const { z } = require('zod');

const superAdminLoginSchema = z.object({
  email: z.string().email('Valid email is required'),
  password: z.string().min(1, 'Password is required'),
});

const instituteLoginSchema = z.object({
  instituteCode: z.string().min(1, 'Institute ID is required'),
  password: z.string().min(1, 'Password is required'),
});

// Structurally identical to superAdminLoginSchema (email + password) but
// kept as its own named schema since the two roles' login semantics are
// conceptually distinct, even though the shape matches today.
const teacherLoginSchema = z.object({
  email: z.string().email('Valid email is required'),
  password: z.string().min(1, 'Password is required'),
});

const refreshSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required'),
});

const logoutSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required'),
});

const studentLoginSchema = z.object({
  email: z.string().min(1, 'Email or Login ID is required'),
  password: z.string().min(1, 'Password is required'),
});

const parentLoginSchema = z.object({
  email: z.string().min(1, 'Email or Login ID is required'),
  password: z.string().min(1, 'Password is required'),
});

module.exports = {
  superAdminLoginSchema,
  instituteLoginSchema,
  teacherLoginSchema,
  studentLoginSchema,
  parentLoginSchema,
  refreshSchema,
  logoutSchema,
};
