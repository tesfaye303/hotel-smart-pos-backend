// routes/paymentRoutes.js
const express = require('express');
const router = express.Router();
const { processPayment, getUnpaidOrders } = require('../controllers/paymentController');
const { verifyToken, checkRole } = require('../middlewares/authMiddleware');

// 1. ክፍያ መቀበል (CASHIER ወይም OWNER ብቻ)
router.post('/', verifyToken, checkRole(['CASHIER', 'OWNER']), processPayment);

// 2. ያልተከፈሉ ትዕዛዞችን ማየት (CASHIER ወይም OWNER)
router.get('/unpaid', verifyToken, checkRole(['CASHIER', 'OWNER']), getUnpaidOrders);

module.exports = router;
