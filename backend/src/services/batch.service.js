const { prisma } = require('../config/prisma');
const { findOwnedOrThrow } = require('../utils/tenant');
const { RECORD_STATUS, ROLES } = require('../constants/roles');
const { ValidationError } = require('../utils/app-error');
const { getTeacherForUser, assertCanAccessBatch } = require('../utils/teacher-access');

async function createBatch(instituteId, data) {
  const { courseId, ...rest } = data;
  if (courseId) {
    await findOwnedOrThrow(prisma.course, courseId, instituteId, 'Course not found');
  }
  return prisma.batch.create({ data: { ...rest, courseId: courseId ?? null, instituteId } });
}

// `auth` is optional and only used to scope results for a TEACHER caller
// (their own assigned batches only) - Institute Admin sees everything, as
// before. Never accept a teacher/instituteId filter from the client for
// this purpose; it always comes from the verified auth context.
async function listBatches(instituteId, query, auth) {
  const { q, status, page = 1, limit = 20 } = query;

  let teacherFilter = {};
  if (auth?.role === ROLES.TEACHER) {
    const teacher = await getTeacherForUser(instituteId, auth.userId);
    // No linked teacher profile - a teacher with no profile sees nothing,
    // rather than erroring the whole list out.
    teacherFilter = { teachers: { some: { teacherId: teacher?.id ?? '__none__' } } };
  }

  const where = {
    instituteId,
    ...teacherFilter,
    ...(status ? { status } : {}),
    ...(q ? { name: { contains: q, mode: 'insensitive' } } : {}),
  };

  const [items, total] = await Promise.all([
    prisma.batch.findMany({
      where,
      include: {
        course: true,
        teachers: { include: { teacher: true } },
        _count: { select: { students: true } },
      },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.batch.count({ where }),
  ]);

  return { items, total, page, limit };
}

async function getBatchById(instituteId, id, auth) {
  const batch = await findOwnedOrThrow(prisma.batch, id, instituteId, 'Batch not found', {
    include: {
      course: true,
      teachers: { include: { teacher: true } },
      students: true,
    },
  });

  if (auth) {
    // Institute Admin can view any batch in their institute; a Teacher
    // can only view batches they're actually assigned to.
    await assertCanAccessBatch(instituteId, auth, id);
  }

  return batch;
}

async function updateBatch(instituteId, id, data) {
  await findOwnedOrThrow(prisma.batch, id, instituteId, 'Batch not found');

  const { courseId, ...rest } = data;
  if (courseId) {
    await findOwnedOrThrow(prisma.course, courseId, instituteId, 'Course not found');
  }

  return prisma.batch.update({
    where: { id },
    data: { ...rest, ...(courseId !== undefined ? { courseId } : {}) },
  });
}

async function deactivateBatch(instituteId, id) {
  await findOwnedOrThrow(prisma.batch, id, instituteId, 'Batch not found');
  return prisma.batch.update({ where: { id }, data: { status: RECORD_STATUS.INACTIVE } });
}

async function addStudents(instituteId, batchId, studentIds) {
  await findOwnedOrThrow(prisma.batch, batchId, instituteId, 'Batch not found');

  const owned = await prisma.student.findMany({
    where: { id: { in: studentIds }, instituteId },
    select: { id: true },
  });
  if (owned.length !== studentIds.length) {
    throw new ValidationError('One or more student ids are invalid for this institute');
  }

  await prisma.student.updateMany({
    where: { id: { in: studentIds }, instituteId },
    data: { batchId },
  });

  return getBatchById(instituteId, batchId);
}

async function removeStudents(instituteId, batchId, studentIds) {
  await findOwnedOrThrow(prisma.batch, batchId, instituteId, 'Batch not found');

  await prisma.student.updateMany({
    where: { id: { in: studentIds }, instituteId, batchId },
    data: { batchId: null },
  });

  return getBatchById(instituteId, batchId);
}

async function assignTeachers(instituteId, batchId, teacherIds) {
  await findOwnedOrThrow(prisma.batch, batchId, instituteId, 'Batch not found');

  const owned = await prisma.teacher.findMany({
    where: { id: { in: teacherIds }, instituteId },
    select: { id: true },
  });
  if (owned.length !== teacherIds.length) {
    throw new ValidationError('One or more teacher ids are invalid for this institute');
  }

  await prisma.$transaction(
    teacherIds.map((teacherId) =>
      prisma.teacherBatch.upsert({
        where: { teacherId_batchId: { teacherId, batchId } },
        create: { teacherId, batchId },
        update: {},
      }),
    ),
  );

  return getBatchById(instituteId, batchId);
}

module.exports = {
  createBatch,
  listBatches,
  getBatchById,
  updateBatch,
  deactivateBatch,
  addStudents,
  removeStudents,
  assignTeachers,
};
