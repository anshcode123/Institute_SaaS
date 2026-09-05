const { asyncHandler } = require('../middleware/async-handler');
const { sendSuccess } = require('../utils/response');
const feeStructureService = require('../services/fee-structure.service');

const createFeeStructure = asyncHandler(async (req, res) => {
  const structure = await feeStructureService.createFeeStructure(
    req.auth.instituteId,
    req.auth.userId,
    req.body,
  );
  sendSuccess(res, structure, 'Fee structure created', 201);
});

const listFeeStructures = asyncHandler(async (req, res) => {
  const result = await feeStructureService.listFeeStructures(req.auth.instituteId, req.validatedQuery);
  sendSuccess(res, result, 'Fee structures retrieved');
});

const getFeeStructure = asyncHandler(async (req, res) => {
  const structure = await feeStructureService.getFeeStructureById(req.auth.instituteId, req.params.id);
  sendSuccess(res, structure, 'Fee structure retrieved');
});

const updateFeeStructure = asyncHandler(async (req, res) => {
  const structure = await feeStructureService.updateFeeStructure(
    req.auth.instituteId,
    req.params.id,
    req.body,
  );
  sendSuccess(res, structure, 'Fee structure updated');
});

module.exports = { createFeeStructure, listFeeStructures, getFeeStructure, updateFeeStructure };
