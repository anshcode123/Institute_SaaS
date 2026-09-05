const { prisma } = require('../config/prisma');
const { findOwnedOrThrow } = require('../utils/tenant');
const { assertCanAccessBatch } = require('../utils/teacher-access');
const { ValidationError, NotFoundError } = require('../utils/app-error');
const { computeResult } = require('../utils/grade');
const { TEST_STATUS } = require('../constants/roles');

async function saveMarks(instituteId, testId, auth, payload) {
  const subjectId = payload.subjectId;
  const entries = payload.entries;

  const test = await findOwnedOrThrow(prisma.test, testId, instituteId, 'Test not found', {
    include: { subjects: true },
  });

  if (test.status === TEST_STATUS.PUBLISHED) {
    throw new ValidationError('This test is published - unpublish it before editing marks');
  }
  if (test.status === TEST_STATUS.CANCELLED) {
    throw new ValidationError('This test has been cancelled');
  }

  await assertCanAccessBatch(instituteId, auth, test.batchId);

  const testSubject = test.subjects.find((s) => s.subjectId === subjectId);
  if (!testSubject) {
    throw new NotFoundError('This subject is not configured on this test');
  }

  const studentIds = entries.map((e) => e.studentId);
  const owned = await prisma.student.findMany({
    where: { id: { in: studentIds }, instituteId, batchId: test.batchId },
    select: { id: true },
  });
  if (owned.length !== studentIds.length) {
    throw new ValidationError('One or more students are not enrolled in this batch');
  }

  for (const entry of entries) {
    if (entry.obtainedMarks > testSubject.maxMarks) {
      throw new ValidationError(
        'Obtained marks (' + entry.obtainedMarks + ') cannot exceed the max marks (' +
          testSubject.maxMarks + ') for this subject',
      );
    }
  }

  await prisma.$transaction(async (tx) => {
    for (const entry of entries) {
      await tx.studentSubjectMark.upsert({
        where: { testId_studentId_subjectId: { testId, studentId: entry.studentId, subjectId } },
        create: {
          instituteId,
          testId,
          studentId: entry.studentId,
          subjectId,
          maxMarks: testSubject.maxMarks,
          obtainedMarks: entry.obtainedMarks,
          enteredById: auth.userId,
        },
        update: {
          obtainedMarks: entry.obtainedMarks,
          enteredById: auth.userId,
        },
      });
    }

    for (const entry of entries) {
      await recomputeStudentResult(tx, instituteId, test, entry.studentId);
    }
  });

  return listMarks(instituteId, testId, { subjectId }, auth);
}

async function recomputeStudentResult(tx, instituteId, test, studentId) {
  const marks = await tx.studentSubjectMark.findMany({
    where: { testId: test.id, studentId },
  });

  const testSubjectCount = await tx.testSubject.count({ where: { testId: test.id } });
  if (marks.length < testSubjectCount) {
    return;
  }

  const obtainedMarks = marks.reduce((sum, m) => sum + m.obtainedMarks, 0);
  const subjectConfigs = await tx.testSubject.findMany({ where: { testId: test.id } });
  const subjectResultsForCompute = marks.map((m) => {
    const config = subjectConfigs.find((s) => s.subjectId === m.subjectId);
    return { obtainedMarks: m.obtainedMarks, passingMarks: config.passingMarks };
  });

  const computed = computeResult({
    totalMarks: test.totalMarks,
    obtainedMarks,
    passingMarks: test.passingMarks,
    subjectResults: subjectResultsForCompute,
  });

  await tx.studentTestResult.upsert({
    where: { testId_studentId: { testId: test.id, studentId } },
    create: {
      instituteId,
      testId: test.id,
      studentId,
      totalMarks: test.totalMarks,
      obtainedMarks,
      percentage: computed.percentage,
      grade: computed.grade,
      status: computed.status,
    },
    update: {
      totalMarks: test.totalMarks,
      obtainedMarks,
      percentage: computed.percentage,
      grade: computed.grade,
      status: computed.status,
    },
  });
}

async function listMarks(instituteId, testId, query, auth) {
  const test = await findOwnedOrThrow(prisma.test, testId, instituteId, 'Test not found');
  if (auth) {
    await assertCanAccessBatch(instituteId, auth, test.batchId);
  }

  const subjectId = query.subjectId;

  const marks = await prisma.studentSubjectMark.findMany({
    where: Object.assign({ testId: testId }, subjectId ? { subjectId: subjectId } : {}),
    include: {
      student: { select: { id: true, firstName: true, lastName: true, studentCode: true } },
      subject: { select: { id: true, name: true } },
    },
    orderBy: { student: { firstName: 'asc' } },
  });

  return marks;
}

module.exports = { saveMarks, listMarks };
