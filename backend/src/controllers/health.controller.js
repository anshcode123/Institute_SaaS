const { asyncHandler } = require('../middleware/async-handler');
const { sendSuccess } = require('../utils/response');
const { getHealthStatus } = require('../services/health.service');

const checkHealth = asyncHandler(async (req, res) => {
  const status = await getHealthStatus();
  sendSuccess(res, status, 'API is running');
});

module.exports = { checkHealth };
