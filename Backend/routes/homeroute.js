import express from "express";
import pool from "../config/pgsql.js";
import { authenticateToken } from "../middleware/jwtauth.js";

const router = express.Router();

//Load home page info (user details + ongoing ride)
router.get("/home", authenticateToken, async (req, res) => {
  try {
    const userId = req.user.user_id;

    //Get user info
    const userQuery = `
      SELECT first_name, last_name, phone AS contact, rider_rating, driver_rating
      FROM Users
      WHERE user_id = $1
    `;
    const userResult = await pool.query(userQuery, [userId]);

    //Get ongoing ride for driver or rider
    const rideQuery = `
      SELECT r.ride_id, r.origin, r.destination, 
             CASE 
               WHEN r.driver_id = $1 THEN r.status
               ELSE COALESCE(b.status, r.status)
             END as status,
             r.departure_time, r.driver_id,
             d.first_name as driver_first_name, d.last_name as driver_last_name, d.phone as driver_phone
      FROM Rides r
      LEFT JOIN Users d ON r.driver_id = d.user_id
      LEFT JOIN Bookings b ON r.ride_id = b.ride_id AND b.rider_id = $1
      WHERE (
        (r.driver_id = $1 AND r.status IN ('pending','accepted','booked'))
        OR 
        (b.rider_id = $1 AND b.status IN ('pending','accepted') AND r.status IN ('pending','accepted','booked'))
      )
      LIMIT 1
    `;
    const rideResult = await pool.query(rideQuery, [userId]);

    // Check if rider has a completed ride that needs rating
    const completedRideQuery = `
      SELECT r.ride_id, r.driver_id, r.origin, r.destination,
             d.first_name, d.last_name, d.phone
      FROM Rides r
      JOIN Bookings b ON r.ride_id = b.ride_id
      JOIN Users d ON r.driver_id = d.user_id
      WHERE b.rider_id = $1 
        AND r.status = 'completed'
        AND b.status = 'accepted'
        AND NOT EXISTS (
          SELECT 1 FROM Ratings 
          WHERE ride_id = r.ride_id 
            AND reviewer_id = $1 
            AND rating_type = 'rider_to_driver'
        )
      ORDER BY r.created_at DESC
      LIMIT 1
    `;
    const completedRideResult = await pool.query(completedRideQuery, [userId]);

    res.json({
      success: true,
      user: userResult.rows[0],
      ongoing_ride: rideResult.rows.length ? rideResult.rows[0] : null,
      needs_rating: completedRideResult.rows.length ? completedRideResult.rows[0] : null,
    });
  } catch (error) {
    console.error("Error loading home data:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;
