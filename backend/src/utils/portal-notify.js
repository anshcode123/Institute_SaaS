const { prisma } = require('../config/prisma');
const { notifySafely } = require('../services/notification.service');

// Looks up the student's own User (if portal-enabled) and every linked
// parent's User (if portal-enabled) and fires a notification to each.
// Silently skips anyone without portal access enabled - there's no
// account to notify, which is not an error condition here.
async function notifyStudentAndParents(instituteId, studentId, data) {
  const student = await prisma.student.findUnique({
    where: { id: studentId },
    select: { userId: true, portalEnabled: true },
  });

  if (student && student.portalEnabled && student.userId) {
    await notifySafely(instituteId, student.userId, data);
  }

  const links = await prisma.studentParent.findMany({
    where: { studentId: studentId },
    include: { parent: { select: { userId: true, portalEnabled: true } } },
  });

  for (let i = 0; i < links.length; i++) {
    const link = links[i];
    if (link.parent.portalEnabled && link.parent.userId) {
      await notifySafely(instituteId, link.parent.userId, data);
    }
  }
}

module.exports = { notifyStudentAndParents };
