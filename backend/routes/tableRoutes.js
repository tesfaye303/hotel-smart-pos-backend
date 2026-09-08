const express = require('express');
const router = express.Router();
const { getTables, createTable, updateTableStatus } = require('../controllers/tableController');
const { verifyToken, checkRole } = require('../middlewares/authMiddleware');

router.get('/', verifyToken, getTables);
router.post('/', verifyToken, checkRole(['OWNER']), createTable);
router.patch('/:id/status', verifyToken, checkRole(['OWNER', 'WAITRESS', 'CASHIER']), updateTableStatus);

module.exports = router;
