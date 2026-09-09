const { asyncHandler } = require('../middleware/async-handler');
const { sendSuccess } = require('../utils/response');
const service = require('../services/parent-portal.service');

const getMe = asyncHandler(async function (req, res) {
  const profile = await service.getMyProfile(req.auth.instituteId, req.auth.userId);
  sendSuccess(res, profile, 'Profile retrieved');
});

const getChildren = asyncHandler(async function (req, res) {
  const children = await service.getMyChildren(req.auth.instituteId, req.auth.userId);
  sendSuccess(res, children, 'Children retrieved');
});

const getChildDashboard = asyncHandler(async function (req, res) {
  const dashboard = await service.getChildDashboard(req.auth.instituteId, req.auth, req.params.studentId);
  sendSuccess(res, dashboard, 'Dashboard retrieved');
});

const getChildAttendance = asyncHandler(async function (req, res) {
  const result = await service.getChildAttendance(
    req.auth.instituteId,
    req.auth,
    req.params.studentId,
    req.validatedQuery || {},
  );
  sendSuccess(res, result, 'Attendance retrieved');
});

const getChildFees = asyncHandler(async function (req, res) {
  const fees = await service.getChildFees(req.auth.instituteId, req.auth, req.params.studentId);
  sendSuccess(res, fees, 'Fees retrieved');
});

const getChildPayments = asyncHandler(async function (req, res) {
  const payments = await service.getChildPayments(
    req.auth.instituteId,
    req.auth,
    req.params.studentId,
    req.validatedQuery || {},
  );
  sendSuccess(res, payments, 'Payments retrieved');
});

const getChildReceipt = asyncHandler(async function (req, res) {
  const receipt = await service.getChildReceipt(
    req.auth.instituteId,
    req.auth,
    req.params.studentId,
    req.params.receiptId,
  );
  sendSuccess(res, receipt, 'Receipt retrieved');
});

const getChildResults = asyncHandler(async function (req, res) {
  const results = await service.getChildResults(req.auth.instituteId, req.auth, req.params.studentId);
  sendSuccess(res, results, 'Results retrieved');
});

const getChildResultById = asyncHandler(async function (req, res) {
  const result = await service.getChildResultById(
    req.auth.instituteId,
    req.auth,
    req.params.studentId,
    req.params.resultId,
  );
  sendSuccess(res, result, 'Result retrieved');
});

const getChildAnnouncements = asyncHandler(async function (req, res) {
  const announcements = await service.getChildAnnouncements(
    req.auth.instituteId,
    req.auth,
    req.params.studentId,
  );
  sendSuccess(res, announcements, 'Announcements retrieved');
});

module.exports = {
  getMe: getMe,
  getChildren: getChildren,
  getChildDashboard: getChildDashboard,
  getChildAttendance: getChildAttendance,
  getChildFees: getChildFees,
  getChildPayments: getChildPayments,
  getChildReceipt: getChildReceipt,
  getChildResults: getChildResults,
  getChildResultById: getChildResultById,
  getChildAnnouncements: getChildAnnouncements,
};
