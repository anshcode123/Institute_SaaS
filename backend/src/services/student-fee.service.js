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
  const { studentId, feeStructureId, discountAmount: discountAmountInput, discountPercentage } = data;

  await findOwnedOrThrow(prisma.student, studentId, instituteId, 'Student not found');

  const feeStructure = await findOwnedOrThrow(
    prisma.feeStructure,
    feeStructureId,
    instituteId,
    'Fee structure not found',
    { include: { installments: { orderBy: { installmentNumber: 'asc' } } } },
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

  const totalAmount = toDecimal(feeStructure.totalAmount);
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
  const installmentRows = buildDiscountedInstallments(
    feeStructure.installments,
    totalAmount,
    discountAmount,
  );

  const created = await prisma.$transaction(async (tx) => {
    const studentFee = await tx.studentFee.create({
      data: {
        instituteId,
        studentId,
        feeStructureId,
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

function serializeStudentFee(studentFee) {
  const installments = studentFee.installments.map((i) => ({
    ...i,
    status: deriveInstallmentStatus(i),
  }));
  return {
    ...studentFee,
    status: deriveStudentFeeStatus(studentFee, studentFee.installments),
    installments,
  };
}

async function listStudentFees(instituteId, query) {
  const { studentId, status, page = 1, limit = 20 } = query;

  const where = {
    instituteId,
    ...(studentId ? { studentId } : {}),
  };

  const [rows, total] = await Promise.all([
    prisma.studentFee.findMany({
      where,
      include: {
        installments: { orderBy: { installmentNumber: 'asc' } },
        student: { select: { id: true, firstName: true, lastName: true, studentCode: true } },
        feeStructure: {
          select: { id: true, name: true, currency: true, feeType: true, coursePaymentMode: true },
        },
      },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.studentFee.count({ where }),
  ]);

  let items = rows.map(serializeStudentFee);
  // OVERDUE is derived, so a status=OVERDUE filter is applied after
  // fetching rather than in the SQL WHERE clause.
  if (status) {
    items = items.filter((i) => i.status === status);
  }

  return { items, total, page, limit };
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
        feeStructure: {
          select: { id: true, name: true, currency: true, feeType: true, coursePaymentMode: true },
        },
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
      feeStructure: {
        select: { id: true, name: true, currency: true, feeType: true, coursePaymentMode: true },
      },
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
