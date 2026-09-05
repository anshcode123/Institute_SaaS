const { asyncHandler } = require('../middleware/async-handler');
const { sendSuccess } = require('../utils/response');
const instituteService = require('../services/institute.service');

const createInstitute = asyncHandler(async (req, res) => {
  const { institute, instituteCode, initialPassword } = await instituteService.createInstitute(
    req.body,
  );

  sendSuccess(
    res,
    {
      institute,
      credentials: {
        instituteCode,
        // Returned only once, at creation time. Never retrievable again -
        // only its hash is stored.
        initialPassword,
      },
    },
    'Institute created',
    201,
  );
});

const listInstitutes = asyncHandler(async (req, res) => {
  const institutes = await instituteService.listInstitutes();
  sendSuccess(res, institutes, 'Institutes retrieved');
});

const getInstitute = asyncHandler(async (req, res) => {
  const institute = await instituteService.getInstituteById(req.params.id);
  sendSuccess(res, institute, 'Institute retrieved');
});

const updateInstituteStatus = asyncHandler(async (req, res) => {
  const institute = await instituteService.updateInstituteStatus(req.params.id, req.body.status);
  sendSuccess(res, institute, 'Institute status updated');
});

module.exports = { createInstitute, listInstitutes, getInstitute, updateInstituteStatus };
