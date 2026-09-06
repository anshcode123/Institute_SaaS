const { z } = require('zod');
const { decimalString, dateOnlyString } = require('./fee-structure.validators');
const { FEE_STATUS } = require('../constants/roles');

const assignFeeSchema = z
  .object({
    studentId: z.string().uuid('Invalid student id'),
    feeStructureId: z.string().uuid('Invalid fee structure id'),
    feeStartDate: dateOnlyString,
    monthlyFeeGroupId: z.string().uuid('Invalid monthly fee group id').optional(),
    discountAmount: decimalString.optional(),
    discountPercentage: z.coerce.number().min(0).max(100).optional(),
  })
  .refine((data) => !(data.discountAmount !== undefined && data.discountPercentage !== undefined), {
    message: 'Provide either discountAmount or discountPercentage, not both',
    path: ['discountAmount'],
  });

const listStudentFeesQuerySchema = z.object({
  studentId: z.string().uuid().optional(),
  status: z
    .enum([
      FEE_STATUS.PENDING,
      FEE_STATUS.PARTIALLY_PAID,
      FEE_STATUS.PAID,
      FEE_STATUS.OVERDUE,
      FEE_STATUS.CANCELLED,
    ])
    .optional(),
  page: z.coerce.number().int().min(1).optional(),
  limit: z.coerce.number().int().min(1).max(100).optional(),
});

module.exports = { assignFeeSchema, listStudentFeesQuerySchema };
