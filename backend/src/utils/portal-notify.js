const { prisma } = require('../config/prisma');
const { notifySafely } = require('../services/notification.service');

// Looks up the student's own User (if login exists) and every linked
// parent's User (if login exists) and fires a notification to each.
// Silently skips anyone without a user account - there's no
// account to notify, which is not an error condition here.
async function notifyStudentAndParents(instituteId, studentId, data) {
  try {
    const student = await prisma.student.findUnique({
      where: { id: studentId },
      select: { email: true },
    });

    if (student && student.email) {
      const user = await prisma.user.findFirst({
        where: { instituteId: instituteId, email: student.email, role: 'STUDENT' },
        select: { id: true },
      });
      if (user) {
        await notifySafely(instituteId, user.id, data);
      }
    }

    const links = await prisma.studentParent.findMany({
      where: { studentId: studentId },
      include: { parent: { select: { email: true } } },
    });

    for (let i = 0; i < links.length; i++) {
      const parent = links[i].parent;
      if (parent && parent.email) {
        const parentUser = await prisma.user.findFirst({
          where: { instituteId: instituteId, email: parent.email, role: 'PARENT' },
          select: { id: true },
        });
        if (parentUser) {
          await notifySafely(instituteId, parentUser.id, data);
        }
      }
    }
  } catch (err) {
    console.error('[portal-notify] Failed to notify student and parents', err);
  }
}

async function notifyParentsOnly(instituteId, studentId, data) {
  try {
    const links = await prisma.studentParent.findMany({
      where: { studentId: studentId },
      include: { parent: { select: { email: true } } },
    });

    for (let i = 0; i < links.length; i++) {
      const parent = links[i].parent;
      if (parent && parent.email) {
        const parentUser = await prisma.user.findFirst({
          where: { instituteId: instituteId, email: parent.email, role: 'PARENT' },
          select: { id: true },
        });
        if (parentUser) {
          await notifySafely(instituteId, parentUser.id, data);
        }
      }
    }
  } catch (err) {
    console.error('[portal-notify] Failed to notify parents', err);
  }
}

module.exports = { notifyStudentAndParents, notifyParentsOnly };
