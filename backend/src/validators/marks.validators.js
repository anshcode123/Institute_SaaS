const { z } = require('zod');

const markEntrySchema = z.object({
  studentId: z.string().uuid('Invalid student id'),
  obtainedMarks: z.coerce.number().int().min(0, 'Marks cannot be negative'),
});

const saveMarksSchema = z.object({
  subjectId: z.string().uuid('Invalid subject id'),
  entries: z.array(markEntrySchema).min(1, 'At least one mark entry is required'),
});

const listMarksQuerySchema = z.object({
  subjectId: z.string().uuid().optional(),
});

module.exports = { saveMarksSchema, listMarksQuerySchema };
