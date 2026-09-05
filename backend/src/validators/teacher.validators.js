const { z } = require('zod');
const { RECORD_STATUS } = require('../constants/roles');

const createTeacherSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  phone: z.string().optional(),
  email: z.string().email('Invalid email').optional(),
  profilePhoto: z.string().url().optional(),
  address: z.string().optional(),
  joiningDate: z
    .string()
    .refine((v) => !Number.isNaN(Date.parse(v)), 'Must be a valid date')
    .transform((v) => new Date(v))
    .optional(),
});

const updateTeacherSchema = createTeacherSchema.partial().extend({
  status: z.enum([RECORD_STATUS.ACTIVE, RECORD_STATUS.INACTIVE]).optional(),
});

const listTeachersQuerySchema = z.object({
  q: z.string().optional(),
  status: z.enum([RECORD_STATUS.ACTIVE, RECORD_STATUS.INACTIVE]).optional(),
  page: z.coerce.number().int().min(1).optional(),
  limit: z.coerce.number().int().min(1).max(100).optional(),
});

const assignBatchesSchema = z.object({
  batchIds: z.array(z.string().uuid()).min(1, 'At least one batch id is required'),
});

const assignSubjectsSchema = z.object({
  subjectIds: z.array(z.string().uuid()).min(1, 'At least one subject id is required'),
});

module.exports = {
  createTeacherSchema,
  updateTeacherSchema,
  listTeachersQuerySchema,
  assignBatchesSchema,
  assignSubjectsSchema,
};
