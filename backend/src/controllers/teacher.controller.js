const { asyncHandler } = require('../middleware/async-handler');
const { sendSuccess } = require('../utils/response');
const teacherService = require('../services/teacher.service');

const createTeacher = asyncHandler(async (req, res) => {
  const teacher = await teacherService.createTeacher(req.auth.instituteId, req.body);
  sendSuccess(res, teacher, 'Teacher created', 201);
});

const listTeachers = asyncHandler(async (req, res) => {
  const result = await teacherService.listTeachers(req.auth.instituteId, req.validatedQuery);
  sendSuccess(res, result, 'Teachers retrieved');
});

const getTeacher = asyncHandler(async (req, res) => {
  const teacher = await teacherService.getTeacherById(req.auth.instituteId, req.params.id);
  sendSuccess(res, teacher, 'Teacher retrieved');
});

const updateTeacher = asyncHandler(async (req, res) => {
  const teacher = await teacherService.updateTeacher(req.auth.instituteId, req.params.id, req.body);
  sendSuccess(res, teacher, 'Teacher updated');
});

const deactivateTeacher = asyncHandler(async (req, res) => {
  const teacher = await teacherService.deactivateTeacher(req.auth.instituteId, req.params.id);
  sendSuccess(res, teacher, 'Teacher deactivated');
});

const assignBatches = asyncHandler(async (req, res) => {
  const teacher = await teacherService.assignBatches(
    req.auth.instituteId,
    req.params.id,
    req.body.batchIds,
  );
  sendSuccess(res, teacher, 'Teacher assigned to batches');
});

const assignSubjects = asyncHandler(async (req, res) => {
  const teacher = await teacherService.assignSubjects(
    req.auth.instituteId,
    req.params.id,
    req.body.subjectIds,
  );
  sendSuccess(res, teacher, 'Teacher assigned to subjects');
});

const createLogin = asyncHandler(async (req, res) => {
  const result = await teacherService.createTeacherLogin(req.auth.instituteId, req.params.id);
  sendSuccess(
    res,
    result,
    'Teacher login created - save this password now, it will not be shown again',
    201,
  );
});

module.exports = {
  createTeacher,
  listTeachers,
  getTeacher,
  updateTeacher,
  deactivateTeacher,
  assignBatches,
  assignSubjects,
  createLogin,
};
