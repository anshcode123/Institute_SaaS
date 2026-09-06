const { prisma } = require('../config/prisma');
const { findOwnedOrThrow } = require('../utils/tenant');
const { ValidationError, NotFoundError } = require('../utils/app-error');
const { toDecimal, add, subtract, greaterThan } = require('../utils/money');
const { generateReceiptNumber } = require('../utils/receipt-number');
const { FEE_STATUS } = require('../constants/roles');

// The full atomic flow from the spec: validate student -> validate fee ->
// validate installment -> validate amount -> create payment -> update
// installment -> update student fee -> generate receipt. Everything from
// "create payment" onward happens in a single Prisma transaction; if any
// step fails, nothing is written - a payment is never created without its
// balance updates, and a balance is never updated without a payment row.
async function recordPayment(instituteId, actorUserId, data) {
  const {
    studentId,
    studentFeeId,
    installmentId,
    amount,
    paymentMethod,
    transactionReference,
    paymentDate,
    notes,
  } = data;

  await findOwnedOrThrow(prisma.student, studentId, instituteId, 'Student not found');

  const studentFee = await findOwnedOrThrow(
    prisma.studentFee,
    studentFeeId,
    instituteId,
    'Student fee not found',
  );
  if (studentFee.studentId !== studentId) {
    // Same message as "not found" - don't confirm that this fee exists
    // but belongs to a different student.
    throw new NotFoundError('Student fee not found');
  }
  if (studentFee.status === FEE_STATUS.CANCELLED) {
    throw new ValidationError('This fee has been cancelled and cannot accept payments');
  }

  const installment = await prisma.feeInstallment.findFirst({
    where: { id: installmentId, instituteId, studentFeeId },
  });
  if (!installment) {
    throw new NotFoundError('Installment not found');
  }

  const paymentAmount = toDecimal(amount);
  const remaining = subtract(installment.amount, installment.paidAmount);

  if (greaterThan(paymentAmount, remaining)) {
    throw new ValidationError(
      `Payment exceeds the remaining amount for this installment (remaining: ${remaining.toFixed(2)})`,
    );
  }

  const previousOutstanding = toDecimal(studentFee.outstandingAmount);

  const result = await prisma.$transaction(async (tx) => {
    const payment = await tx.payment.create({
      data: {
        instituteId,
        studentId,
        studentFeeId,
        installmentId,
        amount: paymentAmount,
        paymentMethod,
        transactionReference: transactionReference ?? null,
        paymentDate: paymentDate ?? new Date(),
        notes: notes ?? null,
        receivedById: actorUserId,
      },
    });

    const newInstallmentPaid = add(installment.paidAmount, paymentAmount);
    const installmentFullyPaid = !greaterThan(installment.amount, newInstallmentPaid);
    await tx.feeInstallment.update({
      where: { id: installmentId },
      data: {
        paidAmount: newInstallmentPaid,
        status: installmentFullyPaid ? FEE_STATUS.PAID : FEE_STATUS.PARTIALLY_PAID,
      },
    });

    const newFeePaid = add(studentFee.paidAmount, paymentAmount);
    const newOutstanding = subtract(studentFee.finalAmount, newFeePaid);
    const feeFullyPaid = !greaterThan(newOutstanding, toDecimal(0));
    await tx.studentFee.update({
      where: { id: studentFeeId },
      data: {
        paidAmount: newFeePaid,
        outstandingAmount: feeFullyPaid ? toDecimal(0) : newOutstanding,
        status: feeFullyPaid
          ? FEE_STATUS.PAID
          : greaterThan(newFeePaid, toDecimal(0))
            ? FEE_STATUS.PARTIALLY_PAID
            : FEE_STATUS.PENDING,
      },
    });

    const receiptNumber = await generateReceiptNumber(tx, instituteId);
    await tx.paymentReceipt.create({
      data: {
        instituteId,
        paymentId: payment.id,
        receiptNumber,
        previousOutstanding,
        remainingOutstanding: feeFullyPaid ? toDecimal(0) : newOutstanding,
      },
    });

    return { payment };
  });

  return getPaymentById(instituteId, result.payment.id);
}

async function listPayments(instituteId, query) {
  const { studentId, studentFeeId, page = 1, limit = 20 } = query;

  const where = {
    instituteId,
    ...(studentId ? { studentId } : {}),
    ...(studentFeeId ? { studentFeeId } : {}),
  };

  const [items, total] = await Promise.all([
    prisma.payment.findMany({
      where,
      include: {
        student: { select: { id: true, firstName: true, lastName: true, studentCode: true } },
        receivedBy: { select: { id: true, name: true, role: true } },
        receipt: true,
        installment: { select: { id: true, installmentNumber: true } },
      },
      orderBy: { paymentDate: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.payment.count({ where }),
  ]);

  return { items, total, page, limit };
}

async function getPaymentById(instituteId, id) {
  return findOwnedOrThrow(prisma.payment, id, instituteId, 'Payment not found', {
    include: {
      student: { select: { id: true, firstName: true, lastName: true, studentCode: true } },
      studentFee: {
        include: { feeStructure: { select: { id: true, name: true, currency: true } } },
      },
      installment: true,
      receivedBy: { select: { id: true, name: true, role: true } },
      receipt: true,
    },
  });
}

async function getReceiptById(instituteId, id) {
  const receipt = await findOwnedOrThrow(prisma.paymentReceipt, id, instituteId, 'Receipt not found', {
    include: {
      payment: {
        include: {
          student: { select: { id: true, firstName: true, lastName: true, studentCode: true } },
          studentFee: {
            include: { feeStructure: { select: { id: true, name: true, currency: true } } },
          },
          installment: true,
          receivedBy: { select: { id: true, name: true, role: true } },
        },
      },
      institute: { select: { id: true, name: true, instituteCode: true } },
    },
  });

  // Parent name, if any, shown on the receipt where available - looked
  // up separately rather than a heavy nested include on every payment list.
  const studentParent = await prisma.studentParent.findFirst({
    where: { studentId: receipt.payment.studentId },
    include: { parent: { select: { name: true } } },
  });

  return { ...receipt, parentName: studentParent?.parent?.name ?? null };
}

module.exports = { recordPayment, listPayments, getPaymentById, getReceiptById };
