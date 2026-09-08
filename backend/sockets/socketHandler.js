// sockets/socketHandler.js
const setupSocket = (io) => {
  io.on('connection', (socket) => {
    console.log(`🔌 አዲስ መሳሪያ ተገናኝቷል: ${socket.id}`);

    // ተጠቃሚዎች እንደ ስራ ድርሻቸው ወደ ክፍላቸው እንዲገቡ ማድረግ
    socket.on('join_room', (data) => {
      const { role, userId } = data;

      if (role === 'CHEF') {
        socket.join('room:kitchen');
        console.log(`👨🍳 Socket ${socket.id} ወደ 'room:kitchen' ገብቷል`);
      } else if (role === 'WAITRESS') {
        socket.join(`room:waitress_${userId}`);
        console.log(`👩🍳 Waitress ${userId} ወደ 'room:waitress_${userId}' ገብታለች`);
      } else if (role === 'CASHIER') {
        socket.join('room:cashier');
      }
    });

    socket.on('disconnect', () => {
      console.log(`❌ መሳሪያ ተቋርጧል: ${socket.id}`);
    });
  });
};

module.exports = setupSocket;
