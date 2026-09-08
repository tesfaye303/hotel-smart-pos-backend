// controllers/orderController.js
const pool = require('../config/db');
const { 
  sendOrderNotificationToKitchen, 
  sendOrderReadyNotificationToWaitress 
} = require('../services/notificationService'); // 1. Notification Service Import ተደርጓል

// --- 1. አዲስ ትዕዛዝ መፍጠር (Create Order & Broadcast to Kitchen) ---
const createOrder = async (req, res) => {
  const client = await pool.connect(); // Transaction ለመጀመር
  const waitress_id = req.user.id; // ከ JWT Token የሚገኝ
  const { table_id, items } = req.body; 

  if (!table_id || !items || items.length === 0) {
    return res.status(400).json({ message: 'እባክዎን ጠረጴዛ እና የታዘዙ ምግቦችን ያስገቡ!' });
  }

  try {
    await client.query('BEGIN'); // 1. Transaction ጀምር

    // ሀ. ትዕዛዙን በ 'orders' ሰንጠረዥ ውስጥ መመዝገብ
    const orderResult = await client.query(
      `INSERT INTO orders (table_id, waitress_id, status, payment_status)
       VALUES ($1, $2, 'NEW', 'UNPAID') RETURNING *`,
      [table_id, waitress_id]
    );
    const newOrder = orderResult.rows[0];

    let totalAmount = 0;
    const insertedItems = [];

    // ለ. እያንዳንዱን የታዘዘ ምግብ ማስገባት እና ዋጋ ማሰላት
    for (const item of items) {
      const menuRes = await client.query('SELECT name, price FROM menu_items WHERE id = $1', [item.menu_item_id]);
      if (menuRes.rows.length === 0) {
        throw new Error(`የተፈለገው ምግብ አልተገኘም! (ID: ${item.menu_item_id})`);
      }

      const unitPrice = parseFloat(menuRes.rows[0].price);
      const subtotal = unitPrice * item.quantity;
      totalAmount += subtotal;

      // ወደ order_items ማስገባት
      const itemRes = await client.query(
        `INSERT INTO order_items (order_id, menu_item_id, quantity, unit_price, special_instructions)
         VALUES ($1, $2, $3, $4, $5) RETURNING *`,
        [newOrder.id, item.menu_item_id, item.quantity, unitPrice, item.special_instructions || null]
      );

      insertedItems.push({
        ...itemRes.rows[0],
        item_name: menuRes.rows[0].name
      });
    }

    // ሐ. የአጠቃላይ ትዕዛዙን ዋጋ (total_amount) ማስተካከል
    await client.query('UPDATE orders SET total_amount = $1 WHERE id = $2', [totalAmount, newOrder.id]);

    // መ. የጠረጴዛውን ሁኔታ ወደ 'OCCUPIED' መቀየር
    const tableRes = await client.query(
      "UPDATE dining_tables SET status = 'OCCUPIED' WHERE id = $1 RETURNING table_number",
      [table_id]
    );

    await client.query('COMMIT'); // 2. Transaction ጨርስ (Save all)

    const tableNumber = tableRes.rows[0]?.table_number || 'N/A';

    // የትዕዛዙን ሙሉ መረጃ ለ Socket ማዘጋጀት
    const fullOrderPayload = {
      order_id: newOrder.id,
      table_id: newOrder.table_id,
      table_number: tableNumber,
      waitress_id: req.user.id,
      waitress_name: req.user.full_name,
      status: 'NEW',
      total_amount: totalAmount,
      created_at: newOrder.created_at,
      items: insertedItems
    };

    // ሠ. REAL-TIME SOCKET EMIT: ለወጥ ቤት (room:kitchen) መላክ 🚀
    const io = req.app.get('io');
    if (io) {
      io.to('room:kitchen').emit('kitchen:new_order', fullOrderPayload);
    }

    // ረ. PUSH NOTIFICATION: አፕሊኬሽኑ በ Background/Locked ቢሆንም ለወጥ ቤት ስልክ Notification መላክ 🔔
    try {
      await sendOrderNotificationToKitchen(newOrder.id, tableNumber);
    } catch (notifErr) {
      console.error('FCM Kitchen Notification Error:', notifErr);
    }

    res.status(201).json({
      message: 'ትዕዛዙ በትክክል ወደ ወጥ ቤት ተልኳል!',
      order: fullOrderPayload
    });

  } catch (error) {
    await client.query('ROLLBACK'); // ስህተት ካለ ሁሉንም ሰርዝ
    console.error('Create Order Error:', error);
    res.status(500).json({ message: error.message || 'ትዕዛዙን መላክ አልተቻለም!' });
  } finally {
    client.release();
  }
};

// --- 2. የትዕዛዝ ደረጃ መቀየሪያ (Update Order Status) ---
const updateOrderStatus = async (req, res) => {
  const { id } = req.params;
  const { status } = req.body; // 'PREPARING', 'READY', 'COMPLETED', 'CANCELLED'

  try {
    const result = await pool.query(
      `UPDATE orders SET status = $1, updated_at = CURRENT_TIMESTAMP 
       WHERE id = $2 RETURNING *`,
      [status, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'ትዕዛዙ አልተገኘም!' });
    }

    const updatedOrder = result.rows[0];
    const io = req.app.get('io');

    // ሀ. ምግቡ ተሰርቶ ካለቀ ('READY') ለአስተናጋጇ ስልክ በ Socket እና በ Push Notification ማሳወቅ
    if (status === 'READY') {
      const tableRes = await pool.query('SELECT table_number FROM dining_tables WHERE id = $1', [updatedOrder.table_id]);
      const tableNumber = tableRes.rows[0]?.table_number || 'N/A';
      
      if (io) {
        io.to(`room:waitress_${updatedOrder.waitress_id}`).emit('order:ready_alert', {
          order_id: updatedOrder.id,
          table_number: tableNumber,
          message: `የጠረጴዛ ${tableNumber} ምግብ ተሰርቶ አልቋል!`
        });
      }

      // ለአስተናጋጇ ስልክ FCM Push Notification መላክ
      try {
        await sendOrderReadyNotificationToWaitress(updatedOrder.waitress_id, tableNumber, updatedOrder.id);
      } catch (notifErr) {
        console.error('FCM Waitress Notification Error:', notifErr);
      }
    }

    // ለ. ለሁሉም KDS እና አስተናጋጆች የትዕዛዙ ሁኔታ መለወጡን ማሳወቅ
    if (io) {
      io.emit('order:status_changed', { order_id: updatedOrder.id, status });
    }

    res.json({ message: 'የትዕዛዙ ሁኔታ ተቀይሯል!', order: updatedOrder });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'የትዕዛዙን ሁኔታ መቀየር አልተቻለም!' });
  }
};

// --- 3. ለወጥ ቤት አክቲቭ ትዕዛዞችን ማምጫ (Get Active Kitchen Orders) ---
const getKitchenOrders = async (req, res) => {
  try {
    const query = `
      SELECT o.id AS order_id, o.status, o.created_at, dt.table_number, u.full_name AS waitress_name,
             json_agg(
               json_build_object(
                 'item_name', mi.name,
                 'quantity', oi.quantity,
                 'special_instructions', oi.special_instructions
               )
             ) AS items
      FROM orders o
      JOIN dining_tables dt ON o.table_id = dt.id
      JOIN users u ON o.waitress_id = u.id
      JOIN order_items oi ON o.id = oi.order_id
      JOIN menu_items mi ON oi.menu_item_id = mi.id
      WHERE o.status IN ('NEW', 'PREPARING')
      GROUP BY o.id, dt.table_number, u.full_name
      ORDER BY o.created_at ASC
    `;
    const result = await pool.query(query);
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'የወጥ ቤት ትዕዛዞችን ማምጣት አልተቻለም!' });
  }
};

module.exports = {
  createOrder,
  updateOrderStatus,
  getKitchenOrders
};