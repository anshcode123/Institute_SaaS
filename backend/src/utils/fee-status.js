const { toDecimal, isZero } = require('./money');

// The DB only ever stores PENDING / PARTIALLY_PAID / PAID / CANCELLED
// directly (set at write time, when a payment is actually recorded).
// OVERDUE is never persisted - it's purely "still owes money, and the
// due date has passed", computed fresh on every read so it's always
// correct without a cron job or stale cached status.
function deriveInstallmentStatus(installment) {
  if (installment.status === 'CANCELLED' || installment.status === 'PAID') {
    return installment.status;
  }

  const amount = toDecimal(installment.amount);
  const paid = toDecimal(installment.paidAmount);
  const isPastDue = new Date(installment.dueDate) < startOfToday();

  if (paid.greaterThanOrEqualTo(amount) && !isZero(amount)) return 'PAID';
  if (isPastDue) return 'OVERDUE';
  if (paid.greaterThan(0)) return 'PARTIALLY_PAID';
  return 'PENDING';
}

// A StudentFee is OVERDUE if it isn't fully paid/cancelled and at least
// one of its installments is currently overdue.
function deriveStudentFeeStatus(studentFee, installments) {
  if (studentFee.status === 'CANCELLED' || studentFee.status === 'PAID') {
    return studentFee.status;
  }
  const anyOverdue = installments.some((i) => deriveInstallmentStatus(i) === 'OVERDUE');
  if (anyOverdue) return 'OVERDUE';
  return studentFee.status;
}

function startOfToday() {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
}

module.exports = { deriveInstallmentStatus, deriveStudentFeeStatus, startOfToday };
