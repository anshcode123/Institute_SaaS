const { asyncHandler } = require('../middleware/async-handler');
const { sendSuccess } = require('../utils/response');
const parentService = require('../services/parent.service');

const createParent = asyncHandler(async (req, res) => {
  const parent = await parentService.createParent(req.auth.instituteId, req.body);
  sendSuccess(res, parent, 'Parent created', 201);
});

const listParents = asyncHandler(async (req, res) => {
  const result = await parentService.listParents(req.auth.instituteId, req.validatedQuery);
  sendSuccess(res, result, 'Parents retrieved');
});

const getParent = asyncHandler(async (req, res) => {
  const parent = await parentService.getParentById(req.auth.instituteId, req.params.id);
  sendSuccess(res, parent, 'Parent retrieved');
});

const updateParent = asyncHandler(async (req, res) => {
  const parent = await parentService.updateParent(req.auth.instituteId, req.params.id, req.body);
  sendSuccess(res, parent, 'Parent updated');
});

const deactivateParent = asyncHandler(async (req, res) => {
  const parent = await parentService.deactivateParent(req.auth.instituteId, req.params.id);
  sendSuccess(res, parent, 'Parent deactivated');
});

const createLogin = asyncHandler(async (req, res) => {
  const result = await parentService.createParentLogin(
    req.auth.instituteId,
    req.params.id,
    req.body || {},
  );
  sendSuccess(res, result, 'Parent login account created', 201);
});

const resetPassword = asyncHandler(async (req, res) => {
  const result = await parentService.resetParentPassword(
    req.auth.instituteId,
    req.params.id,
    req.body || {},
  );
  sendSuccess(res, result, 'Parent password reset successfully');
});

module.exports = {
  createParent,
  listParents,
  getParent,
  updateParent,
  deactivateParent,
  createLogin,
  resetPassword,
};
