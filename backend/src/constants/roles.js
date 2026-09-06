// Mirrors the Prisma `Role` enum. Kept as a plain JS object (not read from
// Prisma) so middleware/validators can reference it without importing the
// generated client.
const ROLES = Object.freeze({
  SUPER_ADMIN: 'SUPER_ADMIN',
  INSTITUTE_ADMIN: 'INSTITUTE_ADMIN',
  TEACHER: 'TEACHER',
  STUDENT: 'STUDENT',
  PARENT: 'PARENT',
});

const INSTITUTE_STATUS = Object.freeze({
  ACTIVE: 'ACTIVE',
  SUSPENDED: 'SUSPENDED',
});

const RECORD_STATUS = Object.freeze({
  ACTIVE: 'ACTIVE',
  INACTIVE: 'INACTIVE',
});

const GENDER = Object.freeze({
  MALE: 'MALE',
  FEMALE: 'FEMALE',
  OTHER: 'OTHER',
});

const PARENT_RELATIONSHIP = Object.freeze({
  FATHER: 'FATHER',
  MOTHER: 'MOTHER',
  GUARDIAN: 'GUARDIAN',
  OTHER: 'OTHER',
});

const ATTENDANCE_STATUS = Object.freeze({
  PRESENT: 'PRESENT',
  ABSENT: 'ABSENT',
  LATE: 'LATE',
  EXCUSED: 'EXCUSED',
});

const FEE_STRUCTURE_STATUS = Object.freeze({
  ACTIVE: 'ACTIVE',
  INACTIVE: 'INACTIVE',
});

const FEE_TYPE = Object.freeze({
  MONTHLY_FEE: 'MONTHLY_FEE',
  COURSE_FEE: 'COURSE_FEE',
  // Backwards-compatible aliases used by older data/clients.
  MONTHLY: 'MONTHLY_FEE',
  COURSE: 'COURSE_FEE',
});

const COURSE_PAYMENT_MODE = Object.freeze({
  FULL: 'FULL',
  EMI: 'EMI',
  FULL_PAYMENT: 'FULL',
  EMI_PAYMENT: 'EMI',
});

function normalizeFeeType(value) {
  if (value === 'MONTHLY' || value === 'MONTHLY_FEE') return FEE_TYPE.MONTHLY_FEE;
  if (value === 'COURSE' || value === 'COURSE_FEE') return FEE_TYPE.COURSE_FEE;
  return value;
}

function normalizeCoursePaymentMode(value) {
  if (value === 'FULL_PAYMENT') return COURSE_PAYMENT_MODE.FULL;
  if (value === 'EMI_PAYMENT') return COURSE_PAYMENT_MODE.EMI;
  return value;
}

const FEE_STATUS = Object.freeze({
  PENDING: 'PENDING',
  PARTIALLY_PAID: 'PARTIALLY_PAID',
  PAID: 'PAID',
  OVERDUE: 'OVERDUE',
  CANCELLED: 'CANCELLED',
});

const DISCOUNT_TYPE = Object.freeze({
  NONE: 'NONE',
  FIXED: 'FIXED',
  PERCENTAGE: 'PERCENTAGE',
});

const PAYMENT_METHOD = Object.freeze({
  CASH: 'CASH',
  UPI: 'UPI',
  BANK_TRANSFER: 'BANK_TRANSFER',
  CARD: 'CARD',
  OTHER: 'OTHER',
});

const PAYMENT_STATUS = Object.freeze({
  SUCCESS: 'SUCCESS',
  REFUNDED: 'REFUNDED',
});

const TEST_STATUS = Object.freeze({
  DRAFT: 'DRAFT',
  SCHEDULED: 'SCHEDULED',
  COMPLETED: 'COMPLETED',
  PUBLISHED: 'PUBLISHED',
  CANCELLED: 'CANCELLED',
});

const RESULT_STATUS = Object.freeze({
  PASS: 'PASS',
  FAIL: 'FAIL',
});

module.exports = {
  ROLES,
  INSTITUTE_STATUS,
  RECORD_STATUS,
  GENDER,
  PARENT_RELATIONSHIP,
  ATTENDANCE_STATUS,
  FEE_STRUCTURE_STATUS,
  FEE_TYPE,
  COURSE_PAYMENT_MODE,
  normalizeFeeType,
  normalizeCoursePaymentMode,
  FEE_STATUS,
  DISCOUNT_TYPE,
  PAYMENT_METHOD,
  PAYMENT_STATUS,
  TEST_STATUS,
  RESULT_STATUS,
};
