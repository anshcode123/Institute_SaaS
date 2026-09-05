const { prisma } = require('../config/prisma');
const { toDecimal, add } = require('../utils/money');
const { startOfToday } = require('../utils/fee-status');
const { FEE_STATUS } = require('../constants/roles');

async function getDashboardSummary(instituteId) {
  const fees = await prisma.studentFee.findMany({
    where: { instituteId, status: { not: FEE_STATUS.CANCELLED } },
    select: { finalAmount: true, paidAmount: true, outstandingAmount: true },
  });

  const totals = fees.reduce(
    (acc, fee) => ({
      totalFees: add(acc.totalFees, fee.finalAmount),
      collected: add(acc.collected, fee.paidAmount),
      outstanding: add(acc.outstanding, fee.outstandingAmount),
    }),
    { totalFees: toDecimal(0), collected: toDecimal(0), outstanding: toDecimal(0) },
  );

  // Overdue = sum of (amount - paidAmount) across installments that are
  // still unpaid/partially paid and past their due date - the same
  // definition used by deriveInstallmentStatus, computed institute-wide
  // here rather than row-by-row on each fee's detail view.
  const overdueInstallments = await prisma.feeInstallment.findMany({
    where: {
      instituteId,
      status: { in: [FEE_STATUS.PENDING, FEE_STATUS.PARTIALLY_PAID] },
      dueDate: { lt: startOfToday() },
    },
    select: { amount: true, paidAmount: true },
  });
  const overdue = overdueInstallments.reduce(
    (acc, i) => add(acc, toDecimal(i.amount).minus(toDecimal(i.paidAmount))),
    toDecimal(0),
  );

  return {
    totalFees: totals.totalFees,
    collected: totals.collected,
    outstanding: totals.outstanding,
    overdue,
  };
}

module.exports = { getDashboardSummary };
