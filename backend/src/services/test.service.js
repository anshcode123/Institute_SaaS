const { prisma } = require('../config/prisma');
const { findOwnedOrThrow } = require('../utils/tenant');
const { assertCanAccessBatch, getTeacherForUser } = require('../utils/teacher-access');
const { ValidationError, ConflictError } = require('../utils/app-error');
const { TEST_STATUS, ROLES } = require('../constants/roles');

async function createTest(instituteId, actorUserId, data) {
  const { batchId, subjects, ...rest } = data;

  await findOwnedOrThrow(prisma.batch, batchId, instituteId, 'Batch not found');

  const owned = await prisma.subject.findMany({
    where: { id: { in: subjects.map((s) => s.subjectId) }, instituteId },
    select: { id: true },
  });
  if (owned.length !== subjects.length) {
    throw new ValidationError('One or more subjects are invalid for this institute');
  }

  const totalMarks = subjects.reduce((sum, s) => sum + s.maxMarks, 0);

  return prisma.$transaction(async (tx) => {
    const test = await tx.test.create({
      data: {
        ...rest,
        instituteId,
        batchId,
        totalMarks,
        createdById: actorUserId,
      },
    });

    await tx.testSubject.createMany({
      data: subjects.map((s) => ({
        testId: test.id,
        subjectId: s.subjectId,
        maxMarks: s.maxMarks,
        passingMarks: s.passingMarks,
      })),
    });

    return tx.test.findUnique({
      where: { id: test.id },
      include: { subjects: { include: { subject: true } }, batch: { select: { id: true, name: true } } },
    });
  });
}

async function listTests(instituteId, query, auth) {
  const { batchId, status, page = 1, limit = 20 } = query;

  let batchFilter = {};
  if (auth && auth.role === ROLES.TEACHER) {
    const teacher = await getTeacherForUser(instituteId, auth.userId);
    const links = teacher
      ? await prisma.teacherBatch.findMany({ where: { teacherId: teacher.id }, select: { batchId: true } })
      : [];
    const allowedBatchIds = links.map((l) => l.batchId);
    batchFilter = batchId
      ? { batchId: allowedBatchIds.includes(batchId) ? batchId : '__none__' }
      : { batchId: { in: allowedBatchIds } };
  } else if (batchId) {
    await findOwnedOrThrow(prisma.batch, batchId, instituteId, 'Batch not found');
    batchFilter = { batchId };
  }

  const where = {
    instituteId,
    ...batchFilter,
    ...(status ? { status } : {}),
  };

  const [items, total] = await Promise.all([
    prisma.test.findMany({
      where,
      include: {
        subjects: { include: { subject: true } },
        batch: { select: { id: true, name: true } },
        _count: { select: { results: true } },
      },
      orderBy: { testDate: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.test.count({ where }),
  ]);

  return { items, total, page, limit };
}

async function getTestById(instituteId, id, auth) {
  const test = await findOwnedOrThrow(prisma.test, id, instituteId, 'Test not found', {
    include: {
      subjects: { include: { subject: true } },
      batch: { select: { id: true, name: true } },
    },
  });

  if (auth) {
    await assertCanAccessBatch(instituteId, auth, test.batchId);
  }

  return test;
}

async function updateTest(instituteId, id, data) {
  const test = await findOwnedOrThrow(prisma.test, id, instituteId, 'Test not found');

  if (test.status === TEST_STATUS.PUBLISHED && data.status !== undefined) {
    throw new ValidationError('Unpublish the test before changing its status directly');
  }

  return prisma.test.update({ where: { id }, data });
}

async function cancelTest(instituteId, id) {
  const test = await findOwnedOrThrow(prisma.test, id, instituteId, 'Test not found');
  if (test.status === TEST_STATUS.PUBLISHED) {
    throw new ValidationError('Unpublish the test before cancelling it');
  }
  return prisma.test.update({ where: { id }, data: { status: TEST_STATUS.CANCELLED } });
}

async function assertSubjectEditable(testId, subjectId) {
  const anyMarks = await prisma.studentSubjectMark.findFirst({ where: { testId, subjectId } });
  if (anyMarks) {
    throw new ValidationError('Cannot modify a subject that already has marks entered');
  }
}

async function addTestSubject(instituteId, testId, data) {
  const test = await findOwnedOrThrow(prisma.test, testId, instituteId, 'Test not found');
  if (test.status === TEST_STATUS.PUBLISHED) {
    throw new ValidationError('Cannot modify subjects on a published test');
  }

  await findOwnedOrThrow(prisma.subject, data.subjectId, instituteId, 'Subject not found');

  try {
    await prisma.$transaction(async (tx) => {
      await tx.testSubject.create({
        data: { testId, subjectId: data.subjectId, maxMarks: data.maxMarks, passingMarks: data.passingMarks },
      });
      const subjects = await tx.testSubject.findMany({ where: { testId } });
      const totalMarks = subjects.reduce((sum, s) => sum + s.maxMarks, 0);
      await tx.test.update({ where: { id: testId }, data: { totalMarks } });
    });
  } catch (err) {
    if (err.code === 'P2002') {
      throw new ConflictError('This subject is already on the test');
    }
    throw err;
  }

  return getTestById(instituteId, testId);
}

async function updateTestSubject(instituteId, testId, testSubjectId, data) {
  const test = await findOwnedOrThrow(prisma.test, testId, instituteId, 'Test not found');
  if (test.status === TEST_STATUS.PUBLISHED) {
    throw new ValidationError('Cannot modify subjects on a published test');
  }

  const testSubject = await prisma.testSubject.findFirst({ where: { id: testSubjectId, testId } });
  if (!testSubject) {
    throw new ValidationError('Test subject not found');
  }
  await assertSubjectEditable(testId, testSubject.subjectId);

  const maxMarks = data.maxMarks ?? testSubject.maxMarks;
  const passingMarks = data.passingMarks ?? testSubject.passingMarks;
  if (passingMarks > maxMarks) {
    throw new ValidationError('Passing marks cannot exceed max marks');
  }

  await prisma.$transaction(async (tx) => {
    await tx.testSubject.update({ where: { id: testSubjectId }, data: { maxMarks, passingMarks } });
    const subjects = await tx.testSubject.findMany({ where: { testId } });
    const totalMarks = subjects.reduce((sum, s) => sum + s.maxMarks, 0);
    await tx.test.update({ where: { id: testId }, data: { totalMarks } });
  });

  return getTestById(instituteId, testId);
}

async function removeTestSubject(instituteId, testId, testSubjectId) {
  const test = await findOwnedOrThrow(prisma.test, testId, instituteId, 'Test not found');
  if (test.status === TEST_STATUS.PUBLISHED) {
    throw new ValidationError('Cannot modify subjects on a published test');
  }

  const testSubject = await prisma.testSubject.findFirst({ where: { id: testSubjectId, testId } });
  if (!testSubject) {
    throw new ValidationError('Test subject not found');
  }
  await assertSubjectEditable(testId, testSubject.subjectId);

  const remaining = await prisma.testSubject.count({ where: { testId } });
  if (remaining <= 1) {
    throw new ValidationError('A test must have at least one subject');
  }

  await prisma.$transaction(async (tx) => {
    await tx.testSubject.delete({ where: { id: testSubjectId } });
    const subjects = await tx.testSubject.findMany({ where: { testId } });
    const totalMarks = subjects.reduce((sum, s) => sum + s.maxMarks, 0);
    await tx.test.update({ where: { id: testId }, data: { totalMarks } });
  });

  return getTestById(instituteId, testId);
}

module.exports = {
  createTest,
  listTests,
  getTestById,
  updateTest,
  cancelTest,
  addTestSubject,
  updateTestSubject,
  removeTestSubject,
};
