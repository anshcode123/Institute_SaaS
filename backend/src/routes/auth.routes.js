const { Router } = require('express');
const { validateBody } = require('../middleware/validate');
const { loginRateLimiter } = require('../middleware/rate-limit');
const {
  superAdminLoginSchema,
  instituteLoginSchema,
  teacherLoginSchema,
  refreshSchema,
  logoutSchema,
} = require('../validators/auth.validators');
const {
  superAdminLogin,
  instituteLogin,
  teacherLogin,
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

router.post('/refresh', validateBody(refreshSchema), refresh);

router.post('/logout', validateBody(logoutSchema), logout);

module.exports = router;
