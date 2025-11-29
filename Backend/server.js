import express from "express";
import dotenv from "dotenv";
import pg from "pg";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

dotenv.config();
const { Pool } = pg;

// PostgreSQL connection pool
const pool = new Pool({
  host: process.env.PGHOST,
  user: process.env.PGUSER,
  password: process.env.PGPASSWORD,
  database: process.env.PGDATABASE,
  port: process.env.PGPORT,
});

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Root route for testing
app.get("/", (req, res) => {
  res.send("Backend running");
});

// Test database connection
app.get("/test", async (req, res) => {
  try {
    const result = await pool.query("SELECT NOW()");
    res.json({ success: true, time: result.rows[0].now });
  } catch (error) {
    console.error("Database error:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// User registration
app.post("/register", async (req, res) => {
  const { first_name, last_name, email, password, phone } = req.body;

  if (!first_name || !last_name || !email || !password) {
    return res.status(400).json({
      success: false,
      message: "First name, last name, email, and password are required.",
    });
  }

  try {
    // Check if email is already registered
    const existingUser = await pool.query("SELECT * FROM Users WHERE email = $1", [email]);
    if (existingUser.rows.length > 0) {
      return res.status(400).json({ success: false, message: "Email already registered." });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert user into database
    const result = await pool.query(
      `INSERT INTO Users (first_name, last_name, email, password, phone)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING user_id, first_name, last_name, email, phone`,
      [first_name, last_name, email, hashedPassword, phone]
    );

    const user = result.rows[0];

    // Generate JWT token immediately after registration
    const token = jwt.sign(
      { user_id: user.user_id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: "2h" }
    );

    res.status(201).json({
      success: true,
      message: "User registered successfully.",
      token,
      user,
    });
  } catch (error) {
    console.error("Registration error:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// User login
app.post("/login", async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ success: false, message: "Email and password are required." });
  }

  try {
    // Check if user exists
    const result = await pool.query("SELECT * FROM Users WHERE email = $1", [email]);

    if (result.rows.length === 0) {
      return res.status(400).json({ success: false, message: "Invalid email or password." });
    }

    const user = result.rows[0];

    // Compare entered password with hashed password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: "Invalid email or password." });
    }

    // Generate JWT token
    const token = jwt.sign(
      { user_id: user.user_id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: "2h" }
    );

    // Return safe user information
    const { user_id, first_name, last_name, phone } = user;

    res.json({
      success: true,
      message: "Login successful.",
      token,
      user: { user_id, first_name, last_name, email, phone },
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Middleware for token authentication
function authenticateToken(req, res, next) {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) {
    return res.status(401).json({ success: false, message: "Access denied. No token provided." });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ success: false, message: "Invalid or expired token." });
    }
    req.user = user; // attach decoded user info
    next();
  });
}

// Protected route: Home page data (requires login)
app.get("/home", authenticateToken, async (req, res) => {
  try {
    const userId = req.user.user_id;

    // Fetch user profile data
    const userQuery = `
      SELECT first_name, last_name, phone AS contact, rider_rating, driver_rating
      FROM Users
      WHERE user_id = $1
    `;
    const userResult = await pool.query(userQuery, [userId]);

    // Fetch ongoing ride (either driver or rider)
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

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
