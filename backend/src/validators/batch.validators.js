const { z } = require('zod');
const { RECORD_STATUS } = require('../constants/roles');

const dateString = z
  .string()
  .refine((v) => !Number.isNaN(Date.parse(v)), 'Must be a valid date')
  .transform((v) => new Date(v));

const createBatchSchema = z.object({
  name: z.string().min(1, 'Batch name is required'),
  description: z.string().optional(),
  startDate: dateString.optional(),
  endDate: dateString.optional(),
  courseId: z.string().uuid('Invalid course id').optional(),
});

const updateBatchSchema = createBatchSchema.partial().extend({
  status: z.enum([RECORD_STATUS.ACTIVE, RECORD_STATUS.INACTIVE]).optional(),
});

const listBatchesQuerySchema = z.object({
  q: z.string().optional(),
  status: z.enum([RECORD_STATUS.ACTIVE, RECORD_STATUS.INACTIVE]).optional(),
  page: z.coerce.number().int().min(1).optional(),
  limit: z.coerce.number().int().min(1).max(100).optional(),
});

const addStudentsSchema = z.object({
  studentIds: z.array(z.string().uuid()).min(1, 'At least one student id is required'),
});

const removeStudentsSchema = z.object({
  studentIds: z.array(z.string().uuid()).min(1, 'At least one student id is required'),
});

const assignTeachersSchema = z.object({
  teacherIds: z.array(z.string().uuid()).min(1, 'At least one teacher id is required'),
});

module.exports = {
  createBatchSchema,
  updateBatchSchema,
  listBatchesQuerySchema,
  addStudentsSchema,
  removeStudentsSchema,
  assignTeachersSchema,
};
