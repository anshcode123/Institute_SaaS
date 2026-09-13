const { Router } = require('express');
const { validateBody } = require('../middleware/validate');
const { loginRateLimiter } = require('../middleware/rate-limit');
const {
  superAdminLoginSchema,
  instituteLoginSchema,
  teacherLoginSchema,
  studentLoginSchema,
  parentLoginSchema,
  refreshSchema,
  logoutSchema,
} = require('../validators/auth.validators');
const {
  superAdminLogin,
  instituteLogin,
  teacherLogin,
  studentLogin,
  parentLogin,
  refresh,
  logout,
} = require('../controllers/auth.controller');

const router = Router();

router.post(
  '/super-admin/login',
  loginRateLimiter,
  validateBody(superAdminLoginSchema),
  superAdminLogin,
);

router.post('/institute/login', loginRateLimiter, validateBody(instituteLoginSchema), instituteLogin);

router.post('/teacher/login', loginRateLimiter, validateBody(teacherLoginSchema), teacherLogin);

router.post('/student/login', loginRateLimiter, validateBody(studentLoginSchema), studentLogin);

router.post('/parent/login', loginRateLimiter, validateBody(parentLoginSchema), parentLogin);

router.post('/refresh', validateBody(refreshSchema), refresh);

router.post('/logout', validateBody(logoutSchema), logout);

module.exports = router;
