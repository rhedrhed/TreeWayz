import express from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import pool from "../config/pgsql.js";

dotenv.config();
const router = express.Router();

// Helper function to format and validate AUBH email
function formatAUBHEmail(rawEmail) {
  // Trim and lowercase input
  const email = rawEmail.trim().toLowerCase();

  // If user already typed full @aubh.edu.bh, accept it directly
  if (email.endsWith("@aubh.edu.bh")) return email;

  // Acceptable patterns:
  // - Students: F followed by 7 digits (e.g., F2300098)
  // - Staff: firstname.lastname (e.g., rayyan.khan)
  const studentPattern = /^f\d{7}$/i;
  const staffPattern = /^[a-z]+\.[a-z]+$/i;

  if (studentPattern.test(email) || staffPattern.test(email)) {
    return `${email}@aubh.edu.bh`;
  }

  // Otherwise invalid format
  return null;
}

// Register new user
router.post("/register", async (req, res) => {
  const { first_name, last_name, email, password, phone } = req.body;

  if (!first_name || !last_name || !email || !password) {
    return res.status(400).json({
      success: false,
      message: "First name, last name, email, and password are required.",
    });
  }

  // Format and validate email
  const formattedEmail = formatAUBHEmail(email);
  if (!formattedEmail) {
    return res.status(400).json({
      success: false,
      message:
        "Invalid email format. Use your student ID (e.g., F2300098) or staff username (e.g., rayyan.khan).",
    });
  }

  try {
    const existingUser = await pool.query("SELECT * FROM Users WHERE email = $1", [formattedEmail]);
    if (existingUser.rows.length > 0) {
      return res.status(400).json({ success: false, message: "Email already registered." });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const result = await pool.query(
      `INSERT INTO Users (first_name, last_name, email, password, phone)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING user_id, first_name, last_name, email, phone`,
      [first_name, last_name, formattedEmail, hashedPassword, phone]
    );

    const user = result.rows[0];
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
router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password)
    return res.status(400).json({ success: false, message: "Email and password are required." });

  // Format and validate email
  const formattedEmail = formatAUBHEmail(email);
  if (!formattedEmail) {
    return res.status(400).json({
      success: false,
      message:
        "Invalid email format. Use your student ID (e.g., F2300098) or staff username (e.g., rayyan.khan).",
    });
  }

  try {
    const result = await pool.query("SELECT * FROM Users WHERE email = $1", [formattedEmail]);
    if (result.rows.length === 0)
      return res.status(400).json({ success: false, message: "Invalid email or password." });

    const user = result.rows[0];
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch)
      return res.status(400).json({ success: false, message: "Invalid email or password." });

    const token = jwt.sign(
      { user_id: user.user_id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: "2h" }
    );

    const { user_id, first_name, last_name, phone } = user;
    res.json({
      success: true,
      message: "Login successful.",
      token,
      user: { user_id, first_name, last_name, email: formattedEmail, phone },
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;
