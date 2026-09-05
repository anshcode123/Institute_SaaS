const { Router } = require('express');
const { validateBody, validateQuery } = require('../middleware/validate');
const { authorize } = require('../middleware/authorize');
const { ROLES } = require('../constants/roles');
const {
  createTestSchema,
  updateTestSchema,
  addTestSubjectSchema,
  updateTestSubjectSchema,
  listTestsQuerySchema,
} = require('../validators/test.validators');
const { saveMarksSchema, listMarksQuerySchema } = require('../validators/marks.validators');
const testController = require('../controllers/test.controller');
const marksController = require('../controllers/marks.controller');
const resultController = require('../controllers/result.controller');

const router = Router();

// GET routes: both INSTITUTE_ADMIN and TEACHER (router-level authorize in
// routes/index.js); the service layer scopes a TEACHER's results to
// batches they're actually assigned to (assertCanAccessBatch). Every
// mutating/admin-only action additionally requires INSTITUTE_ADMIN.
router.post('/', authorize(ROLES.INSTITUTE_ADMIN), validateBody(createTestSchema), testController.createTest);
router.get('/', validateQuery(listTestsQuerySchema), testController.listTests);
router.get('/:id', testController.getTest);
router.patch(
  '/:id',
  authorize(ROLES.INSTITUTE_ADMIN),
  validateBody(updateTestSchema),
  testController.updateTest,
);
router.delete('/:id', authorize(ROLES.INSTITUTE_ADMIN), testController.cancelTest);

router.post(
  '/:id/subjects',
  authorize(ROLES.INSTITUTE_ADMIN),
  validateBody(addTestSubjectSchema),
  testController.addTestSubject,
);
router.patch(
  '/:id/subjects/:subjectId',
  authorize(ROLES.INSTITUTE_ADMIN),
  validateBody(updateTestSubjectSchema),
  testController.updateTestSubject,
);
router.delete(
  '/:id/subjects/:subjectId',
  authorize(ROLES.INSTITUTE_ADMIN),
  testController.removeTestSubject,
);

// Marks: both roles can save/view, restricted by batch assignment inside
// the service (a TEACHER not assigned to the test's batch is rejected).
router.post('/:id/marks', validateBody(saveMarksSchema), marksController.saveMarks);
router.get('/:id/marks', validateQuery(listMarksQuerySchema), marksController.listMarks);

router.get('/:id/results', resultController.getTestResults);
router.post('/:id/publish', authorize(ROLES.INSTITUTE_ADMIN), resultController.publishTest);
router.post('/:id/unpublish', authorize(ROLES.INSTITUTE_ADMIN), resultController.unpublishTest);

module.exports = router;
