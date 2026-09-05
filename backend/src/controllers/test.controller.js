const { asyncHandler } = require('../middleware/async-handler');
const { sendSuccess } = require('../utils/response');
const testService = require('../services/test.service');

const createTest = asyncHandler(async function (req, res) {
  const test = await testService.createTest(req.auth.instituteId, req.auth.userId, req.body);
  sendSuccess(res, test, 'Test created', 201);
});

const listTests = asyncHandler(async function (req, res) {
  const result = await testService.listTests(req.auth.instituteId, req.validatedQuery, req.auth);
  sendSuccess(res, result, 'Tests retrieved');
});

const getTest = asyncHandler(async function (req, res) {
  const test = await testService.getTestById(req.auth.instituteId, req.params.id, req.auth);
  sendSuccess(res, test, 'Test retrieved');
});

const updateTest = asyncHandler(async function (req, res) {
  const test = await testService.updateTest(req.auth.instituteId, req.params.id, req.body);
  sendSuccess(res, test, 'Test updated');
});

const cancelTest = asyncHandler(async function (req, res) {
  const test = await testService.cancelTest(req.auth.instituteId, req.params.id);
  sendSuccess(res, test, 'Test cancelled');
});

const addTestSubject = asyncHandler(async function (req, res) {
  const test = await testService.addTestSubject(req.auth.instituteId, req.params.id, req.body);
  sendSuccess(res, test, 'Subject added to test', 201);
});

const updateTestSubject = asyncHandler(async function (req, res) {
  const test = await testService.updateTestSubject(
    req.auth.instituteId,
    req.params.id,
    req.params.subjectId,
    req.body,
  );
  sendSuccess(res, test, 'Test subject updated');
});

const removeTestSubject = asyncHandler(async function (req, res) {
  const test = await testService.removeTestSubject(
    req.auth.instituteId,
    req.params.id,
    req.params.subjectId,
  );
  sendSuccess(res, test, 'Subject removed from test');
});

module.exports = {
  createTest,
  listTests,
  getTest,
  updateTest,
  cancelTest,
  addTestSubject,
  updateTestSubject,
  removeTestSubject,
};
