const crypto = require('crypto');

// Opaque, unpredictable, carries zero student data - just a lookup key.
// base64url avoids characters that need escaping in a QR payload or URL.
// 24 random bytes -> 32 base64url chars, well beyond brute-force range.
function generateQrToken() {
  return crypto.randomBytes(24).toString('base64url');
}

module.exports = { generateQrToken };
