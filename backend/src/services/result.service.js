const { prisma } = require('../config/prisma');
const { findOwnedOrThrow } = require('../utils/tenant');
const { assertCanAccessBatch } = require('../utils/teacher-access');
const { ValidationError } = require('../utils/app-error');
const { TEST_STATUS, RESULT_STATUS, ROLES } = require('../constants/roles');

const resultInclude = {
  student: { select: { id: true, firstName: true, lastName: true, studentCode: true } },
  test: {
    select: {
      id: true,
      name: true,
      testDate: true,
      status: true,
      batch: { select: { id: true, name: true } },
    },
  },
};

async function getTestResults(instituteId, testId, auth) {
  const test = await findOwnedOrThrow(prisma.test, testId, instituteId, 'Test not found');
  if (auth) {
    await assertCanAccessBatch(instituteId, auth, test.batchId);
  }

  const results = await prisma.studentTestResult.findMany({
    where: { testId: testId },
    include: resultInclude,
    orderBy: { obtainedMarks: 'desc' },
  });

  const marks = [];
  for (let i = 0; i < results.length; i++) {
    marks.push(results[i].obtainedMarks);
  }
  let passCount = 0;
  for (let i = 0; i < results.length; i++) {
    if (results[i].status === RESULT_STATUS.PASS) passCount++;
  }
  const failCount = results.length - passCount;

  let sum = 0;
  for (let i = 0; i < marks.length; i++) sum += marks[i];
  const average = results.length ? Number((sum / results.length).toFixed(2)) : 0;
  const highest = results.length ? Math.max.apply(null, marks) : 0;
  const lowest = results.length ? Math.min.apply(null, marks) : 0;
  const passPercentage = results.length ? Number(((passCount / results.length) * 100).toFixed(2)) : 0;

  const summary = {
    studentCount: results.length,
    average: average,
    highest: highest,
    lowest: lowest,
    passCount: passCount,
    failCount: failCount,
    passPercentage: passPercentage,
  };

  // Rank by obtainedMarks descending, standard competition ranking:
  // ties share a rank, and the next distinct score skips ahead by the
  // number of tied students (e.g. 1, 1, 3, 4).
  let rank = 0;
  let previousMarks = null;
  const ranked = [];
  for (let i = 0; i < results.length; i++) {
    const r = results[i];
    if (r.obtainedMarks !== previousMarks) {
      rank = i + 1;
      previousMarks = r.obtainedMarks;
    }
    const withRank = Object.assign({}, r);
    withRank.rank = rank;
    ranked.push(withRank);
  }

  return {
    test: { id: test.id, name: test.name, status: test.status },
    results: ranked,
    summary: summary,
  };
}

async function publishTest(instituteId, testId) {
  const test = await findOwnedOrThrow(prisma.test, testId, instituteId, 'Test not found', {
    include: { subjects: true },
  });

  if (test.status === TEST_STATUS.PUBLISHED) {
    throw new ValidationError('This test is already published');
  }
  if (test.status === TEST_STATUS.CANCELLED) {
    throw new ValidationError('A cancelled test cannot be published');
  }

  const enrolledStudents = await prisma.student.count({
    where: { instituteId: instituteId, batchId: test.batchId, status: 'ACTIVE' },
  });
  const completedResults = await prisma.studentTestResult.count({ where: { testId: testId } });

  if (completedResults === 0) {
    throw new ValidationError('No results have been calculated yet - enter marks before publishing');
  }
  if (completedResults < enrolledStudents) {
    const missing = enrolledStudents - completedResults;
    throw new ValidationError(
      'Marks are incomplete for ' + missing + ' of ' + enrolledStudents +
        ' enrolled student(s) - all students need marks for every subject before publishing',
    );
  }

  const now = new Date();
  await prisma.$transaction(async function (tx) {
    await tx.studentTestResult.updateMany({ where: { testId: testId }, data: { publishedAt: now } });
    await tx.test.update({ where: { id: testId }, data: { status: TEST_STATUS.PUBLISHED } });
  });

  return getTestById(testId);
}

async function unpublishTest(instituteId, testId) {
  const test = await findOwnedOrThrow(prisma.test, testId, instituteId, 'Test not found');
  if (test.status !== TEST_STATUS.PUBLISHED) {
    throw new ValidationError('This test is not currently published');
  }

  await prisma.$transaction(async function (tx) {
    await tx.studentTestResult.updateMany({ where: { testId: testId }, data: { publishedAt: null } });
    await tx.test.update({ where: { id: testId }, data: { status: TEST_STATUS.COMPLETED } });
  });

  return getTestById(testId);
}

async function getTestById(id) {
  return prisma.test.findUnique({
    where: { id: id },
    include: { subjects: { include: { subject: true } }, batch: { select: { id: true, name: true } } },
  });
}

async function getStudentResults(instituteId, auth, studentId) {
  const student = await findOwnedOrThrow(prisma.student, studentId, instituteId, 'Student not found');

  if (auth.role === ROLES.TEACHER) {
    if (!student.batchId) {
      throw new ValidationError('This student is not in any of your batches');
    }
    await assertCanAccessBatch(instituteId, auth, student.batchId);
  }

  return prisma.studentTestResult.findMany({
    where: { instituteId: instituteId, studentId: studentId },
    include: resultInclude,
    orderBy: { test: { testDate: 'desc' } },
  });
}

async function getStudentResultById(instituteId, auth, studentId, resultId) {
  const student = await findOwnedOrThrow(prisma.student, studentId, instituteId, 'Student not found');

  if (auth.role === ROLES.TEACHER) {
    if (!student.batchId) {
      throw new ValidationError('This student is not in any of your batches');
    }
    await assertCanAccessBatch(instituteId, auth, student.batchId);
  }

  const includeShape = {
    student: resultInclude.student,
    test: { include: { subjects: { include: { subject: true } } } },
  };

  const result = await findOwnedOrThrow(
    prisma.studentTestResult,
    resultId,
    instituteId,
    'Result not found',
    { include: includeShape },
  );

  if (result.studentId !== studentId) {
    throw new ValidationError('Result not found');
  }

  const subjectMarks = await prisma.studentSubjectMark.findMany({
    where: { testId: result.testId, studentId: studentId },
    include: { subject: { select: { id: true, name: true } } },
  });

  const withMarks = Object.assign({}, result);
  withMarks.subjectMarks = subjectMarks;
  return withMarks;
}

module.exports = {
  getTestResults,
  publishTest,
  unpublishTest,
  getStudentResults,
  getStudentResultById,
};
