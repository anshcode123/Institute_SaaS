const { Router } = require('express');
const { validateBody, validateQuery } = require('../middleware/validate');
const {
  createStudentSchema,
  updateStudentSchema,
  listStudentsQuerySchema,
  linkParentSchema,
  assignBatchSchema,
} = require('../validators/student.validators');
const {
  createStudent,
  listStudents,
  getStudent,
  updateStudent,
  deactivateStudent,
  linkParent,
  unlinkParent,
  assignBatch,
} = require('../controllers/student.controller');

const router = Router();

router.post('/', validateBody(createStudentSchema), createStudent);
router.get('/', validateQuery(listStudentsQuerySchema), listStudents);
router.get('/:id', getStudent);
router.patch('/:id', validateBody(updateStudentSchema), updateStudent);
router.delete('/:id', deactivateStudent);

router.post('/:studentId/parent', validateBody(linkParentSchema), linkParent);
router.delete('/:studentId/parent/:parentId', unlinkParent);
router.post('/:studentId/batch', validateBody(assignBatchSchema), assignBatch);

module.exports = router;
