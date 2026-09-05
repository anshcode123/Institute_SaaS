const { AppError } = require('../utils/app-error');
const { sendError } = require('../utils/response');
const { isProduction } = require('../config/env');

// Catches errors from any route/controller passed via next(err).
// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  if (err instanceof AppError) {
    sendError(res, err.message, err.statusCode, err.details);
    return;
  }

  if (err && (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError')) {
    sendError(res, 'Invalid or expired token', 401);
    return;
  }

  console.error('[Unhandled Error]', err);
  const message = err instanceof Error ? err.message : 'Unexpected server error';
  sendError(res, isProduction ? 'Internal server error' : message, 500);
}

function notFoundHandler(req, res) {
  sendError(res, `Route not found: ${req.method} ${req.originalUrl}`, 404);
}

module.exports = { errorHandler, notFoundHandler };
