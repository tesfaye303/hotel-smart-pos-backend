const express = require('express');
const router = express.Router();
const { register, login } = require('../controllers/authController');
const { verifyToken, checkRole } = require('../middlewares/authMiddleware');

// 1. መግቢያ (ማንኛውም ሰራተኛ ሊጠቀመው የሚችለው)
router.post('/login', login);

// 2. አዲስ ሰራተኛ መመዝገቢያ (የባለቤት/OWNER መብት ብቻ የሚጠይቅ)
router.post('/register', verifyToken, checkRole(['OWNER']), register);

// 3. የፈተና መስመር (የራሴን መረጃ ማያ)
router.get('/me', verifyToken, (req, res) => {
  res.json({ message: 'Token ትክክለኛ ነው!', user: req.user });
});

module.exports = router;