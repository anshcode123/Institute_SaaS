const { prisma } = require('../config/prisma');
const { NotFoundError, ForbiddenError } = require('../utils/app-error');
const { assertParentOwnsStudent, getParentForUser } = require('../utils/parent-access');

const studentService = require('./student.service');
const attendanceService = require('./attendance.service');
const studentFeeService = require('./student-fee.service');
const paymentService = require('./payment.service');
const resultService = require('./result.service');
const announcementService = require('./announcement.service');

async function getMyProfile(instituteId, userId) {
  var parent = await getParentForUser(instituteId, userId);
  if (!parent) {
    throw new ForbiddenError('No parent profile is linked to this account');
  }
  return parent;
}

async function getMyChildren(instituteId, userId) {
  var parent = await getParentForUser(instituteId, userId);
  if (!parent) {
    throw new ForbiddenError('No parent profile is linked to this account');
  }

  var links = await prisma.studentParent.findMany({
    where: { parentId: parent.id },
    include: {
      student: {
        select: {
          id: true,
          firstName: true,
          lastName: true,
          studentCode: true,
          status: true,
          batch: { select: { id: true, name: true } },
        },
      },
    },
  });

  return links.map(function (l) {
    return Object.assign({}, l.student, { relationship: l.relationship });
  });
}

async function getChildDashboard(instituteId, auth, studentId) {
  await assertParentOwnsStudent(instituteId, auth, studentId);

  var student = await studentService.getStudentById(instituteId, studentId);
  var portalAuth = { role: 'PARENT', userId: auth.userId };

  var attendanceSummary = student.batch
    ? await attendanceService.getStudentSummary(instituteId, portalAuth, studentId)
    : null;
  var feesResult = await studentFeeService.getFeesForStudent(instituteId, studentId);
  var allResults = await resultService.getStudentResults(instituteId, portalAuth, studentId);
  var publishedResults = allResults.filter(function (r) { return r.publishedAt !== null; });

  return {
    student: student,
    attendanceSummary: attendanceSummary,
    feesSummary: feesResult.summary,
    latestResult: publishedResults.length ? publishedResults[0] : null,
  };
}

async function getChildAttendance(instituteId, auth, studentId, query) {
  await assertParentOwnsStudent(instituteId, auth, studentId);
  var forcedQuery = Object.assign({}, query, { studentId: studentId });
  return attendanceService.listAttendance(instituteId, { role: 'PARENT', userId: auth.userId }, forcedQuery);
}

async function getChildFees(instituteId, auth, studentId) {
  await assertParentOwnsStudent(instituteId, auth, studentId);
  return studentFeeService.getFeesForStudent(instituteId, studentId);
}

async function getChildPayments(instituteId, auth, studentId, query) {
  await assertParentOwnsStudent(instituteId, auth, studentId);
  var forcedQuery = Object.assign({}, query, { studentId: studentId });
  return paymentService.listPayments(instituteId, forcedQuery);
}

async function getChildReceipt(instituteId, auth, studentId, receiptId) {
  await assertParentOwnsStudent(instituteId, auth, studentId);
  var receipt = await paymentService.getReceiptById(instituteId, receiptId);
  if (receipt.payment.studentId !== studentId) {
    throw new NotFoundError('Receipt not found');
  }
  return receipt;
}

async function getChildResults(instituteId, auth, studentId) {
  await assertParentOwnsStudent(instituteId, auth, studentId);
  var results = await resultService.getStudentResults(
    instituteId,
    { role: 'PARENT', userId: auth.userId },
    studentId,
  );
  return results.filter(function (r) { return r.publishedAt !== null; });
}

async function getChildResultById(instituteId, auth, studentId, resultId) {
  await assertParentOwnsStudent(instituteId, auth, studentId);
  var result = await resultService.getStudentResultById(
    instituteId,
    { role: 'PARENT', userId: auth.userId },
    studentId,
    resultId,
  );
  if (!result.publishedAt) {
    throw new NotFoundError('Result not found');
  }
  return result;
}

async function getChildAnnouncements(instituteId, auth, studentId) {
  await assertParentOwnsStudent(instituteId, auth, studentId);
  var student = await prisma.student.findUnique({ where: { id: studentId }, select: { batchId: true } });
  return announcementService.listAnnouncementsForRole(instituteId, 'PARENT', student.batchId);
}

module.exports = {
  getMyProfile: getMyProfile,
  getMyChildren: getMyChildren,
  getChildDashboard: getChildDashboard,
  getChildAttendance: getChildAttendance,
  getChildFees: getChildFees,
  getChildPayments: getChildPayments,
  getChildReceipt: getChildReceipt,
  getChildResults: getChildResults,
  getChildResultById: getChildResultById,
  getChildAnnouncements: getChildAnnouncements,
};
