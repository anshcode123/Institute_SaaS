const { prisma } = require('../config/prisma');
const { NotFoundError, ForbiddenError } = require('../utils/app-error');

const studentService = require('./student.service');
const attendanceService = require('./attendance.service');
const studentFeeService = require('./student-fee.service');
const paymentService = require('./payment.service');
const resultService = require('./result.service');
const announcementService = require('./announcement.service');

// Every function below derives studentId from the authenticated user's
// own Student.userId link, never from anything the client sends. This is
// the entire security model of the student portal: a STUDENT-role token
// can only ever resolve to exactly one Student row.
async function resolveOwnStudentId(instituteId, userId) {
  var student = await prisma.student.findFirst({
    where: { instituteId: instituteId, userId: userId },
    select: { id: true },
  });
  if (!student) {
    throw new ForbiddenError('No student profile is linked to this account');
  }
  return student.id;
}

async function getMyProfile(instituteId, userId) {
  var studentId = await resolveOwnStudentId(instituteId, userId);
  return studentService.getStudentById(instituteId, studentId);
}

async function getMyDashboard(instituteId, userId) {
  var studentId = await resolveOwnStudentId(instituteId, userId);
  var student = await studentService.getStudentById(instituteId, studentId);
  var auth = { role: 'STUDENT', userId: userId };

  var attendanceSummary = student.batch
    ? await attendanceService.getStudentSummary(instituteId, auth, studentId)
    : null;

  var feesResult = await studentFeeService.getFeesForStudent(instituteId, studentId);
  var allResults = await resultService.getStudentResults(instituteId, auth, studentId);
  var publishedResults = allResults.filter(function (r) { return r.publishedAt !== null; });
  var latestResult = publishedResults.length ? publishedResults[0] : null;

  var unreadCount = await prisma.notification.count({
    where: { instituteId: instituteId, userId: userId, readAt: null },
  });

  return {
    student: student,
    attendanceSummary: attendanceSummary,
    feesSummary: feesResult.summary,
    latestResult: latestResult,
    unreadNotificationCount: unreadCount,
  };
}

async function getMyAttendance(instituteId, userId, query) {
  var studentId = await resolveOwnStudentId(instituteId, userId);
  var forcedQuery = Object.assign({}, query, { studentId: studentId });
  return attendanceService.listAttendance(instituteId, { role: 'STUDENT', userId: userId }, forcedQuery);
}

async function getMyQrCodes(instituteId, userId) {
  var studentId = await resolveOwnStudentId(instituteId, userId);
  var student = await prisma.student.findUnique({
    where: { id: studentId },
    select: { qrCode: true, leavingQrCode: true },
  });
  return { attendanceQr: student.qrCode, leavingQr: student.leavingQrCode };
}

async function getMyFees(instituteId, userId) {
  var studentId = await resolveOwnStudentId(instituteId, userId);
  return studentFeeService.getFeesForStudent(instituteId, studentId);
}

async function getMyPayments(instituteId, userId, query) {
  var studentId = await resolveOwnStudentId(instituteId, userId);
  var forcedQuery = Object.assign({}, query, { studentId: studentId });
  return paymentService.listPayments(instituteId, forcedQuery);
}

async function getMyReceipt(instituteId, userId, receiptId) {
  var studentId = await resolveOwnStudentId(instituteId, userId);
  var receipt = await paymentService.getReceiptById(instituteId, receiptId);
  if (receipt.payment.studentId !== studentId) {
    throw new NotFoundError('Receipt not found');
  }
  return receipt;
}

async function getMyResults(instituteId, userId) {
  var studentId = await resolveOwnStudentId(instituteId, userId);
  var results = await resultService.getStudentResults(instituteId, { role: 'STUDENT', userId: userId }, studentId);
  return results.filter(function (r) { return r.publishedAt !== null; });
}

async function getMyResultById(instituteId, userId, resultId) {
  var studentId = await resolveOwnStudentId(instituteId, userId);
  var result = await resultService.getStudentResultById(
    instituteId,
    { role: 'STUDENT', userId: userId },
    studentId,
    resultId,
  );
  if (!result.publishedAt) {
    throw new NotFoundError('Result not found');
  }
  return result;
}

async function getMyAnnouncements(instituteId, userId) {
  var studentId = await resolveOwnStudentId(instituteId, userId);
  var student = await prisma.student.findUnique({ where: { id: studentId }, select: { batchId: true } });
  return announcementService.listAnnouncementsForRole(instituteId, 'STUDENT', student.batchId);
}

module.exports = {
  getMyProfile: getMyProfile,
  getMyDashboard: getMyDashboard,
  getMyAttendance: getMyAttendance,
  getMyQrCodes: getMyQrCodes,
  getMyFees: getMyFees,
  getMyPayments: getMyPayments,
  getMyReceipt: getMyReceipt,
  getMyResults: getMyResults,
  getMyResultById: getMyResultById,
  getMyAnnouncements: getMyAnnouncements,
};
