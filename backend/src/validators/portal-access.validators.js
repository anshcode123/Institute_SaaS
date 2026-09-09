const { z } = require('zod');

var setPortalPasswordSchema = z
  .object({
    password: z.string().min(6, 'Password must be at least 6 characters'),
    confirmPassword: z.string().min(1, 'Please confirm the password'),
  })
  .refine(function (data) { return data.password === data.confirmPassword; }, {
    message: 'Passwords do not match',
    path: ['confirmPassword'],
  });

var setPortalEnabledSchema = z.object({
  enabled: z.boolean(),
});

module.exports = {
  setPortalPasswordSchema: setPortalPasswordSchema,
  resetPortalPasswordSchema: setPortalPasswordSchema,
  setPortalEnabledSchema: setPortalEnabledSchema,
};
