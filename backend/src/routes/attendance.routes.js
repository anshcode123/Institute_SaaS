const { Router } = require('express');
const { validateBody, validateQuery } = require('../middleware/validate');
const {
  scanAttendanceSchema,
  scanLeavingSchema,
  manualAttendanceSchema,
  listAttendanceQuerySchema,
  batchSummaryQuerySchema,
} = require('../validators/attendance.validators');
const {
  scan,
  scanLeaving,
  markManual,
  listAttendance,
  getStudentSummary,
  getBatchSummary,
} = require('../controllers/attendance.controller');

const router = Router();

router.post('/scan', validateBody(scanAttendanceSchema), scan);
router.post('/scan-leaving', validateBody(scanLeavingSchema), scanLeaving);
router.post('/manual', validateBody(manualAttendanceSchema), markManual);
router.get('/', validateQuery(listAttendanceQuerySchema), listAttendance);
router.get('/students/:studentId/summary', getStudentSummary);
router.get('/batches/:batchId/summary', validateQuery(batchSummaryQuerySchema), getBatchSummary);

module.exports = router;
