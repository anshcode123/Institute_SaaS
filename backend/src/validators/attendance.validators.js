const { z } = require('zod');
const { ATTENDANCE_STATUS } = require('../constants/roles');

const statusEnum = z.enum([
  ATTENDANCE_STATUS.PRESENT,
  ATTENDANCE_STATUS.ABSENT,
  ATTENDANCE_STATUS.LATE,
  ATTENDANCE_STATUS.EXCUSED,
]);

const dateOnlyString = z
  .string()
  .refine((v) => !Number.isNaN(Date.parse(v)), 'Must be a valid date')
  .transform((v) => new Date(v));

const scanAttendanceSchema = z.object({
  qrToken: z.string().min(1, 'QR token is required'),
  batchId: z.string().uuid('Invalid batch id'),
});

const manualAttendanceSchema = z.object({
  batchId: z.string().uuid('Invalid batch id'),
  date: dateOnlyString.optional(),
  entries: z
    .array(
      z.object({
        studentId: z.string().uuid('Invalid student id'),
        status: statusEnum,
      }),
    )
    .min(1, 'At least one attendance entry is required'),
});

const listAttendanceQuerySchema = z.object({
  batchId: z.string().uuid().optional(),
  studentId: z.string().uuid().optional(),
  status: statusEnum.optional(),
  date: dateOnlyString.optional(),
  page: z.coerce.number().int().min(1).optional(),
  limit: z.coerce.number().int().min(1).max(100).optional(),
});

const batchSummaryQuerySchema = z.object({
  date: dateOnlyString.optional(),
});

module.exports = {
  scanAttendanceSchema,
  manualAttendanceSchema,
  listAttendanceQuerySchema,
  batchSummaryQuerySchema,
};
