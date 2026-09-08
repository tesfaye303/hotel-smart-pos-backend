// controllers/paymentController.js
const pool = require('../config/db');

// --- 1. ክፍያ መቀበል እና ትዕዛዝ መዝጋት (Process Payment) ---
const processPayment = async (req, res) => {
  const client = await pool.connect(); // Transaction ለመጀመር
  const cashier_id = req.user.id;
  const { order_id, method, amount_paid, transaction_ref } = req.body;
  // method: 'CASH', 'TELEBIRR', 'CBE_BIRR', 'BANK_TRANSFER'

  if (!order_id || !method || !amount_paid) {
    return res.status(400).json({ message: 'እባክዎን የትዕዛዝ ቁጥር፣ የክፍያ መንገድ እና የተከፈለውን ብር ያስገቡ!' });
  }

  try {
    await client.query('BEGIN'); // Transaction ጀምር

    // ሀ. ትዕዛዙ መኖሩን እና ቀደም ሲል አለመከፈሉን ማረጋገጥ
    const orderRes = await client.query('SELECT * FROM orders WHERE id = $1', [order_id]);
    if (orderRes.rows.length === 0) {
      throw new Error('ትዕዛዙ አልተገኘም!');
    }
    const order = orderRes.rows[0];

    if (order.payment_status === 'PAID') {
      throw new Error('ይህ ትዕዛዝ ቀደም ሲል ተከፍሏል!');
    }

    // ለ. የክፍያ መዝገቡን በ 'payments' ሰንጠረዥ ውስጥ መመዝገብ
    const paymentRes = await client.query(
      `INSERT INTO payments (order_id, cashier_id, method, amount_paid, transaction_ref)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [order_id, cashier_id, method, amount_paid, transaction_ref || null]
    );

    // ሐ. የትዕዛዙን ሁኔታ ወደ PAID እና COMPLETED መቀየር
    await client.query(
      `UPDATE orders SET payment_status = 'PAID', status = 'COMPLETED', updated_at = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [order_id]
    );

    // መ. የያዘውን ጠረጴዛ ነፃ (AVAILABLE) ማድረግ
    if (order.table_id) {
      await client.query("UPDATE dining_tables SET status = 'AVAILABLE' WHERE id = $1", [order.table_id]);
    }

    await client.query('COMMIT'); // Transaction ጨርስ

    // ሠ. Real-time Socket alert መላክ
    const io = req.app.get('io');
    // ለአስተናጋጇ ጠረጴዛው ነፃ መሆኑን እና መከፈሉን ማሳወቅ
    io.to(`room:waitress_${order.waitress_id}`).emit('order:paid_success', {
      order_id: order.id,
      message: `የትዕዛዝ #${order.id} ክፍያ በትክክል ተፈጽሟል። ጠረጴዛው ነፃ ሆኗል!`
    });

    res.status(201).json({
      message: 'ክፍያው በትክክል ተፈጽሟል!',
      payment: paymentRes.rows[0]
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Payment Error:', error);
    res.status(500).json({ message: error.message || 'ክፍያውን ማስተናገድ አልተቻለም!' });
  } finally {
    client.release();
  }
};

// --- 2. ያልተከፈሉ አክቲቭ ትዕዛዞችን ለካሸር ማምጫ (Get Unpaid Orders) ---
const getUnpaidOrders = async (req, res) => {
  try {
    const query = `
      SELECT o.id AS order_id, o.total_amount, o.status, o.created_at, dt.table_number, u.full_name AS waitress_name
      FROM orders o
      LEFT JOIN dining_tables dt ON o.table_id = dt.id
      JOIN users u ON o.waitress_id = u.id
      WHERE o.payment_status = 'UNPAID' AND o.status != 'CANCELLED'
      ORDER BY o.created_at ASC
    `;
    const result = await pool.query(query);
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'ያልተከፈሉ ትዕዛዞችን ማምጣት አልተቻለም!' });
  }
};

module.exports = { processPayment, getUnpaidOrders };
