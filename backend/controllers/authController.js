const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');

// 1. አዲስ ሰራተኛ መመዝገቢያ (Register)
const register = async (req, res) => {
  const { full_name, phone_number, password, role } = req.body;

  if (!full_name || !phone_number || !password || !role) {
    return res.status(400).json({ message: 'እባክዎን ሁሉንም አስፈላጊ መረጃዎች ይሙሉ!' });
  }

  try {
    // ስልክ ቁጥሩ ቀደም ሲል ተመዝግቦ እንደሆነ ማረጋገጥ
    const userCheck = await pool.query('SELECT * FROM users WHERE phone_number = $1', [phone_number]);
    if (userCheck.rows.length > 0) {
      return res.status(400).json({ message: 'ይህ ስልክ ቁጥር ቀደም ሲል ተመዝግቧል!' });
    }

    // የይለፍ ቃሉን ማመስጠር (Hash Password)
    const saltRounds = 10;
    const password_hash = await bcrypt.hash(password, saltRounds);

    // አዲሱን ሰራተኛ ወደ PostgreSQL ዳታቤዝ ማስገባት
    const newUser = await pool.query(
      `INSERT INTO users (full_name, phone_number, password_hash, role)
       VALUES ($1, $2, $3, $4) RETURNING id, full_name, phone_number, role, created_at`,
      [full_name, phone_number, password_hash, role]
    );

    res.status(201).json({
      message: 'ሰራተኛው በትክክል ተመዝግቧል!',
      user: newUser.rows[0]
    });
  } catch (error) {
    console.error('Register Error:', error);
    res.status(500).json({ message: 'የሰርቨር ስህተት ተከሰቷል!' });
  }
};

// 2. ሰራተኛ ወደ ሲስተሙ መግቢያ (Login)
const login = async (req, res) => {
  const { phone_number, password } = req.body;

  if (!phone_number || !password) {
    return res.status(400).json({ message: 'እባክዎን ስልክ ቁጥር እና የይለፍ ቃል ይሙሉ!' });
  }

  try {
    // ተጠቃሚውን በስልክ ቁጥር መፈለግ
    const userResult = await pool.query('SELECT * FROM users WHERE phone_number = $1', [phone_number]);
    if (userResult.rows.length === 0) {
      return res.status(400).json({ message: 'የተሳሳተ ስልክ ቁጥር ወይም የይለፍ ቃል!' });
    }

    const user = userResult.rows[0];

    // ሰራተኛው ከስራ ታግዶ እንደሆነ ማረጋገጥ
    if (!user.is_active) {
      return res.status(403).json({ message: 'መለያዎ የታገደ ስለሆነ መግባት አይችሉም!' });
    }

    // የይለፍ ቃሉን ማረጋገጥ (Compare Passwords)
    const isMatch = await bcrypt.compare(password, user.password_hash);

    if (!isMatch) {
      return res.status(400).json({ message: 'የተሳሳተ ስልክ ቁጥር ወይም የይለፍ ቃል!' });
    }

    // JWT Token ማዘጋጀት (ለ 24 ሰዓት የሚያገለግል)
    const token = jwt.sign(
      { id: user.id, full_name: user.full_name, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      message: 'በተሳካ ሁኔታ ገብተዋል!',
      token,
      user: {
        id: user.id,
        full_name: user.full_name,
        phone_number: user.phone_number,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Login Error:', error);
    res.status(500).json({ message: 'የሰርቨር ስህተት ተከሰቷል!' });
  }
};

module.exports = { register, login };