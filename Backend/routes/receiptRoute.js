import express from "express";
import pool from "../config/pgsql.js";
import { authenticateToken } from "../middlewares/authMiddleware.js";
import PDFDocument from "pdfkit"; // npm i pdfkit

const router = express.Router();

// Get all past rides (completed)
router.get("/api/receipts", authenticateToken, async (req, res) => {
  try {
    const userId = req.user.user_id;

    const query = `
      SELECT 
        b.booking_id,
        r.origin,
        r.destination,
        r.departure_time,
        p.amount,
        p.method,
        p.created_at AS payment_date,
        CONCAT(d.first_name, ' ', d.last_name) AS driver_name
      FROM Bookings b
      JOIN Rides r ON b.ride_id = r.ride_id
      JOIN Payments p ON b.booking_id = p.booking_id
      JOIN Users d ON r.driver_id = d.user_id
      WHERE (b.rider_id = $1 OR r.driver_id = $1)
        AND r.status = 'done'
      ORDER BY p.created_at DESC
    `;

    const result = await pool.query(query, [userId]);

    res.json({
      success: true,
      total_receipts: result.rows.length,
      receipts: result.rows.map((row) => ({
        booking_id: row.booking_id,
        driver_name: row.driver_name,
        origin: row.origin,
        destination: row.destination,
        departure_time: row.departure_time,
        amount: row.amount,
        method: row.method,
        payment_date: row.payment_date,
        invoice_url: `/api/receipts/${row.booking_id}/invoice`,
      })),
    });
  } catch (err) {
    console.error("Receipts error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// Generate and return PDF invoice
router.get("/api/receipts/:booking_id/invoice", authenticateToken, async (req, res) => {
  try {
    const { booking_id } = req.params;
    const userId = req.user.user_id;

    // Fetch invoice data
    const query = `
      SELECT 
        b.booking_id,
        r.origin,
        r.destination,
        r.departure_time,
        r.price,
        p.amount,
        p.method,
        p.created_at AS payment_date,
        CONCAT(d.first_name, ' ', d.last_name) AS driver_name,
        CONCAT(u.first_name, ' ', u.last_name) AS rider_name
      FROM Bookings b
      JOIN Rides r ON b.ride_id = r.ride_id
      JOIN Payments p ON b.booking_id = p.booking_id
      JOIN Users d ON r.driver_id = d.user_id
      JOIN Users u ON b.rider_id = u.user_id
      WHERE b.booking_id = $1 AND (b.rider_id = $2 OR r.driver_id = $2)
    `;

    const result = await pool.query(query, [booking_id, userId]);
    if (result.rows.length === 0)
      return res.status(404).json({ success: false, message: "Invoice not found." });

    const data = result.rows[0];

    // Generate PDF
    const doc = new PDFDocument();
    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", `inline; filename=invoice-${booking_id}.pdf`);
    doc.pipe(res);

    doc.fontSize(20).text("TreeWayz Ride Invoice", { align: "center" });
    doc.moveDown();
    doc.fontSize(12).text(`Booking ID: ${data.booking_id}`);
    doc.text(`Driver: ${data.driver_name}`);
    doc.text(`Rider: ${data.rider_name}`);
    doc.text(`From: ${data.origin}`);
    doc.text(`To: ${data.destination}`);
    doc.text(`Departure Time: ${new Date(data.departure_time).toLocaleString()}`);
    doc.text(`Payment Method: ${data.method}`);
    doc.text(`Payment Date: ${new Date(data.payment_date).toLocaleString()}`);
    doc.moveDown();
    doc.fontSize(14).text(`Amount Paid: ${data.amount} BD`, { align: "right" });
    doc.moveDown(2);
    doc.fontSize(10).text("Thank you for riding with TreeWayz!", { align: "center" });

    doc.end();
  } catch (err) {
    console.error("Invoice PDF error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

export default router;
