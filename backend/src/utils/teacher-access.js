const { prisma } = require('../config/prisma');
const { ForbiddenError } = require('./app-error');
const { ROLES } = require('../constants/roles');

// Resolves the Teacher row for the authenticated user (a User can be
// linked to at most one Teacher via Teacher.userId - see schema).
async function getTeacherForUser(instituteId, userId) {
  return prisma.teacher.findFirst({ where: { instituteId, userId } });
}

// Institute Admins can act on any batch in their institute. Teachers can
// only act on batches they're actually assigned to via TeacherBatch -
// this is checked here, server-side, never inferred from anything the
// client sends.
async function assertCanAccessBatch(instituteId, auth, batchId) {
  if (auth.role === ROLES.INSTITUTE_ADMIN) return;

  if (auth.role === ROLES.TEACHER) {
    const teacher = await getTeacherForUser(instituteId, auth.userId);
    if (!teacher) {
      throw new ForbiddenError('No teacher profile is linked to this account');
    }
    const link = await prisma.teacherBatch.findUnique({
      where: { teacherId_batchId: { teacherId: teacher.id, batchId } },
    });
    if (!link) {
      throw new ForbiddenError('You are not assigned to this batch');
    }
    return;
  }

  throw new ForbiddenError('You do not have permission to perform this action');
}

module.exports = { getTeacherForUser, assertCanAccessBatch };
