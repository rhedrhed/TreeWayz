import express from "express";
import dotenv from "dotenv";
import pool from "./config/pgsql.js";
import authRoutes from "./routes/authroutes.js";
import homeRoutes from "./routes/homeroute.js";
import receiptsRoute from "./routes/receiptRoute.js";
import rideRoutes from "./routes/rideRoute.js";
import cors from "cors";


dotenv.config();
const app = express();
const PORT = process.env.PORT || 5000;

// Middlewares
app.use(cors());
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*"); // Allow all origins for development
  res.header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization");

  // Handle preflight requests
  if (req.method === "OPTIONS") {
    return res.sendStatus(200);
  }
  next();
});
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

// Start server - bind to 0.0.0.0 to accept connections from network
app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n🚀 Server running on port ${PORT}`);
  console.log(`📱 Local: http://localhost:${PORT}`);
  console.log(`🌐 Network: http://192.168.8.101:${PORT}`);
  console.log(`✅ Ready for connections\n`);
});
