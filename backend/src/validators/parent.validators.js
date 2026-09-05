const { z } = require('zod');
const { RECORD_STATUS } = require('../constants/roles');

const createParentSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  phone: z.string().optional(),
  email: z.string().email('Invalid email').optional(),
  address: z.string().optional(),
});

const updateParentSchema = createParentSchema.partial().extend({
  status: z.enum([RECORD_STATUS.ACTIVE, RECORD_STATUS.INACTIVE]).optional(),
});

const listParentsQuerySchema = z.object({
  q: z.string().optional(),
  status: z.enum([RECORD_STATUS.ACTIVE, RECORD_STATUS.INACTIVE]).optional(),
  page: z.coerce.number().int().min(1).optional(),
  limit: z.coerce.number().int().min(1).max(100).optional(),
});

module.exports = { createParentSchema, updateParentSchema, listParentsQuerySchema };
