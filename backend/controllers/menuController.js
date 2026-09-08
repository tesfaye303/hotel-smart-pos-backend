const pool = require('../config/db');

// --- 1. የካቴጎሪ (Menu Categories) ስራዎች ---

// ሁሉንም የምግብ ምድቦች ማምጫ
const getCategories = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM menu_categories ORDER BY id ASC');
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'የምግብ ምድቦችን በማምጣት ላይ ስህተት ተከሰቷል!' });
  }
};

// አዲስ የምግብ ምድብ መፍጠሪያ (OWNER ብቻ)
const createCategory = async (req, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ message: 'እባክዎን የምድቡን ስም ያስገቡ!' });

  try {
    const result = await pool.query(
      'INSERT INTO menu_categories (name) VALUES ($1) RETURNING *',
      [name]
    );
    res.status(201).json({ message: 'ምድቡ በትክክል ተፈጥሯል!', category: result.rows[0] });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'ምድቡን ለመመዝገብ አልተቻለም (ምናልባት ቀደም ሲል ይኖራል)!' });
  }
};

// --- 2. የምግብ ዝርዝር (Menu Items) ስራዎች ---

// ሁሉንም ምግቦች ማምጫ (ከካቴጎሪ ስማቸው ጋር)
const getMenuItems = async (req, res) => {
  try {
    const query = `
      SELECT m.id, m.name, m.price, m.is_available, m.image_url, c.name AS category_name, m.category_id
      FROM menu_items m
      LEFT JOIN menu_categories c ON m.category_id = c.id
      ORDER BY m.id DESC
    `;
    const result = await pool.query(query);
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'የምግብ ዝርዝሩን በማምጣት ላይ ስህተት ተከሰቷል!' });
  }
};

// አዲስ ምግብ መጨመሪያ (OWNER ብቻ)
const createMenuItem = async (req, res) => {
  const { category_id, name, price, image_url } = req.body;

  if (!name || !price) {
    return res.status(400).json({ message: 'የምግቡ ስም እና ዋጋ መሞላት አለባቸው!' });
  }

  try {
    const result = await pool.query(
      `INSERT INTO menu_items (category_id, name, price, image_url)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [category_id || null, name, price, image_url || null]
    );
    res.status(201).json({ message: 'ምግቡ በትክክል ተመዝግቧል!', menuItem: result.rows[0] });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'ምግቡን ለመመዝገብ አልተቻለም!' });
  }
};

// የምግብ ዋጋ ወይም ዝርዝር ማስተካከያ (OWNER ብቻ)
const updateMenuItem = async (req, res) => {
  const { id } = req.params;
  const { category_id, name, price, is_available, image_url } = req.body;

  try {
    const result = await pool.query(
      `UPDATE menu_items 
       SET category_id = COALESCE($1, category_id),
           name = COALESCE($2, name),
           price = COALESCE($3, price),
           is_available = COALESCE($4, is_available),
           image_url = COALESCE($5, image_url)
       WHERE id = $6 RETURNING *`,
      [category_id, name, price, is_available, image_url, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'ምግቡ አልተገኘም!' });
    }

    res.json({ message: 'የምግቡ መረጃ ተስተካክሏል!', menuItem: result.rows[0] });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'መረጃውን ማስተካከል አልተቻለም!' });
  }
};

module.exports = {
  getCategories,
  createCategory,
  getMenuItems,
  createMenuItem,
  updateMenuItem
};
