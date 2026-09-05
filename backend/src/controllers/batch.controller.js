const { asyncHandler } = require('../middleware/async-handler');
const { sendSuccess } = require('../utils/response');
const batchService = require('../services/batch.service');

const createBatch = asyncHandler(async (req, res) => {
  const batch = await batchService.createBatch(req.auth.instituteId, req.body);
  sendSuccess(res, batch, 'Batch created', 201);
});

const listBatches = asyncHandler(async (req, res) => {
  const result = await batchService.listBatches(req.auth.instituteId, req.validatedQuery, req.auth);
  sendSuccess(res, result, 'Batches retrieved');
});

const getBatch = asyncHandler(async (req, res) => {
  const batch = await batchService.getBatchById(req.auth.instituteId, req.params.id, req.auth);
  sendSuccess(res, batch, 'Batch retrieved');
});

const updateBatch = asyncHandler(async (req, res) => {
  const batch = await batchService.updateBatch(req.auth.instituteId, req.params.id, req.body);
  sendSuccess(res, batch, 'Batch updated');
});

const deactivateBatch = asyncHandler(async (req, res) => {
  const batch = await batchService.deactivateBatch(req.auth.instituteId, req.params.id);
  sendSuccess(res, batch, 'Batch deactivated');
});

const addStudents = asyncHandler(async (req, res) => {
  const batch = await batchService.addStudents(
    req.auth.instituteId,
    req.params.id,
    req.body.studentIds,
  );
  sendSuccess(res, batch, 'Students added to batch');
});

const removeStudents = asyncHandler(async (req, res) => {
  const batch = await batchService.removeStudents(
    req.auth.instituteId,
    req.params.id,
    req.body.studentIds,
  );
  sendSuccess(res, batch, 'Students removed from batch');
});

const assignTeachers = asyncHandler(async (req, res) => {
  const batch = await batchService.assignTeachers(
    req.auth.instituteId,
    req.params.id,
    req.body.teacherIds,
  );
  sendSuccess(res, batch, 'Teachers assigned to batch');
});

module.exports = {
  createBatch,
  listBatches,
  getBatch,
  updateBatch,
  deactivateBatch,
  addStudents,
  removeStudents,
  assignTeachers,
};
