import express from "express";
import pool from "../config/pgsql.js";
import { authenticateToken } from "../middleware/jwtauth.js";

const router = express.Router();

router.get("/home", authenticateToken, async (req, res) => {
  try {
    const userId = req.user.user_id;

    const userQuery = `
      SELECT first_name, last_name, phone AS contact, rider_rating, driver_rating
      FROM Users
      WHERE user_id = $1
    `;
    const userResult = await pool.query(userQuery, [userId]);

    const rideQuery = `
      SELECT ride_id, origin, destination, status, departure_time
      FROM Rides
      WHERE (driver_id = $1 AND status = 'open')
         OR ride_id IN (
              SELECT ride_id FROM Bookings WHERE rider_id = $1 AND status = 'booked'
            )
      LIMIT 1
    `;
    const rideResult = await pool.query(rideQuery, [userId]);

    res.json({
      success: true,
      user: userResult.rows[0],
      ongoing_ride: rideResult.rows.length ? rideResult.rows[0] : null,
    });
  } catch (error) {
    console.error("Error loading home data:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;
