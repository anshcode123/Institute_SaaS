const { prisma } = require('../config/prisma');
const { findOwnedOrThrow } = require('../utils/tenant');
const { ValidationError, ConflictError } = require('../utils/app-error');
const { toDecimal, add, subtract, multiply, divide, round2, greaterThan } = require('../utils/money');
const { deriveStudentFeeStatus, deriveInstallmentStatus } = require('../utils/fee-status');
const { FEE_STRUCTURE_STATUS, DISCOUNT_TYPE } = require('../constants/roles');

// Splits a discount across installment templates proportionally to each
// installment's share of the total, so a student's remaining
// installments each reflect a fair share of the discount rather than
// always discounting the first one. The last installment absorbs any
// rounding remainder so the parts always sum exactly to finalAmount.
function buildDiscountedInstallments(templates, totalAmount, discountAmount) {
  if (templates.length === 0) return [];

  let allocated = toDecimal(0);
  return templates.map((t, index) => {
    const isLast = index === templates.length - 1;
    let share;
    if (isLast) {
      share = subtract(discountAmount, allocated);
    } else {
      share = round2(multiply(divide(t.amount, totalAmount), discountAmount));
      allocated = add(allocated, share);
    }
    return {
      installmentNumber: t.installmentNumber,
      dueDate: t.dueDate,
      amount: subtract(t.amount, share),
    };
  });
}

async function assignFee(instituteId, actorUserId, data) {
  const { studentId, feeStructureId, feeStartDate, monthlyFeeGroupId, discountAmount: discountAmountInput, discountPercentage } = data;

  await findOwnedOrThrow(prisma.student, studentId, instituteId, 'Student not found');

  const feeStructure = await findOwnedOrThrow(
    prisma.feeStructure,
    feeStructureId,
    instituteId,
    'Fee structure not found',
    { include: { installments: { orderBy: { installmentNumber: 'asc' } }, monthlyGroups: { include: { subjectPrices: true } } } },
  );

  if (feeStructure.status !== FEE_STRUCTURE_STATUS.ACTIVE) {
    throw new ValidationError('This fee structure is not active');
  }

  const existing = await prisma.studentFee.findUnique({
    where: { studentId_feeStructureId: { studentId, feeStructureId } },
  });
  if (existing) {
    throw new ConflictError('This fee structure is already assigned to this student');
  }

  if (feeStructure.feeType === 'MONTHLY' && !monthlyFeeGroupId) throw new ValidationError('Select a fee group for this monthly fee');
  if (feeStructure.feeType === 'COURSE' && monthlyFeeGroupId) throw new ValidationError('Fee groups are only valid for monthly fees');
  const monthlyGroup = monthlyFeeGroupId ? feeStructure.monthlyGroups.find((group) => group.id === monthlyFeeGroupId) : null;
  if (monthlyFeeGroupId && !monthlyGroup) throw new ValidationError('Fee group does not belong to this fee structure');
  const totalAmount = monthlyGroup
    ? (monthlyGroup.pricingType === 'COMBINED' ? toDecimal(monthlyGroup.combinedAmount) : monthlyGroup.subjectPrices.reduce((sum, item) => add(sum, item.monthlyAmount), toDecimal(0)))
    : toDecimal(feeStructure.totalAmount);
  let discountType = DISCOUNT_TYPE.NONE;
  let discountValue = toDecimal(0);
  let discountAmount = toDecimal(0);

  if (discountPercentage !== undefined) {
    discountType = DISCOUNT_TYPE.PERCENTAGE;
    discountValue = toDecimal(discountPercentage);
    discountAmount = round2(multiply(totalAmount, divide(discountPercentage, 100)));
  } else if (discountAmountInput !== undefined) {
    discountType = DISCOUNT_TYPE.FIXED;
    discountValue = toDecimal(discountAmountInput);
    discountAmount = toDecimal(discountAmountInput);
  }

  // Never allow a negative final payable amount.
  if (greaterThan(discountAmount, totalAmount)) {
    throw new ValidationError('Discount cannot exceed the total fee amount');
  }

  const finalAmount = subtract(totalAmount, discountAmount);
  let installmentRows = buildDiscountedInstallments(feeStructure.installments, totalAmount, discountAmount);
  if (feeStructure.feeType === 'COURSE' && feeStructure.coursePaymentMode === 'FULL') {
    installmentRows = [{ installmentNumber: 1, dueDate: feeStartDate, amount: finalAmount }];
  }
  if (feeStructure.feeType === 'MONTHLY') {
    const dueDate = new Date(feeStartDate);
    const dueDay = Math.min(feeStructure.monthlyDueDay, new Date(dueDate.getFullYear(), dueDate.getMonth() + 1, 0).getDate());
    dueDate.setDate(dueDay);
    if (dueDate < feeStartDate) dueDate.setMonth(dueDate.getMonth() + 1);
    installmentRows = [{ installmentNumber: 1, dueDate, amount: finalAmount }];
  }

  const created = await prisma.$transaction(async (tx) => {
    const studentFee = await tx.studentFee.create({
      data: {
        instituteId,
        studentId,
        feeStructureId,
        feeStartDate,
        monthlyFeeGroupId: monthlyFeeGroupId ?? null,
        totalAmount,
        discountType,
        discountValue,
        discountAmount,
        finalAmount,
        paidAmount: 0,
        outstandingAmount: finalAmount,
        assignedById: actorUserId,
      },
    });

    await tx.feeInstallment.createMany({
      data: installmentRows.map((row) => ({
        instituteId,
        studentFeeId: studentFee.id,
        installmentNumber: row.installmentNumber,
        amount: row.amount,
        dueDate: row.dueDate,
      })),
    });

    return studentFee;
  });

  return getStudentFeeById(instituteId, created.id);
}

function getNextOutstandingInstallment(installments) {
  if (!installments || installments.length === 0) return null;
  const unpaid = installments.filter((i) => {
    const status = deriveInstallmentStatus(i);
    return status !== 'PAID' && status !== 'CANCELLED';
  });
  if (unpaid.length === 0) return null;
  unpaid.sort((a, b) => new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime());
  return unpaid[0];
}

function getDueStatusText(dueDate, isPaidOrCancelled) {
  if (isPaidOrCancelled || !dueDate) return null;
  const now = new Date();
  const todayUtc = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
  const due = new Date(dueDate);
  const dueUtc = Date.UTC(due.getUTCFullYear(), due.getUTCMonth(), due.getUTCDate());
  const diffDays = Math.round((dueUtc - todayUtc) / (24 * 60 * 60 * 1000));

  const dayStr = due.toLocaleDateString('en-US', { day: 'numeric', month: 'short', timeZone: 'UTC' });

  if (diffDays < 0) {
    return `Overdue (${dayStr})`;
  } else if (diffDays === 0) {
    return 'Due TODAY';
  } else if (diffDays === 1) {
    return 'Due TOMORROW';
  } else {
    return `Due ${dayStr}`;
  }
}

function calculateUrgencyScore(item) {
  const derivedStatus = item.status;
  if (derivedStatus === 'PAID' || derivedStatus === 'CANCELLED') {
    return { urgencyRank: 4, dueTimestamp: Infinity };
  }

  const nextInstallment = getNextOutstandingInstallment(item.installments);
  if (!nextInstallment || !nextInstallment.dueDate) {
    return { urgencyRank: 4, dueTimestamp: Infinity };
  }

  const now = new Date();
  const todayUtc = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
  const due = new Date(nextInstallment.dueDate);
  const dueUtc = Date.UTC(due.getUTCFullYear(), due.getUTCMonth(), due.getUTCDate());
  const diffDays = Math.round((dueUtc - todayUtc) / (24 * 60 * 60 * 1000));

  if (diffDays < 0) {
    // Overdue - rank 1, earlier overdue first
    return { urgencyRank: 1, dueTimestamp: dueUtc };
  } else if (diffDays === 0) {
    // Due Today - rank 2
    return { urgencyRank: 2, dueTimestamp: dueUtc };
  } else {
    // Upcoming - rank 3, nearest first
    return { urgencyRank: 3, dueTimestamp: dueUtc };
  }
}

function compareFeeUrgency(a, b) {
  const scoreA = calculateUrgencyScore(a);
  const scoreB = calculateUrgencyScore(b);

  if (scoreA.urgencyRank !== scoreB.urgencyRank) {
    return scoreA.urgencyRank - scoreB.urgencyRank;
  }
  if (scoreA.dueTimestamp !== scoreB.dueTimestamp) {
    return scoreA.dueTimestamp - scoreB.dueTimestamp;
  }

  // Secondary sort: Student name (firstName + lastName) case-insensitive ascending
  const nameA = ((a.student?.firstName || '') + ' ' + (a.student?.lastName || '')).trim().toLowerCase();
  const nameB = ((b.student?.firstName || '') + ' ' + (b.student?.lastName || '')).trim().toLowerCase();
  if (nameA !== nameB) {
    return nameA.localeCompare(nameB);
  }
  return new Date(b.createdAt || 0).getTime() - new Date(a.createdAt || 0).getTime();
}

function serializeStudentFee(studentFee) {
  const installments = (studentFee.installments || []).map((i) => ({
    ...i,
    status: deriveInstallmentStatus(i),
  }));
  const derivedStatus = deriveStudentFeeStatus(studentFee, studentFee.installments || []);
  const nextInstallment = derivedStatus !== 'PAID' && derivedStatus !== 'CANCELLED'
    ? getNextOutstandingInstallment(installments)
    : null;
  const nextDueDate = nextInstallment ? nextInstallment.dueDate : null;
  const dueStatusText = getDueStatusText(nextDueDate, derivedStatus === 'PAID' || derivedStatus === 'CANCELLED');

  return {
    ...studentFee,
    status: derivedStatus,
    installments,
    nextDueDate,
    dueStatusText,
  };
}

async function listStudentFees(instituteId, query = {}) {
  const { studentId, status } = query;
  const page = parseInt(query.page, 10) || 1;
  const limit = parseInt(query.limit, 10) || 20;

  const where = {
    instituteId,
    ...(studentId ? { studentId } : {}),
  };

  const rows = await prisma.studentFee.findMany({
    where,
    include: {
      installments: { orderBy: { installmentNumber: 'asc' } },
      student: { select: { id: true, firstName: true, lastName: true, studentCode: true } },
      feeStructure: { select: { id: true, name: true, currency: true, feeType: true } },
      monthlyFeeGroup: { select: { id: true, name: true } },
    },
    orderBy: { createdAt: 'desc' },
  });

  let items = rows.map(serializeStudentFee);

  // OVERDUE is derived, so a status=OVERDUE filter is applied after
  // fetching rather than in the SQL WHERE clause.
  if (status) {
    items = items.filter((i) => i.status === status);
  }

  // Sort by urgency: Overdue -> Due Today -> Nearest Upcoming -> Later Upcoming -> Paid/None
  items.sort(compareFeeUrgency);

  const total = items.length;
  const paginatedItems = items.slice((page - 1) * limit, page * limit);

  return { items: paginatedItems, total, page, limit };
}

async function getStudentFeeById(instituteId, id) {
  const studentFee = await findOwnedOrThrow(
    prisma.studentFee,
    id,
    instituteId,
    'Student fee not found',
    {
      include: {
        installments: { orderBy: { installmentNumber: 'asc' } },
        student: { select: { id: true, firstName: true, lastName: true, studentCode: true } },
        feeStructure: { select: { id: true, name: true, currency: true, feeType: true } },
        monthlyFeeGroup: { select: { id: true, name: true } },
        payments: { orderBy: { paymentDate: 'desc' } },
      },
    },
  );
  return serializeStudentFee(studentFee);
}

// Aggregate view for one student across all their fee assignments - used
// by the Student Profile "Fees" section.
async function getFeesForStudent(instituteId, studentId) {
  await findOwnedOrThrow(prisma.student, studentId, instituteId, 'Student not found');

  const rows = await prisma.studentFee.findMany({
    where: { instituteId, studentId },
    include: {
      installments: { orderBy: { installmentNumber: 'asc' } },
      feeStructure: { select: { id: true, name: true, currency: true, feeType: true } },
      monthlyFeeGroup: { select: { id: true, name: true } },
      payments: { orderBy: { paymentDate: 'desc' }, include: { receipt: true } },
    },
    orderBy: { createdAt: 'desc' },
  });

  const items = rows.map(serializeStudentFee);

  const totals = items.reduce(
    (acc, fee) => ({
      totalAmount: add(acc.totalAmount, fee.totalAmount),
      discountAmount: add(acc.discountAmount, fee.discountAmount),
      finalAmount: add(acc.finalAmount, fee.finalAmount),
      paidAmount: add(acc.paidAmount, fee.paidAmount),
      outstandingAmount: add(acc.outstandingAmount, fee.outstandingAmount),
    }),
    {
      totalAmount: toDecimal(0),
      discountAmount: toDecimal(0),
      finalAmount: toDecimal(0),
      paidAmount: toDecimal(0),
      outstandingAmount: toDecimal(0),
    },
  );

  return { fees: items, summary: totals };
}

module.exports = {
  assignFee,
  listStudentFees,
  getStudentFeeById,
  getFeesForStudent,
  serializeStudentFee,
};
