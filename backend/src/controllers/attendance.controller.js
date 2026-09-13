const { asyncHandler } = require('../middleware/async-handler');
const { sendSuccess } = require('../utils/response');
const attendanceService = require('../services/attendance.service');

const scan = asyncHandler(async (req, res) => {
  const result = await attendanceService.scanAttendance(req.auth.instituteId, req.auth, req.body);
  const message = result.alreadyMarked ? 'Attendance already marked' : 'Attendance marked';
  sendSuccess(res, result, message, result.alreadyMarked ? 200 : 201);
});

const scanLeaving = asyncHandler(async (req, res) => {
  const result = await attendanceService.scanLeaving(req.auth.instituteId, req.auth, req.body);
  sendSuccess(res, result, result.message || 'Leaving recorded');
});

const markManual = asyncHandler(async (req, res) => {
  const records = await attendanceService.markManual(req.auth.instituteId, req.auth, req.body);
  sendSuccess(res, records, 'Attendance updated');
});

const listAttendance = asyncHandler(async (req, res) => {
  const result = await attendanceService.listAttendance(
    req.auth.instituteId,
    req.auth,
    req.validatedQuery,
  );
  sendSuccess(res, result, 'Attendance retrieved');
});

const getStudentSummary = asyncHandler(async (req, res) => {
  const summary = await attendanceService.getStudentSummary(
    req.auth.instituteId,
    req.auth,
    req.params.studentId,
  );
  sendSuccess(res, summary, 'Student attendance summary retrieved');
});

const getBatchSummary = asyncHandler(async (req, res) => {
  const summary = await attendanceService.getBatchSummary(
    req.auth.instituteId,
    req.auth,
    req.params.batchId,
    req.validatedQuery?.date,
  );
  sendSuccess(res, summary, 'Batch attendance summary retrieved');
});

module.exports = { scan, scanLeaving, markManual, listAttendance, getStudentSummary, getBatchSummary };
