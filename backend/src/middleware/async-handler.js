// Wraps async controllers so thrown/rejected errors reach errorHandler
// without needing try/catch in every controller.
function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

module.exports = { asyncHandler };
