const { asyncHandler } = require('../middleware/async-handler');
const { sendSuccess } = require('../utils/response');
const resultService = require('../services/result.service');

const getTestResults = asyncHandler(async function (req, res) {
  const results = await resultService.getTestResults(req.auth.instituteId, req.params.id, req.auth);
  sendSuccess(res, results, 'Results retrieved');
});

const publishTest = asyncHandler(async function (req, res) {
  const test = await resultService.publishTest(req.auth.instituteId, req.params.id);
  sendSuccess(res, test, 'Results published');
});

const unpublishTest = asyncHandler(async function (req, res) {
  const test = await resultService.unpublishTest(req.auth.instituteId, req.params.id);
  sendSuccess(res, test, 'Results unpublished');
});

const getStudentResults = asyncHandler(async function (req, res) {
  const results = await resultService.getStudentResults(
    req.auth.instituteId,
    req.auth,
    req.params.studentId,
  );
  sendSuccess(res, results, 'Student results retrieved');
});

const getStudentResultById = asyncHandler(async function (req, res) {
  const result = await resultService.getStudentResultById(
    req.auth.instituteId,
    req.auth,
    req.params.studentId,
    req.params.resultId,
  );
  sendSuccess(res, result, 'Result retrieved');
});

module.exports = {
  getTestResults: getTestResults,
  publishTest: publishTest,
  unpublishTest: unpublishTest,
  getStudentResults: getStudentResults,
  getStudentResultById: getStudentResultById,
};
