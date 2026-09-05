const { Router } = require('express');
const healthRoutes = require('./health.routes');
const authRoutes = require('./auth.routes');
const adminRoutes = require('./admin.routes');
const studentRoutes = require('./student.routes');
const parentRoutes = require('./parent.routes');
const teacherRoutes = require('./teacher.routes');
const batchRoutes = require('./batch.routes');
const attendanceRoutes = require('./attendance.routes');
const feeRoutes = require('./fee.routes');
const { paymentsRouter, receiptsRouter } = require('./payment.routes');
const testRoutes = require('./test.routes');
const studentResultsRoutes = require('./student-results.routes');
const { authenticate } = require('../middleware/authenticate');
const { authorize } = require('../middleware/authorize');
const { ROLES } = require('../constants/roles');

const router = Router();

router.use('/', healthRoutes);
router.use('/auth', authRoutes);
router.use('/admin', adminRoutes);

// Student results (Phase 6): mounted BEFORE the general Institute-Admin
// -only /students gate below, with its own [INSTITUTE_ADMIN, TEACHER]
// authorize - a Teacher needs their own students' results without full
// student-management access. Any /students request that doesn't match a
// route here (e.g. creating a student) falls through unaffected to the
// stricter gate + studentRoutes right after.
router.use('/students', authenticate, authorize(ROLES.INSTITUTE_ADMIN, ROLES.TEACHER), studentResultsRoutes);

// Phase 3 resources: Institute Admin only. authenticate -> authorize ->
// controller, same pattern as admin.routes.js. instituteId always comes
// from req.auth (set by authenticate from the verified token), never
// from the request itself.
router.use(['/students', '/parents', '/teachers'], authenticate, authorize(ROLES.INSTITUTE_ADMIN));
router.use('/students', studentRoutes);
router.use('/parents', parentRoutes);
router.use('/teachers', teacherRoutes);

// Batches: both INSTITUTE_ADMIN and TEACHER can reach these routes (a
// teacher needs to see their own assigned batches for attendance); the
// finer-grained split between read (both roles) and write
// (INSTITUTE_ADMIN only) lives in batch.routes.js itself.
router.use('/batches', authenticate, authorize(ROLES.INSTITUTE_ADMIN, ROLES.TEACHER));
router.use('/batches', batchRoutes);

// Phase 4: attendance. Both roles can reach every route here; the service
// layer enforces that a TEACHER can only act on/view batches they're
// actually assigned to (see utils/teacher-access.js).
router.use('/attendance', authenticate, authorize(ROLES.INSTITUTE_ADMIN, ROLES.TEACHER));
router.use('/attendance', attendanceRoutes);

// Phase 5: fees, payments, receipts. Institute Admin only - Teachers get
// no financial access by default (spec Section 20). There is no
// separate student/parent portal login (see README), so "student fee
// view" / "parent fee view" are Institute-Admin-mediated reads via
// GET /fees/student/:studentId, not a self-service endpoint.
router.use(
  ['/fees', '/payments', '/receipts'],
  authenticate,
  authorize(ROLES.INSTITUTE_ADMIN),
);
router.use('/fees', feeRoutes);
router.use('/payments', paymentsRouter);
router.use('/receipts', receiptsRouter);

// Phase 6: tests, marks, results. Both roles reach every route here (same
// pattern as attendance/batches); test.routes.js itself gates the
// admin-only actions (create/edit/delete test, subject config,
// publish/unpublish) with an additional authorize(INSTITUTE_ADMIN).
router.use('/tests', authenticate, authorize(ROLES.INSTITUTE_ADMIN, ROLES.TEACHER));
router.use('/tests', testRoutes);

module.exports = router;
