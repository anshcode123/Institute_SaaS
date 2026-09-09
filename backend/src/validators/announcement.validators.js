const { z } = require('zod');
const { ANNOUNCEMENT_AUDIENCE, ANNOUNCEMENT_STATUS } = require('../constants/roles');

const audienceEnum = z.enum([
  ANNOUNCEMENT_AUDIENCE.ALL,
  ANNOUNCEMENT_AUDIENCE.TEACHERS,
  ANNOUNCEMENT_AUDIENCE.STUDENTS,
  ANNOUNCEMENT_AUDIENCE.PARENTS,
  ANNOUNCEMENT_AUDIENCE.BATCH,
]);

const createAnnouncementSchema = z
  .object({
    title: z.string().min(1, 'Title is required'),
    message: z.string().min(1, 'Message is required'),
    audience: audienceEnum.default(ANNOUNCEMENT_AUDIENCE.ALL),
    batchId: z.string().uuid('Invalid batch id').optional(),
    expiresAt: z
      .string()
      .refine(function (v) { return !isNaN(Date.parse(v)); }, 'Must be a valid date')
      .transform(function (v) { return new Date(v); })
      .optional(),
  })
  .refine(
    function (data) { return data.audience !== ANNOUNCEMENT_AUDIENCE.BATCH || !!data.batchId; },
    { message: 'batchId is required when audience is BATCH', path: ['batchId'] },
  );

const updateAnnouncementSchema = z.object({
  title: z.string().min(1).optional(),
  message: z.string().min(1).optional(),
  status: z
    .enum([ANNOUNCEMENT_STATUS.DRAFT, ANNOUNCEMENT_STATUS.PUBLISHED, ANNOUNCEMENT_STATUS.ARCHIVED])
    .optional(),
  expiresAt: z
    .string()
    .refine(function (v) { return !isNaN(Date.parse(v)); }, 'Must be a valid date')
    .transform(function (v) { return new Date(v); })
    .optional(),
});

const listAnnouncementsQuerySchema = z.object({
  status: z
    .enum([ANNOUNCEMENT_STATUS.DRAFT, ANNOUNCEMENT_STATUS.PUBLISHED, ANNOUNCEMENT_STATUS.ARCHIVED])
    .optional(),
  page: z.coerce.number().int().min(1).optional(),
  limit: z.coerce.number().int().min(1).max(100).optional(),
});

module.exports = { createAnnouncementSchema, updateAnnouncementSchema, listAnnouncementsQuerySchema };
