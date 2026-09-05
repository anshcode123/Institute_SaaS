const { z } = require('zod');
const { TEST_STATUS } = require('../constants/roles');

const dateOnlyString = z
  .string()
  .refine((v) => !Number.isNaN(Date.parse(v)), 'Must be a valid date')
  .transform((v) => new Date(v));

const testSubjectInputSchema = z.object({
  subjectId: z.string().uuid('Invalid subject id'),
  maxMarks: z.coerce.number().int().positive('Max marks must be a positive integer'),
  passingMarks: z.coerce.number().int().min(0, 'Passing marks cannot be negative'),
});

const createTestSchema = z
  .object({
    batchId: z.string().uuid('Invalid batch id'),
    name: z.string().min(1, 'Test name is required'),
    description: z.string().optional(),
    testDate: dateOnlyString,
    durationMinutes: z.coerce.number().int().positive().optional(),
    passingMarks: z.coerce.number().int().min(0, 'Passing marks cannot be negative'),
    subjects: z.array(testSubjectInputSchema).min(1, 'At least one subject is required'),
  })
  .refine(
    (data) => new Set(data.subjects.map((s) => s.subjectId)).size === data.subjects.length,
    { message: 'Duplicate subjects are not allowed on the same test', path: ['subjects'] },
  )
  .refine((data) => data.subjects.every((s) => s.passingMarks <= s.maxMarks), {
    message: 'A subject passing marks cannot exceed its max marks',
    path: ['subjects'],
  })
  .refine(
    (data) => data.passingMarks <= data.subjects.reduce((sum, s) => sum + s.maxMarks, 0),
    {
      message: 'Overall passing marks cannot exceed the total of all subjects max marks',
      path: ['passingMarks'],
    },
  );

const updateTestSchema = z.object({
  name: z.string().min(1).optional(),
  description: z.string().optional(),
  testDate: dateOnlyString.optional(),
  durationMinutes: z.coerce.number().int().positive().optional(),
  status: z
    .enum([TEST_STATUS.DRAFT, TEST_STATUS.SCHEDULED, TEST_STATUS.COMPLETED, TEST_STATUS.CANCELLED])
    .optional(),
});

const addTestSubjectSchema = testSubjectInputSchema;

const updateTestSubjectSchema = z.object({
  maxMarks: z.coerce.number().int().positive().optional(),
  passingMarks: z.coerce.number().int().min(0).optional(),
});

const listTestsQuerySchema = z.object({
  batchId: z.string().uuid().optional(),
  status: z
    .enum([
      TEST_STATUS.DRAFT,
      TEST_STATUS.SCHEDULED,
      TEST_STATUS.COMPLETED,
      TEST_STATUS.PUBLISHED,
      TEST_STATUS.CANCELLED,
    ])
    .optional(),
  page: z.coerce.number().int().min(1).optional(),
  limit: z.coerce.number().int().min(1).max(100).optional(),
});

module.exports = {
  dateOnlyString,
  createTestSchema,
  updateTestSchema,
  addTestSubjectSchema,
  updateTestSubjectSchema,
  listTestsQuerySchema,
};
