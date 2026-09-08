// routes/shiftRoutes.js
const express = require('express');
const router = express.Router();
const { startShift, endShift, getCurrentShift } = require('../controllers/shiftController');
const { verifyToken } = require('../middlewares/authMiddleware');

router.post('/start', verifyToken, startShift);
router.post('/end', verifyToken, endShift);
router.get('/current', verifyToken, getCurrentShift);

module.exports = router;
