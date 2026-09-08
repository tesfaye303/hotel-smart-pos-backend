const express = require('express');
const router = express.Router();
const {
  getCategories,
  createCategory,
  getMenuItems,
  createMenuItem,
  updateMenuItem
} = require('../controllers/menuController');

const { verifyToken, checkRole } = require('../middlewares/authMiddleware');

// Category Routes
router.get('/categories', verifyToken, getCategories);
router.post('/categories', verifyToken, checkRole(['OWNER']), createCategory);

// Menu Item Routes
router.get('/items', verifyToken, getMenuItems);
router.post('/items', verifyToken, checkRole(['OWNER']), createMenuItem);
router.put('/items/:id', verifyToken, checkRole(['OWNER']), updateMenuItem);

module.exports = router;
