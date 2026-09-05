const { Router } = require('express');
const { validateBody, validateQuery } = require('../middleware/validate');
const {
  createFeeStructureSchema,
  updateFeeStructureSchema,
  listFeeStructuresQuerySchema,
} = require('../validators/fee-structure.validators');
const { assignFeeSchema, listStudentFeesQuerySchema } = require('../validators/student-fee.validators');
const {
  createFeeStructure,
  listFeeStructures,
  getFeeStructure,
  updateFeeStructure,
} = require('../controllers/fee-structure.controller');
const {
  assignFee,
  listStudentFees,
  getStudentFee,
  getFeesForStudent,
  getDashboard,
} = require('../controllers/student-fee.controller');

const router = Router();

// Fee structures (reusable templates)
router.post('/structures', validateBody(createFeeStructureSchema), createFeeStructure);
router.get('/structures', validateQuery(listFeeStructuresQuerySchema), listFeeStructures);
router.get('/structures/:id', getFeeStructure);
router.patch('/structures/:id', validateBody(updateFeeStructureSchema), updateFeeStructure);

// Assigning a fee structure to a student
router.post('/student', validateBody(assignFeeSchema), assignFee);
router.get('/student/:studentId', getFeesForStudent);

// Dashboard must be registered before the /:id catch-all below, or
// Express would treat "dashboard" as an :id value.
router.get('/dashboard', getDashboard);

// All assigned fees (institute-wide list)
router.get('/', validateQuery(listStudentFeesQuerySchema), listStudentFees);
router.get('/:id', getStudentFee);

module.exports = router;
