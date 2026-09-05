const { z } = require('zod');
const { decimalString } = require('./fee-structure.validators');
const { PAYMENT_METHOD } = require('../constants/roles');

const recordPaymentSchema = z.object({
  studentId: z.string().uuid('Invalid student id'),
  studentFeeId: z.string().uuid('Invalid student fee id'),
  installmentId: z.string().uuid('Invalid installment id'),
  amount: decimalString.refine((v) => Number(v) > 0, 'Payment amount must be greater than zero'),
  paymentMethod: z.enum([
    PAYMENT_METHOD.CASH,
    PAYMENT_METHOD.UPI,
    PAYMENT_METHOD.BANK_TRANSFER,
    PAYMENT_METHOD.CARD,
    PAYMENT_METHOD.OTHER,
  ]),
  transactionReference: z.string().optional(),
  paymentDate: z
    .string()
    .refine((v) => !Number.isNaN(Date.parse(v)), 'Must be a valid date')
    .transform((v) => new Date(v))
    .optional(),
  notes: z.string().optional(),
});

const listPaymentsQuerySchema = z.object({
  studentId: z.string().uuid().optional(),
  studentFeeId: z.string().uuid().optional(),
  page: z.coerce.number().int().min(1).optional(),
  limit: z.coerce.number().int().min(1).max(100).optional(),
});

module.exports = { recordPaymentSchema, listPaymentsQuerySchema };
