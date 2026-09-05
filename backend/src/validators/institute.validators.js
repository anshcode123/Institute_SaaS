const { z } = require('zod');
const { INSTITUTE_STATUS } = require('../constants/roles');

const createInstituteSchema = z.object({
  name: z.string().min(2, 'Institute name is required'),
  email: z.string().email('Valid institute email is required'),
  phone: z.string().optional(),
  address: z.string().optional(),
  adminName: z.string().min(2, 'Institute admin name is required'),
});

const updateInstituteStatusSchema = z.object({
  status: z.enum([INSTITUTE_STATUS.ACTIVE, INSTITUTE_STATUS.SUSPENDED]),
});

module.exports = { createInstituteSchema, updateInstituteStatusSchema };
