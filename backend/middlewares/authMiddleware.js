const jwt = require('jsonwebtoken');

// 1. የ Token ትክክለኛነት ማረጋገጫ
const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Format: "Bearer <TOKEN>"

  if (!token) {
    return res.status(401).json({ message: 'ተከልክሏል፡ የይለፍ ማስረጃ (Token) አልቀረበም!' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // { id, full_name, role } መረጃን ወደ Request አካል መጨመር
    next();
  } catch (err) {
    return res.status(403).json({ message: 'የተሳሳተ ወይም ጊዜው ያለፈበት Token!' });
  }
};

// 2. የተጠቃሚ መብት (Role-Based Access Control) ማረጋገጫ
const checkRole = (allowedRoles) => {
  return (req, res, next) => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ 
        message: 'የተከለከለ፡ ይህን ድርጊት ለመፈጸም የሚያስችል የመብት ደረጃ (Role) የለዎትም!' 
      });
    }
    next();
  };
};

module.exports = { verifyToken, checkRole };