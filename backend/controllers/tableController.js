const pool = require('../config/db');

// ሁሉንም ጠረጴዛዎች ማምጫ
const getTables = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM dining_tables ORDER BY id ASC');
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'የጠረጴዛዎችን መረጃ ማምጣት አልተቻለም!' });
  }
};

// አዲስ ጠረጴዛ መጨመሪያ (OWNER ብቻ)
const createTable = async (req, res) => {
  const { table_number } = req.body;
  if (!table_number) return res.status(400).json({ message: 'እባክዎን የጠረጴዛ ቁጥር ያስገቡ!' });

  try {
    const result = await pool.query(
      'INSERT INTO dining_tables (table_number) VALUES ($1) RETURNING *',
      [table_number]
    );
    res.status(201).json({ message: 'ጠረጴዛው ተመዝግቧል!', table: result.rows[0] });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'ጠረጴዛውን መመዝገብ አልተቻለም (ቁጥሩ ተደግሟል)!' });
  }
};

// የጠረጴዛ ሁኔታ መቀየሪያ (AVAILABLE / OCCUPIED)
const updateTableStatus = async (req, res) => {
  const { id } = req.params;
  const { status } = req.body; // 'AVAILABLE' ወይም 'OCCUPIED'

  try {
    const result = await pool.query(
      'UPDATE dining_tables SET status = $1 WHERE id = $2 RETURNING *',
      [status, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'ጠረጴዛው አልተገኘም!' });
    }

    res.json({ message: 'የጠረጴዛው ሁኔታ ተቀይሯል!', table: result.rows[0] });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'የጠረጴዛውን ሁኔታ መቀየር አልተቻለም!' });
  }
};

module.exports = { getTables, createTable, updateTableStatus };
