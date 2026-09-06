const { z } = require('zod');
const { Prisma } = require('@prisma/client');
const {
  FEE_STRUCTURE_STATUS,
  FEE_TYPE,
  COURSE_PAYMENT_MODE,
  normalizeFeeType,
  normalizeCoursePaymentMode,
} = require('../constants/roles');

const dateOnlyString = z
  .string()
  .refine((v) => !Number.isNaN(Date.parse(v)), 'Must be a valid date')
  .transform((v) => new Date(v));

const decimalString = z
  .union([z.string(), z.number()])
  .transform((v) => String(v).trim())
  .refine((v) => {
    try {
      const value = new Prisma.Decimal(v);
      return value.greaterThanOrEqualTo(0) && value.decimalPlaces() <= 2;
    } catch {
      return false;
    }
  }, 'Must be a non-negative amount with at most 2 decimal places');

const installmentTemplateSchema = z.object({
  installmentNumber: z.coerce.number().int().min(1),
  amount: decimalString,
  dueDate: dateOnlyString,
});

const feeTypeSchema = z.preprocess(
  (value) => (typeof value === 'string' ? normalizeFeeType(value) : value),
  z.enum([FEE_TYPE.MONTHLY_FEE, FEE_TYPE.COURSE_FEE]),
);

const coursePaymentModeSchema = z.preprocess(
  (value) => (typeof value === 'string' ? normalizeCoursePaymentMode(value) : value),
  z.enum([COURSE_PAYMENT_MODE.FULL, COURSE_PAYMENT_MODE.EMI]).optional(),
);

const createFeeStructureSchema = z
  .object({
    name: z.string().min(1, 'Fee structure name is required'),
    description: z.string().optional(),
    totalAmount: decimalString,
    currency: z.string().min(1).optional(),
    batchId: z.string().uuid('Invalid batch id').optional(),
    feeType: feeTypeSchema.default(FEE_TYPE.MONTHLY_FEE),
    coursePaymentMode: coursePaymentModeSchema,
    installments: z.array(installmentTemplateSchema).optional(),
  })
  .superRefine((data, ctx) => {
    const feeType = normalizeFeeType(data.feeType);
    const installments = data.installments ?? [];
    const numberSet = new Set();
    for (const item of installments) {
      if (numberSet.has(item.installmentNumber)) {
        ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'Installment numbers must be unique', path: ['installments'] });
        break;
      }
      numberSet.add(item.installmentNumber);
    }

    if (feeType === FEE_TYPE.COURSE_FEE) {
      if (!data.coursePaymentMode) {
        ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'coursePaymentMode is required for COURSE fees', path: ['coursePaymentMode'] });
      }
      if (installments.length === 0) {
        ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'At least one installment is required for COURSE fees', path: ['installments'] });
      }
      if (data.coursePaymentMode === COURSE_PAYMENT_MODE.FULL && installments.length !== 1) {
        ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'COURSE FULL fees require exactly one installment', path: ['installments'] });
      }
      if (data.coursePaymentMode === COURSE_PAYMENT_MODE.EMI && installments.length < 2) {
        ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'COURSE EMI fees require at least two installments', path: ['installments'] });
      }
      if (installments.length > 0) {
        const sum = installments.reduce(
          (acc, i) => acc.plus(new Prisma.Decimal(i.amount)),
          new Prisma.Decimal(0),
        );
        if (!sum.equals(new Prisma.Decimal(data.totalAmount))) {
          ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'Installment amounts must sum to the total amount', path: ['installments'] });
        }
      }
      return;
    }

    if (data.coursePaymentMode) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'coursePaymentMode is only valid for COURSE fees', path: ['coursePaymentMode'] });
    }
    if (installments.length > 0) {
      const sum = installments.reduce(
        (acc, i) => acc.plus(new Prisma.Decimal(i.amount)),
        new Prisma.Decimal(0),
      );
      if (!sum.equals(new Prisma.Decimal(data.totalAmount))) {
        ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'Installment amounts must sum to the total amount', path: ['installments'] });
      }
    }
  });

const updateFeeStructureSchema = z.object({
  name: z.string().min(1).optional(),
  description: z.string().optional(),
  status: z.enum([FEE_STRUCTURE_STATUS.ACTIVE, FEE_STRUCTURE_STATUS.INACTIVE]).optional(),
});

const listFeeStructuresQuerySchema = z.object({
  status: z.enum([FEE_STRUCTURE_STATUS.ACTIVE, FEE_STRUCTURE_STATUS.INACTIVE]).optional(),
  batchId: z.string().uuid().optional(),
  page: z.coerce.number().int().min(1).optional(),
  limit: z.coerce.number().int().min(1).max(100).optional(),
});

module.exports = {
  decimalString,
  dateOnlyString,
  createFeeStructureSchema,
  updateFeeStructureSchema,
  listFeeStructuresQuerySchema,
};
