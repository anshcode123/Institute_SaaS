const { prisma } = require('../config/prisma');
const { findOwnedOrThrow } = require('../utils/tenant');
const { assertCanAccessBatch, getTeacherForUser } = require('../utils/teacher-access');
const { ValidationError, ForbiddenError } = require('../utils/app-error');
const { ATTENDANCE_STATUS, ROLES, RECORD_STATUS } = require('../constants/roles');

function toDateOnly(date) {
  const d = date instanceof Date ? date : new Date(date);
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
}

function today() {
  return toDateOnly(new Date());
}

const studentSelect = { id: true, firstName: true, lastName: true, studentCode: true };
const batchSelect = { id: true, name: true };
const markedBySelect = { id: true, name: true, role: true };

async function withRelations(attendance) {
  if (!attendance) return null;
  return prisma.attendance.findUnique({
    where: { id: attendance.id },
    include: {
      student: { select: studentSelect },
      batch: { select: batchSelect },
      markedBy: { select: markedBySelect },
    },
  });
}

async function markPresentOrReturnExisting(instituteId, { studentId, batchId, date, markedById }) {
  const existing = await prisma.attendance.findUnique({
    where: { studentId_batchId_date: { studentId, batchId, date } },
  });

  if (existing) {
    return { alreadyMarked: true, attendance: await withRelations(existing) };
  }

  try {
    const created = await prisma.attendance.create({
      data: {
        instituteId,
        studentId,
        batchId,
        date,
        status: ATTENDANCE_STATUS.PRESENT,
        markedById,
      },
    });
    return { alreadyMarked: false, attendance: await withRelations(created) };
  } catch (err) {
    // Race: two scans landed at once and both passed the findUnique check.
    // Treat the resulting unique-constraint hit as "already marked"
    // rather than surfacing a 500.
    if (err.code === 'P2002') {
      const record = await prisma.attendance.findUnique({
        where: { studentId_batchId_date: { studentId, batchId, date } },
      });
      return { alreadyMarked: true, attendance: await withRelations(record) };
    }
    throw err;
  }
}

const { notifyStudentAndParents } = require('../utils/portal-notify');

// ---------------------------------------------------------------------
// QR scan
// ---------------------------------------------------------------------
async function scanAttendance(instituteId, auth, { qrToken, batchId }) {
  let token = qrToken.trim();
  if (token.startsWith('LEAVE:')) {
    throw new ValidationError('This is a leaving QR code, not an attendance QR code');
  }
  if (token.startsWith('ATTEND:')) {
    token = token.replace('ATTEND:', '');
  }

  // Look up by the opaque token first, then confirm tenant ownership -
  // the same generic error either way, so a token from another institute
  // never confirms whether it "exists" versus "isn't valid here".
  const student = await prisma.student.findUnique({
    where: { qrCode: token },
    include: { batch: true },
  });
  if (!student || student.instituteId !== instituteId) {
    throw new ValidationError('Invalid student QR code');
  }

  const effectiveBatchId = batchId || student.batchId;
  if (!effectiveBatchId) {
    throw new ValidationError('Student is not enrolled in any batch');
  }

  await findOwnedOrThrow(prisma.batch, effectiveBatchId, instituteId, 'Batch not found');
  await assertCanAccessBatch(instituteId, auth, effectiveBatchId);

  if (student.batchId && student.batchId !== effectiveBatchId) {
    throw new ValidationError('Student is not enrolled in this batch');
  }

  const result = await markPresentOrReturnExisting(instituteId, {
    studentId: student.id,
    batchId: effectiveBatchId,
    date: today(),
    markedById: auth.userId,
  });

  if (!result.alreadyMarked) {
    notifyStudentAndParents(instituteId, student.id, {
      type: 'ATTENDANCE',
      title: 'Attendance Marked',
      message: `${student.firstName} ${student.lastName} was marked PRESENT for today.`,
      entityType: 'ATTENDANCE',
      entityId: result.attendance.id,
    }).catch(() => { });
  }

  return result;
}

// ---------------------------------------------------------------------
// Leaving QR scan
// ---------------------------------------------------------------------
async function scanLeaving(instituteId, auth, { qrToken }) {
  let token = qrToken.trim();
  if (token.startsWith('LEAVE:')) {
    token = token.replace('LEAVE:', '');
  }

  const student = await prisma.student.findUnique({
    where: { qrCode: token },
    include: { batch: true },
  });
  if (!student || student.instituteId !== instituteId) {
    throw new ValidationError('Invalid student leaving QR code');
  }

  // Check if student checked in today
  const attendanceToday = await prisma.attendance.findFirst({
    where: {
      instituteId,
      studentId: student.id,
      date: today(),
      status: ATTENDANCE_STATUS.PRESENT,
    },
    include: { batch: true },
  });

  if (!attendanceToday) {
    throw new ValidationError('Student has not checked in today');
  }

  const leavingTime = new Date();

  notifyStudentAndParents(instituteId, student.id, {
    type: 'LEAVING',
    title: 'Leaving Recorded',
    message: `${student.firstName} ${student.lastName} marked check-out at ${leavingTime.toLocaleTimeString()}.`,
    entityType: 'ATTENDANCE',
    entityId: attendanceToday.id,
  }).catch(() => { });

  return {
    student: {
      id: student.id,
      studentCode: student.studentCode,
      firstName: student.firstName,
      lastName: student.lastName,
      fullName: `${student.firstName} ${student.lastName}`,
      batch: student.batch ? { id: student.batch.id, name: student.batch.name } : null,
    },
    leavingTime,
    message: 'Student check-out recorded successfully',
  };
}

// ---------------------------------------------------------------------
// Manual attendance
// ---------------------------------------------------------------------
async function markManual(instituteId, auth, { batchId, date, entries }) {
  await findOwnedOrThrow(prisma.batch, batchId, instituteId, 'Batch not found');
  await assertCanAccessBatch(instituteId, auth, batchId);

  const attendanceDate = date ? toDateOnly(date) : today();
  const studentIds = entries.map((e) => e.studentId);

  // Every student must belong to this institute AND actually be enrolled
  // in this batch - not just exist somewhere in the institute.
  const owned = await prisma.student.findMany({
    where: { id: { in: studentIds }, instituteId, batchId },
    select: { id: true },
  });
  if (owned.length !== studentIds.length) {
    throw new ValidationError('One or more students are not enrolled in this batch');
  }

  await prisma.$transaction(
    entries.map((entry) =>
      prisma.attendance.upsert({
        where: {
          studentId_batchId_date: { studentId: entry.studentId, batchId, date: attendanceDate },
        },
        create: {
          instituteId,
          studentId: entry.studentId,
          batchId,
          date: attendanceDate,
          status: entry.status,
          markedById: auth.userId,
        },
        update: {
          status: entry.status,
          markedById: auth.userId,
          markedAt: new Date(),
        },
      }),
    ),
  );

  return prisma.attendance.findMany({
    where: { instituteId, batchId, date: attendanceDate, studentId: { in: studentIds } },
    include: {
      student: { select: studentSelect },
      batch: { select: batchSelect },
      markedBy: { select: markedBySelect },
    },
    orderBy: { student: { firstName: 'asc' } },
  });
}

// ---------------------------------------------------------------------
// History / listing
// ---------------------------------------------------------------------
async function listAttendance(instituteId, auth, query) {
  const { batchId, studentId, status, date, page = 1, limit = 20 } = query;

  let batchFilter = {};
  if (auth.role === ROLES.TEACHER) {
    if (batchId) {
      await assertCanAccessBatch(instituteId, auth, batchId);
      batchFilter = { batchId };
    } else {
      const teacher = await getTeacherForUser(instituteId, auth.userId);
      const links = teacher
        ? await prisma.teacherBatch.findMany({ where: { teacherId: teacher.id }, select: { batchId: true } })
        : [];
      batchFilter = { batchId: { in: links.map((l) => l.batchId) } };
    }
  } else if (batchId) {
    await findOwnedOrThrow(prisma.batch, batchId, instituteId, 'Batch not found');
    batchFilter = { batchId };
  }

  const where = {
    instituteId,
    ...batchFilter,
    ...(studentId ? { studentId } : {}),
    ...(status ? { status } : {}),
    ...(date ? { date: toDateOnly(date) } : {}),
  };

  const [items, total] = await Promise.all([
    prisma.attendance.findMany({
      where,
      include: {
        student: { select: studentSelect },
        batch: { select: batchSelect },
        markedBy: { select: markedBySelect },
      },
      orderBy: [{ date: 'desc' }, { markedAt: 'desc' }],
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.attendance.count({ where }),
  ]);

  return { items, total, page, limit };
}

// ---------------------------------------------------------------------
// Summaries
// ---------------------------------------------------------------------
async function getStudentSummary(instituteId, auth, studentId) {
  const student = await findOwnedOrThrow(prisma.student, studentId, instituteId, 'Student not found');

  if (auth.role === ROLES.TEACHER) {
    if (!student.batchId) {
      throw new ForbiddenError('This student is not in any of your batches');
    }
    await assertCanAccessBatch(instituteId, auth, student.batchId);
  }

  const grouped = await prisma.attendance.groupBy({
    by: ['status'],
    where: { instituteId, studentId },
    _count: true,
  });

  const counts = { PRESENT: 0, ABSENT: 0, LATE: 0, EXCUSED: 0 };
  grouped.forEach((g) => {
    counts[g.status] = g._count;
  });
  const total = Object.values(counts).reduce((a, b) => a + b, 0);
  const percentage = total > 0 ? Number(((counts.PRESENT / total) * 100).toFixed(1)) : 0;

  const recent = await prisma.attendance.findMany({
    where: { instituteId, studentId },
    include: { batch: { select: batchSelect } },
    orderBy: { date: 'desc' },
    take: 10,
  });

  return {
    studentId,
    total,
    present: counts.PRESENT,
    absent: counts.ABSENT,
    late: counts.LATE,
    excused: counts.EXCUSED,
    percentage,
    recent,
  };
}

async function getBatchSummary(instituteId, auth, batchId, date) {
  await findOwnedOrThrow(prisma.batch, batchId, instituteId, 'Batch not found');
  await assertCanAccessBatch(instituteId, auth, batchId);

  const summaryDate = date ? toDateOnly(date) : today();

  const totalStudents = await prisma.student.count({
    where: { instituteId, batchId, status: RECORD_STATUS.ACTIVE },
  });

  const grouped = await prisma.attendance.groupBy({
    by: ['status'],
    where: { instituteId, batchId, date: summaryDate },
    _count: true,
  });

  const counts = { PRESENT: 0, ABSENT: 0, LATE: 0, EXCUSED: 0 };
  grouped.forEach((g) => {
    counts[g.status] = g._count;
  });
  const marked = Object.values(counts).reduce((a, b) => a + b, 0);
  const percentage =
    totalStudents > 0 ? Number(((counts.PRESENT / totalStudents) * 100).toFixed(1)) : 0;

  return {
    batchId,
    date: summaryDate,
    totalStudents,
    present: counts.PRESENT,
    absent: counts.ABSENT,
    late: counts.LATE,
    excused: counts.EXCUSED,
    remaining: totalStudents - marked,
    percentage,
  };
}

module.exports = {
  scanAttendance,
  scanLeaving,
  markManual,
  listAttendance,
  getStudentSummary,
  getBatchSummary,
};
