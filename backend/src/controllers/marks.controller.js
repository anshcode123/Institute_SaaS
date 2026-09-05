const { asyncHandler } = require('../middleware/async-handler');
const { sendSuccess } = require('../utils/response');
const marksService = require('../services/marks.service');

const saveMarks = asyncHandler(async function (req, res) {
  const marks = await marksService.saveMarks(req.auth.instituteId, req.params.id, req.auth, req.body);
  sendSuccess(res, marks, 'Marks saved');
});

const listMarks = asyncHandler(async function (req, res) {
  const marks = await marksService.listMarks(
    req.auth.instituteId,
    req.params.id,
    req.validatedQuery,
    req.auth,
  );
  sendSuccess(res, marks, 'Marks retrieved');
});

module.exports = { saveMarks, listMarks };
