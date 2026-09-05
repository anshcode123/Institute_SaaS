const { prisma } = require('../config/prisma');
const { findOwnedOrThrow } = require('../utils/tenant');
const { RECORD_STATUS, ROLES } = require('../constants/roles');
const { ValidationError, ConflictError } = require('../utils/app-error');
const { hashPassword, generateTempPassword } = require('../utils/password');

async function createTeacher(instituteId, data) {
  return prisma.teacher.create({ data: { ...data, instituteId } });
}

async function listTeachers(instituteId, query) {
  const { q, status, page = 1, limit = 20 } = query;

  const where = {
    instituteId,
    ...(status ? { status } : {}),
    ...(q
      ? {
          OR: [
            { name: { contains: q, mode: 'insensitive' } },
            { email: { contains: q, mode: 'insensitive' } },
            { phone: { contains: q, mode: 'insensitive' } },
          ],
        }
      : {}),
  };

  const [items, total] = await Promise.all([
    prisma.teacher.findMany({
      where,
      include: { batches: { include: { batch: true } }, subjects: { include: { subject: true } } },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.teacher.count({ where }),
  ]);

  return { items, total, page, limit };
}

async function getTeacherById(instituteId, id) {
  return findOwnedOrThrow(prisma.teacher, id, instituteId, 'Teacher not found', {
    include: { batches: { include: { batch: true } }, subjects: { include: { subject: true } } },
  });
}

async function updateTeacher(instituteId, id, data) {
  await findOwnedOrThrow(prisma.teacher, id, instituteId, 'Teacher not found');
  return prisma.teacher.update({ where: { id }, data });
}

async function deactivateTeacher(instituteId, id) {
  await findOwnedOrThrow(prisma.teacher, id, instituteId, 'Teacher not found');
  return prisma.teacher.update({ where: { id }, data: { status: RECORD_STATUS.INACTIVE } });
}

async function assignBatches(instituteId, teacherId, batchIds) {
  await findOwnedOrThrow(prisma.teacher, teacherId, instituteId, 'Teacher not found');

  // Every batchId must belong to this institute - verify the full set,
  // not just that *a* batch with that id exists somewhere.
  const owned = await prisma.batch.findMany({
    where: { id: { in: batchIds }, instituteId },
    select: { id: true },
  });
  if (owned.length !== batchIds.length) {
    throw new ValidationError('One or more batch ids are invalid for this institute');
  }

  await prisma.$transaction(
    batchIds.map((batchId) =>
      prisma.teacherBatch.upsert({
        where: { teacherId_batchId: { teacherId, batchId } },
        create: { teacherId, batchId },
        update: {},
      }),
    ),
  );

  return getTeacherById(instituteId, teacherId);
}

async function assignSubjects(instituteId, teacherId, subjectIds) {
  await findOwnedOrThrow(prisma.teacher, teacherId, instituteId, 'Teacher not found');

  const owned = await prisma.subject.findMany({
    where: { id: { in: subjectIds }, instituteId },
    select: { id: true },
  });
  if (owned.length !== subjectIds.length) {
    throw new ValidationError('One or more subject ids are invalid for this institute');
  }

  await prisma.$transaction(
    subjectIds.map((subjectId) =>
      prisma.teacherSubject.upsert({
        where: { teacherId_subjectId: { teacherId, subjectId } },
        create: { teacherId, subjectId },
        update: {},
      }),
    ),
  );

  return getTeacherById(instituteId, teacherId);
}

// Creates the login account for an existing teacher, mirroring how
// Institute Admin accounts are created in Phase 2: generate a temp
// password, hash it, return the plaintext once, store only the hash.
// The teacher must already have an email on file - reuses it as the
// login identifier rather than asking for a new one.
async function createTeacherLogin(instituteId, teacherId) {
  const teacher = await findOwnedOrThrow(prisma.teacher, teacherId, instituteId, 'Teacher not found');

  if (teacher.userId) {
    throw new ConflictError('This teacher already has a login account');
  }
  if (!teacher.email) {
    throw new ValidationError('Teacher must have an email on file before creating a login');
  }

  const initialPassword = generateTempPassword();
  const passwordHash = await hashPassword(initialPassword);

  try {
    const user = await prisma.$transaction(async (tx) => {
      const created = await tx.user.create({
        data: {
          instituteId,
          name: teacher.name,
          email: teacher.email,
          passwordHash,
          role: ROLES.TEACHER,
        },
      });
      await tx.teacher.update({ where: { id: teacherId }, data: { userId: created.id } });
      return created;
    });

    return { userId: user.id, email: user.email, initialPassword };
  } catch (err) {
    if (err.code === 'P2002') {
      throw new ConflictError('A login with that email already exists');
    }
    throw err;
  }
}

module.exports = {
  createTeacher,
  listTeachers,
  getTeacherById,
  updateTeacher,
  deactivateTeacher,
  assignBatches,
  assignSubjects,
  createTeacherLogin,
};
