import express from "express";
import dotenv from "dotenv";
import pool from "./config/pgsql.js";
import authRoutes from "./routes/authroutes.js";
import homeRoutes from "./routes/homeroute.js";
import receiptsRoute from "./routes/receiptRoute.js";
import rideRoutes from "./routes/rideRoute.js";

dotenv.config();
const app = express();
const PORT = process.env.PORT || 5000;

// Middlewares
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Root route
app.get("/", (req, res) => res.send("Backend running"));

// Test DB connection
app.get("/test", async (req, res) => {
  try {
    const result = await pool.query("SELECT NOW()");
    res.json({ success: true, time: result.rows[0].now });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Routes
app.use("/", authRoutes);
app.use("/", homeRoutes);
app.use("/", receiptsRoute);
app.use("/rides", rideRoutes);

// Start server
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
