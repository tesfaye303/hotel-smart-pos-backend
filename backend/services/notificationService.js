const admin = require('firebase-admin');

// አዲስ ትዕዛዝ ሲገባ ወደ ወጥ ቤት ስልኮች Push Notification መላኪያ
async function sendOrderNotificationToKitchen(orderId, tableName) {
  const message = {
    notification: {
      title: '🔔 አዲስ ትዕዛዝ ደርሷል!',
      body: `ከጠረጴዛ ${tableName} አዲስ ትዕዛዝ ተልኳል (Order #${orderId})`,
    },
    topic: 'kitchen',
  };

  try {
    await admin.messaging().send(message);
    console.log('Notification sent to kitchen successfully');
  } catch (error) {
    console.error('Error sending notification:', error);
  }
}

module.exports = { sendOrderNotificationToKitchen };