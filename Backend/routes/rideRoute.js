import express from "express";
import pool from "../config/pgsql.js";
import { authenticateToken } from "../middleware/jwtauth.js";
import { predefinedLocations } from "../data/locations.js";

const router = express.Router();

// Predefined allowed destinations
const validDestinations = [
    "AUBH",
    "Juffair",
    "Busaiteen",
    "Aali",
    "KU",
    "Polytechnic"
];

// Helps to convert hour/minute/AMPM to 24-hour Date object
function parseTimeToDate(hour, minute, ampm) {
    let h = parseInt(hour);
    const m = parseInt(minute);

    if (isNaN(h) || isNaN(m) || !ampm) return null;

    const am = ampm.toUpperCase();
    if (am === "PM" && h !== 12) h += 12;
    if (am === "AM" && h === 12) h = 0;

    const date = new Date();
    date.setHours(h, m, 0, 0);
    return date;
}

//Posting a new ride
router.post("/postRide", authenticateToken, async (req, res) => {
    try {
        const driverId = req.user.user_id;
        const {
            pickup_point,
            destination_point,
            hour,
            minute,
            ampm,
            available_seats,
            total_fare,
            fare_per_seat,
            payment_method,
        } = req.body;

        // Validate required fields
        if (
            !pickup_point ||
            !destination_point ||
            hour == null ||
            minute == null ||
            !ampm ||
            !available_seats ||
            !payment_method
        ) {
            return res.status(400).json({
                success: false,
                message: "All fields are required (pickup, destination, time, seats, payment method).",
            });
        }

        // Validate pickup & destination
        if (!validDestinations.includes(pickup_point) || !validDestinations.includes(destination_point)) {
            return res.status(400).json({
                success: false,
                message: "Pickup and destination must be one of the predefined locations.",
            });
        }

        // Validate numeric values
        if (available_seats <= 0) {
            return res.status(400).json({
                success: false,
                message: "Available seats must be greater than 0.",
            });
        }

        // Validate payment method
        const allowedMethods = ["cash", "benefit"];
        if (!allowedMethods.includes(payment_method.toLowerCase())) {
            return res.status(400).json({
                success: false,
                message: "Invalid payment method. Must be 'cash' or 'benefit'.",
            });
        }

        // Parse departure time
        const departure_time = parseTimeToDate(hour, minute, ampm);
        if (!departure_time) {
            return res.status(400).json({
                success: false,
                message: "Invalid departure time format.",
            });
        }

        // Auto-fill coordinates from predefined locations
        const finalPickupLat = predefinedLocations[pickup_point].lat;
        const finalPickupLng = predefinedLocations[pickup_point].lng;
        const finalDestinationLat = predefinedLocations[destination_point].lat;
        const finalDestinationLng = predefinedLocations[destination_point].lng;

        // Calculate distance using Haversine formula
        const R = 6371; // Earth's radius in km
        const dLat = (finalDestinationLat - finalPickupLat) * Math.PI / 180;
        const dLng = (finalDestinationLng - finalPickupLng) * Math.PI / 180;
        const a =
            Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(finalPickupLat * Math.PI / 180) *
            Math.cos(finalDestinationLat * Math.PI / 180) *
            Math.sin(dLng / 2) * Math.sin(dLng / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        const distanceKm = R * c;

        // Calculate fare: 0.20 BHD per km, minimum 0.50 BHD
        const RATE_PER_KM = 0.20;
        const MIN_FARE = 0.50;
        const totalFare = Math.max(distanceKm * RATE_PER_KM, MIN_FARE);
        const finalFarePerSeat = (totalFare / available_seats).toFixed(3);

        // Insert new ride into database
        const result = await pool.query(
            `INSERT INTO Rides (
                driver_id, origin, origin_lat, origin_lng,
                destination, destination_lat, destination_lng,
                departure_time, available_seats, price, payment_method, status
            )
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,'pending')
            RETURNING ride_id, origin, destination, departure_time,
                      available_seats, price, payment_method, status`,
            [
                driverId,
                pickup_point,
                finalPickupLat,
                finalPickupLng,
                destination_point,
                finalDestinationLat,
                finalDestinationLng,
                departure_time,
                available_seats,
                finalFarePerSeat,
                payment_method,
            ]
        );

        // Convert departure_time to Bahrain local time
        const ride = result.rows[0];
        ride.departure_time = new Date(ride.departure_time).toLocaleString("en-BH", {
            timeZone: "Asia/Bahrain",
        });

        res.status(201).json({
            success: true,
            message: "Ride posted successfully.",
            ride,
        });
    } catch (error) {
        console.error("Post ride error:", error);
        res.status(500).json({ success: false, error: error.message });
    }
});

//Searches rides by pickup and destination
router.get("/searchRides", authenticateToken, async (req, res) => {
    try {
        const { pickup_point, destination_point, seats_needed, payment_method } = req.query;

        if (!pickup_point || !destination_point || !seats_needed) {
            return res.status(400).json({
                success: false,
                message: "pickup_point, destination_point, and seats_needed are required.",
            });
        }

        let query = `
            SELECT r.ride_id, r.origin, r.destination, r.departure_time,
                   r.available_seats, r.price, r.payment_method, r.status,
                   u.first_name, u.last_name, u.phone
            FROM Rides r
            JOIN Users u ON r.driver_id = u.user_id
            WHERE r.status = 'pending'
              AND LOWER(r.destination) = LOWER($1)
              AND LOWER(r.origin) = LOWER($2)
              AND r.available_seats >= $3
        `;
        const values = [destination_point, pickup_point, seats_needed];

        if (payment_method) {
            query += ` AND r.payment_method = $${values.length + 1}`;
            values.push(payment_method);
        }

        query += " ORDER BY r.departure_time ASC";

        const result = await pool.query(query, values);

        result.rows.forEach((ride) => {
            ride.departure_time = new Date(ride.departure_time).toLocaleString("en-BH", { timeZone: "Asia/Bahrain" });
        });

        res.json({ success: true, rides: result.rows });
    } catch (error) {
        console.error("Search rides error:", error);
        res.status(500).json({ success: false, error: error.message });
    }
});

//searches nearby rides (optimized)
router.get("/searchNearbyRides", authenticateToken, async (req, res) => {
    try {
        const { lat, lng, radius = 5, seats_needed = 1, payment_method } = req.query;

        if (!lat || !lng) {
            return res.status(400).json({ success: false, message: "Latitude and longitude are required." });
        }

        const values = [lat, lng, seats_needed];
        let paymentFilter = "";
        let radiusParam = "$4";

        if (payment_method) {
            paymentFilter = "AND r.payment_method = $4";
            radiusParam = "$5";
            values.push(payment_method);
        }

        values.push(radius); // Add radius as parameterized value

        const query = `
            SELECT * FROM (
                SELECT r.*, u.first_name, u.last_name, u.phone,
                       (6371 * acos(
                            cos(radians($1)) * cos(radians(r.origin_lat)) *
                            cos(radians(r.origin_lng) - radians($2)) +
                            sin(radians($1)) * sin(radians(r.origin_lat))
                       )) AS distance_km
                FROM Rides r
                JOIN Users u ON r.driver_id = u.user_id
                WHERE r.status = 'pending'
                  AND r.available_seats >= $3
                  AND r.origin_lat IS NOT NULL
                  AND r.origin_lng IS NOT NULL
                  ${paymentFilter}
            ) AS sub
            WHERE distance_km <= ${radiusParam}
            ORDER BY distance_km ASC;
        `;

        const result = await pool.query(query, values);

        result.rows.forEach((ride) => {
            ride.departure_time = new Date(ride.departure_time).toLocaleString("en-BH", { timeZone: "Asia/Bahrain" });
        });

        res.json({ success: true, rides: result.rows });
    } catch (error) {
        console.error("Search nearby rides error:", error);
        res.status(500).json({ success: false, error: error.message });
    }
});

//Driver views posted ride
router.get("/myRide", authenticateToken, async (req, res) => {
    try {
        const driverId = req.user.user_id;

        const result = await pool.query(
            `SELECT * FROM Rides WHERE driver_id=$1 AND status IN ('pending','booked','accepted') ORDER BY created_at DESC LIMIT 1`,
            [driverId]
        );

        if (result.rows.length === 0)
            return res.json({ success: false, message: "No active rides." });

        const ride = result.rows[0];

        // Fetch pending rider requests
        const bookings = await pool.query(
            `SELECT b.booking_id, b.seats, u.first_name, u.last_name, 
                    u.phone, u.rider_rating
             FROM Bookings b
             JOIN Users u ON b.rider_id = u.user_id
             WHERE b.ride_id=$1 AND b.status='pending'`,
            [ride.ride_id]
        );

        res.json({
            success: true,
            ride,
            requests: bookings.rows
        });
    } catch (error) {
        console.error("My ride error:", error);
        res.status(500).json({ success: false, error: error.message });
    }
});


// Get accepted riders for a ride (for rating)
router.get("/acceptedRiders/:rideId", authenticateToken, async (req, res) => {
    try {
        const { rideId } = req.params;
        const driverId = req.user.user_id;

        // Verify ride belongs to driver
        const rideRes = await pool.query(`SELECT driver_id FROM Rides WHERE ride_id=$1`, [rideId]);
        if (!rideRes.rows.length) return res.status(404).json({ success: false, message: "Ride not found." });
        if (rideRes.rows[0].driver_id !== driverId) {
            return res.status(403).json({ success: false, message: "Not your ride." });
        }

        // Get accepted riders
        const riders = await pool.query(
            `SELECT b.rider_id, b.seats, u.first_name, u.last_name, u.phone, u.rider_rating
             FROM Bookings b
             JOIN Users u ON b.rider_id = u.user_id
             WHERE b.ride_id=$1 AND b.status='accepted'`,
            [rideId]
        );

        res.json({
            success: true,
            riders: riders.rows
        });
    } catch (error) {
        console.error("Get accepted riders error:", error);
        res.status(500).json({ success: false, error: error.message });
    }
});

//Driver begins drive (ongoing)
router.patch("/beginDrive/:rideId", authenticateToken, async (req, res) => {
    try {
        const { rideId } = req.params;
        const driverId = req.user.user_id;

        // Verify ride belongs to driver
        const rideRes = await pool.query(`SELECT driver_id FROM Rides WHERE ride_id=$1`, [rideId]);
        if (!rideRes.rows.length) return res.status(404).json({ success: false, message: "Ride not found." });
        if (rideRes.rows[0].driver_id !== driverId) {
            return res.status(403).json({ success: false, message: "You are not allowed to start this ride." });
        }

        await pool.query(`UPDATE Rides SET status='accepted' WHERE ride_id=$1`, [rideId]);
        res.json({ success: true, message: "Drive started." });
    } catch (error) {
        console.error("Begin drive error:", error);
        res.status(500).json({ success: false, error: error.message });
    }
});

//Cancel ride (Driver) - soft delete
router.patch("/cancel/:rideId", authenticateToken, async (req, res) => {
    const client = await pool.connect();
    try {
        const { rideId } = req.params;
        const driverId = req.user.user_id;

        await client.query('BEGIN');

        // Verify ride belongs to driver
        const rideRes = await client.query(`SELECT driver_id, status FROM Rides WHERE ride_id=$1`, [rideId]);
        if (!rideRes.rows.length) {
            await client.query('ROLLBACK');
            return res.status(404).json({ success: false, message: "Ride not found." });
        }
        if (rideRes.rows[0].driver_id !== driverId) {
            await client.query('ROLLBACK');
            return res.status(403).json({ success: false, message: "You are not allowed to cancel this ride." });
        }

        // Check if ride is already completed or cancelled
        if (rideRes.rows[0].status === 'completed') {
            await client.query('ROLLBACK');
            return res.status(400).json({ success: false, message: "Cannot cancel a completed ride." });
        }
        if (rideRes.rows[0].status === 'cancelled') {
            await client.query('ROLLBACK');
            return res.status(400).json({ success: false, message: "Ride is already cancelled." });
        }

        // Reject all pending bookings for this ride
        await client.query(
            `UPDATE Bookings SET status='rejected' WHERE ride_id=$1 AND status='pending'`,
            [rideId]
        );

        // Cancel the ride
        await client.query(`UPDATE Rides SET status='cancelled' WHERE ride_id=$1`, [rideId]);

        await client.query('COMMIT');
        res.json({ success: true, message: "Ride cancelled successfully." });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error("Cancel ride error:", error);
        res.status(500).json({ success: false, error: error.message });
    } finally {
        client.release();
    }
});

//Request ride (Rider)
router.post("/requestRide", authenticateToken, async (req, res) => {
    try {
        const riderId = req.user.user_id;
        const { ride_id, seats } = req.body;

        if (!ride_id || !seats) {
            return res.status(400).json({ success: false, message: "ride_id and seats are required." });
        }

        // Prevent driver from booking their own ride
        const rideRes = await pool.query(`SELECT driver_id, available_seats FROM Rides WHERE ride_id=$1 AND status='pending'`, [ride_id]);
        if (!rideRes.rows.length) return res.status(404).json({ success: false, message: "Ride not found." });
        if (rideRes.rows[0].driver_id === riderId) {
            return res.status(400).json({ success: false, message: "Drivers cannot book their own ride." });
        }
        if (rideRes.rows[0].available_seats < seats) {
            return res.status(400).json({ success: false, message: "Not enough seats available." });
        }

        await pool.query(
            `INSERT INTO Bookings (ride_id, rider_id, seats, status)
             VALUES ($1,$2,$3,'pending')`,
            [ride_id, riderId, seats]
        );

        res.json({ success: true, message: "Ride requested successfully." });
    } catch (error) {
        console.error("Request ride error:", error);
        res.status(500).json({ success: false, error: error.message });
    }
});

//Accept Ride (Driver)
router.patch("/acceptRequest/:bookingId", authenticateToken, async (req, res) => {
    const client = await pool.connect();
    try {
        const { bookingId } = req.params;
        const driverId = req.user.user_id;

        await client.query('BEGIN');

        // Get booking info
        const bookingRes = await client.query(
            `SELECT b.ride_id, b.seats, r.driver_id, r.available_seats
             FROM Bookings b
             JOIN Rides r ON b.ride_id = r.ride_id
             WHERE b.booking_id=$1 FOR UPDATE`,
            [bookingId]
        );

        const booking = bookingRes.rows[0];
        if (!booking) {
            await client.query('ROLLBACK');
            return res.status(404).json({ success: false, message: "Booking not found." });
        }

        // Verify driver owns the ride
        if (booking.driver_id !== driverId) {
            await client.query('ROLLBACK');
            return res.status(403).json({ success: false, message: "You cannot accept this booking." });
        }

        // Check available seats
        if (booking.available_seats < booking.seats) {
            await client.query('ROLLBACK');
            return res.status(400).json({ success: false, message: "Not enough seats available." });
        }

        // Update booking status
        await client.query(`UPDATE Bookings SET status='accepted' WHERE booking_id=$1`, [bookingId]);

        // Deduct seats from ride
        const updatedRideRes = await client.query(
            `UPDATE Rides SET available_seats = available_seats - $2 WHERE ride_id=$1 RETURNING available_seats`,
            [booking.ride_id, booking.seats]
        );

        // Change ride status to 'booked' after accepting at least one rider
        // This allows the driver to start the drive
        await client.query(`UPDATE Rides SET status='booked' WHERE ride_id=$1`, [booking.ride_id]);
        // Get ride price and payment method
        const rideInfo = await client.query(
            `SELECT price, payment_method FROM Rides WHERE ride_id=$1`,
            [booking.ride_id]
        );

        const pricePerSeat = parseFloat(rideInfo.rows[0].price);
        const totalPayment = pricePerSeat * booking.seats;

        await client.query(
            `INSERT INTO Payments (booking_id, amount, method)
     VALUES ($1, $2, $3)`,
            [bookingId, totalPayment, rideInfo.rows[0].payment_method]
        );
        await client.query('COMMIT');
        res.json({ success: true, message: "Rider accepted." });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error("Accept request error:", error);
        res.status(500).json({ success: false, error: error.message });
    } finally {
        client.release();
    }
});

//Reject ride request (driver) - soft delete
router.patch("/rejectRequest/:bookingId", authenticateToken, async (req, res) => {
    try {
        const { bookingId } = req.params;
        const driverId = req.user.user_id;

        // Verify booking belongs to driver’s ride
        const bookingRes = await pool.query(
            `SELECT b.ride_id, r.driver_id
             FROM Bookings b
             JOIN Rides r ON b.ride_id = r.ride_id
             WHERE b.booking_id=$1`,
            [bookingId]
        );

        const booking = bookingRes.rows[0];
        if (!booking) return res.status(404).json({ success: false, message: "Booking not found." });
        if (booking.driver_id !== driverId) {
            return res.status(403).json({ success: false, message: "You cannot reject this booking." });
        }

        // Soft delete
        await pool.query(`UPDATE Bookings SET status='rejected' WHERE booking_id=$1`, [bookingId]);

        res.json({ success: true, message: "Request rejected." });
    } catch (error) {
        console.error("Reject request error:", error);
        res.status(500).json({ success: false, error: error.message });
    }
});

//End drive (Driver)
router.patch("/endDrive/:rideId", authenticateToken, async (req, res) => {
    try {
        const { rideId } = req.params;
        const driverId = req.user.user_id;

        // Verify ride belongs to driver and is ongoing
        const rideRes = await pool.query(`SELECT driver_id, status FROM Rides WHERE ride_id=$1`, [rideId]);
        if (!rideRes.rows.length) return res.status(404).json({ success: false, message: "Ride not found." });

        const ride = rideRes.rows[0];
        if (ride.driver_id !== driverId)
            return res.status(403).json({ success: false, message: "You cannot end this ride." });

        if (ride.status !== "accepted")
            return res.status(400).json({ success: false, message: "Ride is not in progress." });

        // Mark ride as completed
        await pool.query(`UPDATE Rides SET status='completed' WHERE ride_id=$1`, [rideId]);
        res.json({ success: true, message: "Drive ended successfully." });
    } catch (error) {
        console.error("End drive error:", error);
        res.status(500).json({ success: false, error: error.message });
    }
});

//Driver rates rider
router.post("/rateRider/:rideId", authenticateToken, async (req, res) => {
    try {
        const driverId = req.user.user_id;
        const { rideId } = req.params;
        const { rider_id, score } = req.body;

        if (!rider_id || !score) return res.status(400).json({ success: false, message: "rider_id and score are required." });
        if (score < 1 || score > 5) return res.status(400).json({ success: false, message: "Score must be between 1 and 5." });

        // Verify driver owns the ride
        const rideRes = await pool.query(`SELECT driver_id FROM Rides WHERE ride_id=$1`, [rideId]);
        if (!rideRes.rows.length) return res.status(404).json({ success: false, message: "Ride not found." });
        if (rideRes.rows[0].driver_id !== driverId)
            return res.status(403).json({ success: false, message: "You cannot rate riders for this ride." });

        // Check for duplicate rating
        const existingRating = await pool.query(
            `SELECT * FROM Ratings 
             WHERE ride_id=$1 AND reviewer_id=$2 AND reviewee_id=$3 AND rating_type='driver_to_rider'`,
            [rideId, driverId, rider_id]
        );

        if (existingRating.rows.length > 0) {
            return res.status(400).json({
                success: false,
                message: "You have already rated this rider for this ride."
            });
        }

        // Insert rating
        await pool.query(
            `INSERT INTO Ratings (ride_id, reviewer_id, reviewee_id, score, rating_type)
             VALUES ($1, $2, $3, $4, 'driver_to_rider')`,
            [rideId, driverId, rider_id, score]
        );

        // Update rider average rating
        const avgRes = await pool.query(
            `SELECT AVG(score)::numeric(2,1) AS avg_rating
             FROM Ratings
             WHERE reviewee_id=$1 AND rating_type='driver_to_rider'`,
            [rider_id]
        );

        await pool.query(
            `UPDATE Users SET rider_rating=$1 WHERE user_id=$2`,
            [avgRes.rows[0].avg_rating, rider_id]
        );

        res.json({ success: true, message: "Rider rated successfully." });
    } catch (error) {
        console.error("Rate rider error:", error);
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post("/rateDriver/:rideId", authenticateToken, async (req, res) => {
    try {
        const riderId = req.user.user_id;
        const { rideId } = req.params;
        const { score } = req.body;

        if (!score) return res.status(400).json({ success: false, message: "Score is required." });
        if (score < 1 || score > 5) return res.status(400).json({ success: false, message: "Score must be between 1 and 5." });

        // Verify rider booked this ride
        const bookingRes = await pool.query(
            `SELECT * FROM Bookings WHERE ride_id=$1 AND rider_id=$2 AND status='accepted'`,
            [rideId, riderId]
        );
        if (!bookingRes.rows.length) return res.status(403).json({ success: false, message: "You did not book this ride." });

        const driverRes = await pool.query(`SELECT driver_id FROM Rides WHERE ride_id=$1`, [rideId]);
        if (!driverRes.rows.length) return res.status(404).json({ success: false, message: "Ride not found." });

        // Check for duplicate rating
        const existingRating = await pool.query(
            `SELECT * FROM Ratings 
             WHERE ride_id=$1 AND reviewer_id=$2 AND reviewee_id=$3 AND rating_type='rider_to_driver'`,
            [rideId, riderId, driverRes.rows[0].driver_id]
        );

        if (existingRating.rows.length > 0) {
            return res.status(400).json({
                success: false,
                message: "You have already rated this driver for this ride."
            });
        }

        // Insert rating
        await pool.query(
            `INSERT INTO Ratings (ride_id, reviewer_id, reviewee_id, score, rating_type)
             VALUES ($1, $2, $3, $4, 'rider_to_driver')`,
            [rideId, riderId, driverRes.rows[0].driver_id, score]
        );

        // Update driver average rating
        const avgRes = await pool.query(
            `SELECT AVG(score)::numeric(2,1) AS avg_rating
             FROM Ratings
             WHERE reviewee_id=$1 AND rating_type='rider_to_driver'`,
            [driverRes.rows[0].driver_id]
        );

        await pool.query(
            `UPDATE Users SET driver_rating=$1 WHERE user_id=$2`,
            [avgRes.rows[0].avg_rating, driverRes.rows[0].driver_id]
        );

        res.json({ success: true, message: "Driver rated successfully." });
    } catch (error) {
        console.error("Rate driver error:", error);
        res.status(500).json({ success: false, error: error.message });
    }
});


export default router;
