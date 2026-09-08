// controllers/shiftController.js
const pool = require('../config/db');

// --- 1. ሺፍት መክፈት / ስራ መጀመር (Start Shift) ---
const startShift = async (req, res) => {
  const user_id = req.user.id;
  const { starting_cash } = req.body; // ለካሸሮች መነሻ ብር

  try {
    // ቀደም ሲል ያልተዘጋ OPEN ሺፍት እንዳለ ማረጋገጥ
    const activeShift = await pool.query(
      "SELECT * FROM shift_logs WHERE user_id = $1 AND status = 'OPEN'",
      [user_id]
    );

    if (activeShift.rows.length > 0) {
      return res.status(400).json({ message: 'ቀደም ሲል የተከፈተ ሺፍት አለዎት! መጀመሪያ ያንን ይዝጉ።' });
    }

    const result = await pool.query(
      `INSERT INTO shift_logs (user_id, starting_cash, status)
       VALUES ($1, $2, 'OPEN') RETURNING *`,
      [user_id, starting_cash || 0.00]
    );

    res.status(201).json({
      message: 'ሺፍት በደስታ ተከፍቷል! መልካም የስራ ጊዜ።',
      shift: result.rows[0]
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'ሺፍት መክፈት አልተቻለም!' });
  }
};

// --- 2. ሺፍት መዝጋት / የካዝና ሂሳብ መስራት (End Shift) ---
const endShift = async (req, res) => {
  const user_id = req.user.id;
  const { actual_ending_cash, notes } = req.body;

  try {
    // አክቲቭ ሺፍቱን መፈለግ
    const shiftRes = await pool.query(
      "SELECT * FROM shift_logs WHERE user_id = $1 AND status = 'OPEN'",
      [user_id]
    );

    if (shiftRes.rows.length === 0) {
      return res.status(404).json({ message: 'ምንም አይነት የተከፈተ ሺፍት አልተገኘም!' });
    }

    const currentShift = shiftRes.rows[0];

    // በዚሁ ሺፍት ጊዜ በ CASH የተቀበለውን አጠቃላይ ብር ዳታቤዝ ላይ ማሰላት
    const cashSalesRes = await pool.query(
      `SELECT COALESCE(SUM(amount_paid), 0) AS total_cash
       FROM payments
       WHERE cashier_id = $1 AND method = 'CASH'
         AND paid_at >= $2`,
      [user_id, currentShift.started_at]
    );

    const totalCashSales = parseFloat(cashSalesRes.rows[0].total_cash);
    const startingCash = parseFloat(currentShift.starting_cash);
    
    // መኖር ያለበት የጥሬ ገንዘብ መጠን = መነሻ ብር + የዕለቱ የካሽ ሽያጭ
    const expectedEndingCash = startingCash + totalCashSales;

    // ሺፍቱን መዝጋት
    const updatedShift = await pool.query(
      `UPDATE shift_logs 
       SET status = 'CLOSED',
           expected_ending_cash = $1,
           actual_ending_cash = $2,
           ended_at = CURRENT_TIMESTAMP,
           notes = $3
       WHERE id = $4 RETURNING *`,
      [expectedEndingCash, actual_ending_cash || 0.00, notes || null, currentShift.id]
    );

    res.json({
      message: 'ሺፍቱ በተሳካ ሁኔታ ተዘጋቷል!',
      summary: {
        starting_cash: startingCash,
        total_cash_sales: totalCashSales,
        expected_ending_cash: expectedEndingCash,
        actual_ending_cash: parseFloat(actual_ending_cash || 0),
        difference: parseFloat(actual_ending_cash || 0) - expectedEndingCash, // ልዩነት (ከጎደለ minus ይሆናል)
        shift_details: updatedShift.rows[0]
      }
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'ሺፍቱን መዝጋት አልተቻለም!' });
  }
};

// --- 3. የወቅቱን ሺፍት መረጃ ማምጫ (Get Current Active Shift) ---
const getCurrentShift = async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT * FROM shift_logs WHERE user_id = $1 AND status = 'OPEN'",
      [req.user.id]
    );
    res.json(result.rows[0] || null);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'የሺፍት መረጃ ማምጣት አልተቻለም!' });
  }
};

module.exports = { startShift, endShift, getCurrentShift };
