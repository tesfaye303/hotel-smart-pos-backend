// routes/orderRoutes.js
const express = require('express');
const router = express.Router();
const { createOrder, updateOrderStatus, getKitchenOrders } = require('../controllers/orderController');
const { verifyToken, checkRole } = require('../middlewares/authMiddleware');

// 1. አዲስ ትዕዛዝ መላኪያ (WAITRESS ወይም OWNER)
router.post('/', verifyToken, checkRole(['WAITRESS', 'OWNER']), createOrder);

// 2. ለወጥ ቤት የሚሆኑ አክቲቭ ትዕዛዞች ማምጫ (CHEF ወይም OWNER)
router.get('/kitchen', verifyToken, checkRole(['CHEF', 'OWNER']), getKitchenOrders);

// 3. የትዕዛዝ ደረጃ መቀየሪያ (CHEF, WAITRESS, CASHIER, OWNER)
router.patch('/:id/status', verifyToken, updateOrderStatus);

module.exports = router;
