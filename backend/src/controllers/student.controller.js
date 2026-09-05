const { asyncHandler } = require('../middleware/async-handler');
const { sendSuccess } = require('../utils/response');
const studentService = require('../services/student.service');

const createStudent = asyncHandler(async (req, res) => {
  const student = await studentService.createStudent(req.auth.instituteId, req.body);
  sendSuccess(res, student, 'Student created', 201);
});

const listStudents = asyncHandler(async (req, res) => {
  const result = await studentService.listStudents(req.auth.instituteId, req.validatedQuery);
  sendSuccess(res, result, 'Students retrieved');
});

const getStudent = asyncHandler(async (req, res) => {
  const student = await studentService.getStudentById(req.auth.instituteId, req.params.id);
  sendSuccess(res, student, 'Student retrieved');
});

const updateStudent = asyncHandler(async (req, res) => {
  const student = await studentService.updateStudent(
    req.auth.instituteId,
    req.params.id,
    req.body,
  );
  sendSuccess(res, student, 'Student updated');
});

const deactivateStudent = asyncHandler(async (req, res) => {
  const student = await studentService.deactivateStudent(req.auth.instituteId, req.params.id);
  sendSuccess(res, student, 'Student deactivated');
});

const linkParent = asyncHandler(async (req, res) => {
  const link = await studentService.linkParent(
    req.auth.instituteId,
    req.params.studentId,
    req.body,
  );
  sendSuccess(res, link, 'Parent linked to student', 201);
});

const unlinkParent = asyncHandler(async (req, res) => {
  await studentService.unlinkParent(req.auth.instituteId, req.params.studentId, req.params.parentId);
  sendSuccess(res, null, 'Parent unlinked from student');
});

const assignBatch = asyncHandler(async (req, res) => {
  const student = await studentService.assignBatch(
    req.auth.instituteId,
    req.params.studentId,
    req.body.batchId,
  );
  sendSuccess(res, student, 'Student assigned to batch');
});

module.exports = {
  createStudent,
  listStudents,
  getStudent,
  updateStudent,
  deactivateStudent,
  linkParent,
  unlinkParent,
  assignBatch,
};
