const { z } = require('zod');
const { GENDER, RECORD_STATUS, PARENT_RELATIONSHIP } = require('../constants/roles');

const dateString = z
  .string()
  .refine((v) => !Number.isNaN(Date.parse(v)), 'Must be a valid date')
  .transform((v) => new Date(v));

const createStudentSchema = z.object({
  studentCode: z.string().min(1, 'Student code is required'),
  firstName: z.string().min(1, 'First name is required'),
  lastName: z.string().min(1, 'Last name is required'),
  profilePhoto: z.string().url().optional(),
  dateOfBirth: dateString.optional(),
  gender: z.enum([GENDER.MALE, GENDER.FEMALE, GENDER.OTHER]).optional(),
  phone: z.string().optional(),
  email: z.string().email('Invalid email').optional(),
  address: z.string().optional(),
  admissionDate: dateString.optional(),
  batchId: z.string().uuid('Invalid batch id').optional(),
});

const updateStudentSchema = createStudentSchema.partial().extend({
  status: z.enum([RECORD_STATUS.ACTIVE, RECORD_STATUS.INACTIVE]).optional(),
});

const listStudentsQuerySchema = z.object({
  q: z.string().optional(),
  status: z.enum([RECORD_STATUS.ACTIVE, RECORD_STATUS.INACTIVE]).optional(),
  batchId: z.string().uuid().optional(),
  page: z.coerce.number().int().min(1).optional(),
  limit: z.coerce.number().int().min(1).max(100).optional(),
});

const linkParentSchema = z.object({
  parentId: z.string().uuid('Invalid parent id'),
  relationship: z
    .enum([
      PARENT_RELATIONSHIP.FATHER,
      PARENT_RELATIONSHIP.MOTHER,
      PARENT_RELATIONSHIP.GUARDIAN,
      PARENT_RELATIONSHIP.OTHER,
    ])
    .optional(),
});

const assignBatchSchema = z.object({
  batchId: z.string().uuid('Invalid batch id'),
});

module.exports = {
  createStudentSchema,
  updateStudentSchema,
  listStudentsQuerySchema,
  linkParentSchema,
  assignBatchSchema,
};
