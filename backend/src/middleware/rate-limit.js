const rateLimit = require('express-rate-limit');
const { sendError } = require('../utils/response');

// Applied only to login endpoints - brute-force mitigation, not a general
// API rate limit (that's a separate later concern).
const loginRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    sendError(res, 'Too many login attempts. Please try again later.', 429);
  },
});

module.exports = { loginRateLimiter };
