const { prisma } = require('../config/prisma');
const { findOwnedOrThrow } = require('../utils/tenant');
const { ConflictError } = require('../utils/app-error');
const { RECORD_STATUS } = require('../constants/roles');
const { generateQrToken } = require('../utils/qr-token');

// Retry a small number of times on the astronomically unlikely chance of
// a qrCode collision (24 random bytes), rather than looping forever.
async function createStudentWithUniqueQrCode(data, attemptsLeft = 3) {
  try {
    return await prisma.student.create({ data: { ...data, qrCode: generateQrToken() } });
  } catch (err) {
    if (err.code === 'P2002' && err.meta?.target?.includes('qrCode') && attemptsLeft > 0) {
      return createStudentWithUniqueQrCode(data, attemptsLeft - 1);
    }
    throw err;
  }
}

async function createStudent(instituteId, data) {
  const { batchId, ...rest } = data;

  if (batchId) {
    // Batch must belong to the same institute - never trust a client-
    // supplied batchId without checking tenant ownership first.
    await findOwnedOrThrow(prisma.batch, batchId, instituteId, 'Batch not found');
  }

  try {
    return await createStudentWithUniqueQrCode({ ...rest, instituteId, batchId: batchId ?? null });
  } catch (err) {
    if (err.code === 'P2002') {
      throw new ConflictError('A student with that student code already exists');
    }
    throw err;
  }
}

async function listStudents(instituteId, query) {
  const { q, status, batchId, page = 1, limit = 20 } = query;

  const where = {
    instituteId,
    ...(status ? { status } : {}),
    ...(batchId ? { batchId } : {}),
    ...(q
      ? {
        OR: [
          { firstName: { contains: q, mode: 'insensitive' } },
          { lastName: { contains: q, mode: 'insensitive' } },
          { studentCode: { contains: q, mode: 'insensitive' } },
          { email: { contains: q, mode: 'insensitive' } },
        ],
      }
      : {}),
  };

  const [items, total] = await Promise.all([
    prisma.student.findMany({
      where,
      include: { batch: true, parents: { include: { parent: true } } },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.student.count({ where }),
  ]);

  return { items, total, page, limit };
}

const { ROLES } = require('../constants/roles');
const { ValidationError } = require('../utils/app-error');
const { hashPassword, generateTempPassword } = require('../utils/password');

async function getStudentById(instituteId, id) {
  const student = await findOwnedOrThrow(prisma.student, id, instituteId, 'Student not found', {
    include: { batch: true, parents: { include: { parent: true } } },
  });

  let hasLogin = false;
  let loginEmail = null;
  if (student.email) {
    const user = await prisma.user.findFirst({
      where: { instituteId, email: student.email, role: ROLES.STUDENT },
      select: { id: true, email: true },
    });
    if (user) {
      hasLogin = true;
      loginEmail = user.email;
    }
  }

  return { ...student, hasLogin, loginEmail };
}

async function createStudentLogin(instituteId, studentId, data = {}) {
  const student = await findOwnedOrThrow(prisma.student, studentId, instituteId, 'Student not found');

  const loginId = (data.loginId && data.loginId.trim()) || student.email || `${student.studentCode.toLowerCase()}@student.local`;
  const plainPassword = (data.password && data.password.trim()) || generateTempPassword();
  const passwordHash = await hashPassword(plainPassword);

  // Check if student already has a login
  if (student.email) {
    const existing = await prisma.user.findFirst({
      where: { instituteId, email: student.email, role: ROLES.STUDENT },
    });
    if (existing) {
      throw new ConflictError('This student already has a login account');
    }
  }

  try {
    const user = await prisma.$transaction(async (tx) => {
      const created = await tx.user.create({
        data: {
          instituteId,
          name: `${student.firstName} ${student.lastName}`,
          email: loginId,
          passwordHash,
          role: ROLES.STUDENT,
        },
      });
      // Ensure student's email matches the login email
      if (student.email !== loginId) {
        await tx.student.update({ where: { id: studentId }, data: { email: loginId } });
      }
      return created;
    });

    return { userId: user.id, email: user.email, initialPassword: plainPassword };
  } catch (err) {
    if (err.code === 'P2002') {
      throw new ConflictError('A login with that email/ID already exists');
    }
    throw err;
  }
}

async function resetStudentPassword(instituteId, studentId, data = {}) {
  const student = await findOwnedOrThrow(prisma.student, studentId, instituteId, 'Student not found');

  if (!student.email) {
    throw new ValidationError('Student does not have an email/login account');
  }

  const user = await prisma.user.findFirst({
    where: { instituteId, email: student.email, role: ROLES.STUDENT },
  });

  if (!user) {
    throw new ValidationError('No login account found for this student');
  }

  const newPlainPassword = (data.newPassword && data.newPassword.trim()) || generateTempPassword();
  const passwordHash = await hashPassword(newPlainPassword);

  await prisma.user.update({
    where: { id: user.id },
    data: { passwordHash },
  });

  return { email: user.email, newPassword: newPlainPassword };
}

async function updateStudent(instituteId, id, data) {
  await findOwnedOrThrow(prisma.student, id, instituteId, 'Student not found');

  const { batchId, ...rest } = data;
  if (batchId) {
    await findOwnedOrThrow(prisma.batch, batchId, instituteId, 'Batch not found');
  }

  try {
    return await prisma.student.update({
      where: { id },
      data: { ...rest, ...(batchId !== undefined ? { batchId } : {}) },
    });
  } catch (err) {
    if (err.code === 'P2002') {
      throw new ConflictError('A student with that student code already exists');
    }
    throw err;
  }
}

// Soft-deactivate rather than physically delete, per the business rules.
async function deactivateStudent(instituteId, id) {
  await findOwnedOrThrow(prisma.student, id, instituteId, 'Student not found');
  return prisma.student.update({
    where: { id },
    data: { status: RECORD_STATUS.INACTIVE },
  });
}

async function linkParent(instituteId, studentId, { parentId, relationship }) {
  await findOwnedOrThrow(prisma.student, studentId, instituteId, 'Student not found');
  // Both sides must belong to the same institute - a parent from another
  // tenant must never be linkable here.
  await findOwnedOrThrow(prisma.parent, parentId, instituteId, 'Parent not found');

  try {
    return await prisma.studentParent.create({
      data: { studentId, parentId, relationship: relationship ?? undefined },
      include: { parent: true },
    });
  } catch (err) {
    if (err.code === 'P2002') {
      throw new ConflictError('This parent is already linked to this student');
    }
    throw err;
  }
}

async function unlinkParent(instituteId, studentId, parentId) {
  await findOwnedOrThrow(prisma.student, studentId, instituteId, 'Student not found');
  await findOwnedOrThrow(prisma.parent, parentId, instituteId, 'Parent not found');

  await prisma.studentParent.deleteMany({ where: { studentId, parentId } });
}

async function assignBatch(instituteId, studentId, batchId) {
  await findOwnedOrThrow(prisma.student, studentId, instituteId, 'Student not found');
  await findOwnedOrThrow(prisma.batch, batchId, instituteId, 'Batch not found');

  return prisma.student.update({ where: { id: studentId }, data: { batchId } });
}

module.exports = {
  createStudent,
  listStudents,
  getStudentById,
  updateStudent,
  deactivateStudent,
  linkParent,
  unlinkParent,
  assignBatch,
  createStudentLogin,
  resetStudentPassword,
};
