// server.js (የተስተካከለው ሙሉ ፋይል)
const paymentRoutes = require('./routes/paymentRoutes');
const shiftRoutes = require('./routes/shiftRoutes');
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/authRoutes');
const menuRoutes = require('./routes/menuRoutes');
const tableRoutes = require('./routes/tableRoutes');
const orderRoutes = require('./routes/orderRoutes');
const setupSocket = require('./sockets/socketHandler');

const app = express();
const server = http.createServer(app);

const io = socketIo(server, {
  cors: { origin: '*', methods: ['GET', 'POST', 'PATCH'] }
});

// Socket Instance ን በ Express app ውስጥ ማስቀመጥ (ለ Controller እንዲደረስ)
app.set('io', io);

// Socket Handlers ማስነሳት
setupSocket(io);

// Middlewares
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/menu', menuRoutes);
app.use('/api/v1/tables', tableRoutes);
app.use('/api/v1/orders', orderRoutes);
app.use('/api/v1/payments', paymentRoutes);
app.use('/api/v1/shifts', shiftRoutes);
app.get('/', (req, res) => {
  res.json({ message: 'Hotel Smart POS API & Real-time Server is running...' });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT}`);
});
