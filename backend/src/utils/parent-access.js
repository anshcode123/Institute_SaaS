const { prisma } = require('../config/prisma');
const { ForbiddenError } = require('./app-error');

async function getParentForUser(instituteId, userId) {
  return prisma.parent.findFirst({ where: { instituteId: instituteId, userId: userId } });
}

// THE critical check for every parent-portal endpoint: a parent must
// never see another parent's child by changing a studentId in the URL.
// This verifies an actual StudentParent row links this parent to this
// specific student in this institute - never trust that a client-
// supplied studentId belongs to the caller.
async function assertParentOwnsStudent(instituteId, auth, studentId) {
  const parent = await getParentForUser(instituteId, auth.userId);
  if (!parent) {
    throw new ForbiddenError('No parent profile is linked to this account');
  }

  const link = await prisma.studentParent.findUnique({
    where: { studentId_parentId: { studentId: studentId, parentId: parent.id } },
  });
  if (!link) {
    throw new ForbiddenError('This student is not linked to your account');
  }

  return parent;
}

module.exports = { getParentForUser: getParentForUser, assertParentOwnsStudent: assertParentOwnsStudent };
