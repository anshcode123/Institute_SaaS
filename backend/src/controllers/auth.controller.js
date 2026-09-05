const { asyncHandler } = require('../middleware/async-handler');
const { sendSuccess } = require('../utils/response');
const authService = require('../services/auth.service');
const tokenService = require('../services/token.service');

const superAdminLogin = asyncHandler(async (req, res) => {
  const result = await authService.superAdminLogin(req.body);
  sendSuccess(res, result, 'Login successful');
});

const instituteLogin = asyncHandler(async (req, res) => {
  const result = await authService.instituteLogin(req.body);
  sendSuccess(res, result, 'Login successful');
});

const teacherLogin = asyncHandler(async (req, res) => {
  const result = await authService.teacherLogin(req.body);
  sendSuccess(res, result, 'Login successful');
});

const refresh = asyncHandler(async (req, res) => {
  const tokens = await tokenService.rotateTokens(req.body.refreshToken);
  sendSuccess(res, tokens, 'Token refreshed');
});

const logout = asyncHandler(async (req, res) => {
  await tokenService.revokeByToken(req.body.refreshToken);
  sendSuccess(res, null, 'Logged out');
});

module.exports = { superAdminLogin, instituteLogin, teacherLogin, refresh, logout };
