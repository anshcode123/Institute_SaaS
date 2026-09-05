const { Router } = require('express');
const { validateBody, validateQuery } = require('../middleware/validate');
const { authorize } = require('../middleware/authorize');
const { ROLES } = require('../constants/roles');
const {
  createBatchSchema,
  updateBatchSchema,
  listBatchesQuerySchema,
  addStudentsSchema,
  removeStudentsSchema,
  assignTeachersSchema,
} = require('../validators/batch.validators');
const {
  createBatch,
  listBatches,
  getBatch,
  updateBatch,
  deactivateBatch,
  addStudents,
  removeStudents,
  assignTeachers,
} = require('../controllers/batch.controller');

const router = Router();

// GET routes are reachable by INSTITUTE_ADMIN and TEACHER (see routes/index.js
// router-level authorize); the service layer scopes a TEACHER's results to
// their own assigned batches. Every mutating route additionally requires
// INSTITUTE_ADMIN specifically - teachers manage attendance, not batches.
router.post('/', authorize(ROLES.INSTITUTE_ADMIN), validateBody(createBatchSchema), createBatch);
router.get('/', validateQuery(listBatchesQuerySchema), listBatches);
router.get('/:id', getBatch);
router.patch('/:id', authorize(ROLES.INSTITUTE_ADMIN), validateBody(updateBatchSchema), updateBatch);
router.delete('/:id', authorize(ROLES.INSTITUTE_ADMIN), deactivateBatch);

router.post(
  '/:id/students',
  authorize(ROLES.INSTITUTE_ADMIN),
  validateBody(addStudentsSchema),
  addStudents,
);
router.delete(
  '/:id/students',
  authorize(ROLES.INSTITUTE_ADMIN),
  validateBody(removeStudentsSchema),
  removeStudents,
);
router.post(
  '/:id/teachers',
  authorize(ROLES.INSTITUTE_ADMIN),
  validateBody(assignTeachersSchema),
  assignTeachers,
);

module.exports = router;
