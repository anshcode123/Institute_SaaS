const { z } = require('zod');
const { FEE_STRUCTURE_STATUS } = require('../constants/roles');

const dateOnlyString = z.string().refine((v) => !Number.isNaN(Date.parse(v)), 'Must be a valid date').transform((v) => new Date(v));
const decimalString = z.union([z.string(), z.number()]).refine((v) => !Number.isNaN(Number(v)) && Number(v) >= 0, 'Must be a non-negative amount').transform(String);
const positiveDecimal = decimalString.refine((v) => Number(v) > 0, 'Must be greater than zero');
const installmentTemplateSchema = z.object({ installmentNumber: z.coerce.number().int().min(1), amount: positiveDecimal, dueDate: dateOnlyString });

const monthlySubjectItemSchema = z.object({
  subjectId: z.string().optional(),
  subjectName: z.string().min(1).optional(),
  name: z.string().min(1).optional(),
  monthlyAmount: positiveDecimal,
}).refine(
  (item) => (item.subjectId && item.subjectId.trim().length > 0) ||
    (item.subjectName && item.subjectName.trim().length > 0) ||
    (item.name && item.name.trim().length > 0),
  'Subject name is required',
);

const monthlyGroupSchema = z.discriminatedUnion('pricingType', [
  z.object({
    name: z.string().min(1),
    applicableLevel: z.string().min(1),
    pricingType: z.literal('COMBINED'),
    combinedAmount: positiveDecimal,
    subjects: z.array(z.any()).max(0).optional(),
  }),
  z.object({
    name: z.string().min(1),
    applicableLevel: z.string().min(1),
    pricingType: z.literal('SUBJECT_WISE'),
    subjects: z.array(monthlySubjectItemSchema).min(1, 'Add at least one subject').refine(
      (items) => {
        const identifiers = items.map((item) =>
          (item.subjectName || item.name || item.subjectId || '').trim().toLowerCase(),
        );
        return new Set(identifiers).size === items.length;
      },
      'Duplicate subjects are not allowed',
    ),
  }),
]);

const common = { name: z.string().min(1, 'Fee structure name is required'), description: z.string().optional(), currency: z.string().min(1).optional(), batchId: z.string().uuid('Invalid batch id').optional() };
const monthlyFeeSchema = z.object({ ...common, feeType: z.literal('MONTHLY'), monthlyDueDay: z.coerce.number().int().min(1).max(31), lateFee: decimalString.optional(), gracePeriodDays: z.coerce.number().int().min(0).max(365).optional(), monthlyGroups: z.array(monthlyGroupSchema).min(1, 'Add at least one fee group') });
const courseFeeSchema = z.object({ ...common, feeType: z.literal('COURSE'), courseId: z.string().uuid('Invalid course id'), totalAmount: positiveDecimal, coursePaymentMode: z.enum(['FULL', 'EMI']), installments: z.array(installmentTemplateSchema).optional() }).superRefine((data, ctx) => {
  if (data.coursePaymentMode === 'FULL' && data.installments?.length) ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['installments'], message: 'Full payment does not use EMI installments' });
  if (data.coursePaymentMode === 'EMI') {
    if (!data.installments?.length) return ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['installments'], message: 'Add at least one EMI' });
    const sum = data.installments.reduce((total, item) => total + Number(item.amount), 0);
    if (Math.round(sum * 100) !== Math.round(Number(data.totalAmount) * 100)) ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['installments'], message: 'EMI amounts must sum to the final payable amount' });
  }
});

// courseFeeSchema has cross-field EMI validation (a ZodEffects wrapper),
// which Zod cannot place inside discriminatedUnion. Each branch still
// requires its literal feeType, so their request shapes stay exclusive.
const createFeeStructureSchema = z.union([monthlyFeeSchema, courseFeeSchema]);
const updateFeeStructureSchema = z.object({ name: z.string().min(1).optional(), description: z.string().optional(), status: z.enum([FEE_STRUCTURE_STATUS.ACTIVE, FEE_STRUCTURE_STATUS.INACTIVE]).optional() });
const listFeeStructuresQuerySchema = z.object({ status: z.enum([FEE_STRUCTURE_STATUS.ACTIVE, FEE_STRUCTURE_STATUS.INACTIVE]).optional(), batchId: z.string().uuid().optional(), page: z.coerce.number().int().min(1).optional(), limit: z.coerce.number().int().min(1).max(100).optional() });

module.exports = { decimalString, dateOnlyString, createFeeStructureSchema, updateFeeStructureSchema, listFeeStructuresQuerySchema };
