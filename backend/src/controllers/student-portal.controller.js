const { asyncHandler } = require('../middleware/async-handler');
const { sendSuccess } = require('../utils/response');
const service = require('../services/student-portal.service');

const getMe = asyncHandler(async function (req, res) {
  const profile = await service.getMyProfile(req.auth.instituteId, req.auth.userId);
  sendSuccess(res, profile, 'Profile retrieved');
});

const getDashboard = asyncHandler(async function (req, res) {
  const dashboard = await service.getMyDashboard(req.auth.instituteId, req.auth.userId);
  sendSuccess(res, dashboard, 'Dashboard retrieved');
});

const getAttendance = asyncHandler(async function (req, res) {
  const result = await service.getMyAttendance(req.auth.instituteId, req.auth.userId, req.validatedQuery || {});
  sendSuccess(res, result, 'Attendance retrieved');
});

const getQrCodes = asyncHandler(async function (req, res) {
  const codes = await service.getMyQrCodes(req.auth.instituteId, req.auth.userId);
  sendSuccess(res, codes, 'QR codes retrieved');
});

const getFees = asyncHandler(async function (req, res) {
  const fees = await service.getMyFees(req.auth.instituteId, req.auth.userId);
  sendSuccess(res, fees, 'Fees retrieved');
});

const getPayments = asyncHandler(async function (req, res) {
  const payments = await service.getMyPayments(req.auth.instituteId, req.auth.userId, req.validatedQuery || {});
  sendSuccess(res, payments, 'Payments retrieved');
});

const getReceipt = asyncHandler(async function (req, res) {
  const receipt = await service.getMyReceipt(req.auth.instituteId, req.auth.userId, req.params.id);
  sendSuccess(res, receipt, 'Receipt retrieved');
});

const getResults = asyncHandler(async function (req, res) {
  const results = await service.getMyResults(req.auth.instituteId, req.auth.userId);
  sendSuccess(res, results, 'Results retrieved');
});

const getResultById = asyncHandler(async function (req, res) {
  const result = await service.getMyResultById(req.auth.instituteId, req.auth.userId, req.params.id);
  sendSuccess(res, result, 'Result retrieved');
});

const getAnnouncements = asyncHandler(async function (req, res) {
  const announcements = await service.getMyAnnouncements(req.auth.instituteId, req.auth.userId);
  sendSuccess(res, announcements, 'Announcements retrieved');
});

module.exports = {
  getMe: getMe,
  getDashboard: getDashboard,
  getAttendance: getAttendance,
  getQrCodes: getQrCodes,
  getFees: getFees,
  getPayments: getPayments,
  getReceipt: getReceipt,
  getResults: getResults,
  getResultById: getResultById,
  getAnnouncements: getAnnouncements,
};
