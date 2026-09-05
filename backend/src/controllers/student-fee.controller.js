const { asyncHandler } = require('../middleware/async-handler');
const { sendSuccess } = require('../utils/response');
const studentFeeService = require('../services/student-fee.service');
const dashboardService = require('../services/fee-dashboard.service');

const assignFee = asyncHandler(async (req, res) => {
  const studentFee = await studentFeeService.assignFee(req.auth.instituteId, req.auth.userId, req.body);
  sendSuccess(res, studentFee, 'Fee assigned', 201);
});

const listStudentFees = asyncHandler(async (req, res) => {
  const result = await studentFeeService.listStudentFees(req.auth.instituteId, req.validatedQuery);
  sendSuccess(res, result, 'Student fees retrieved');
});

const getStudentFee = asyncHandler(async (req, res) => {
  const studentFee = await studentFeeService.getStudentFeeById(req.auth.instituteId, req.params.id);
  sendSuccess(res, studentFee, 'Student fee retrieved');
});

const getFeesForStudent = asyncHandler(async (req, res) => {
  const result = await studentFeeService.getFeesForStudent(req.auth.instituteId, req.params.studentId);
  sendSuccess(res, result, 'Student fees retrieved');
});

const getDashboard = asyncHandler(async (req, res) => {
  const summary = await dashboardService.getDashboardSummary(req.auth.instituteId);
  sendSuccess(res, summary, 'Fee dashboard retrieved');
});

module.exports = { assignFee, listStudentFees, getStudentFee, getFeesForStudent, getDashboard };
