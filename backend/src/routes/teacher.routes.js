const { Router } = require('express');
const { validateBody, validateQuery } = require('../middleware/validate');
const {
  createTeacherSchema,
  updateTeacherSchema,
  listTeachersQuerySchema,
  assignBatchesSchema,
  assignSubjectsSchema,
} = require('../validators/teacher.validators');
const {
  createTeacher,
  listTeachers,
  getTeacher,
  updateTeacher,
  deactivateTeacher,
  assignBatches,
  assignSubjects,
  createLogin,
} = require('../controllers/teacher.controller');

const router = Router();

router.post('/', validateBody(createTeacherSchema), createTeacher);
router.get('/', validateQuery(listTeachersQuerySchema), listTeachers);
router.get('/:id', getTeacher);
router.patch('/:id', validateBody(updateTeacherSchema), updateTeacher);
router.delete('/:id', deactivateTeacher);

router.post('/:id/batches', validateBody(assignBatchesSchema), assignBatches);
router.post('/:id/subjects', validateBody(assignSubjectsSchema), assignSubjects);
router.post('/:id/login', createLogin);

module.exports = router;
