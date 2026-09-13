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

const ANNOUNCEMENT_AUDIENCE = Object.freeze({
  ALL: 'ALL',
  TEACHERS: 'TEACHERS',
  STUDENTS: 'STUDENTS',
  PARENTS: 'PARENTS',
  BATCH: 'BATCH',
});

const ANNOUNCEMENT_STATUS = Object.freeze({
  DRAFT: 'DRAFT',
  PUBLISHED: 'PUBLISHED',
  ARCHIVED: 'ARCHIVED',
});

module.exports = {
  ROLES,
  INSTITUTE_STATUS,
  RECORD_STATUS,
  GENDER,
  PARENT_RELATIONSHIP,
  ATTENDANCE_STATUS,
  FEE_STRUCTURE_STATUS,
  FEE_STATUS,
  DISCOUNT_TYPE,
  PAYMENT_METHOD,
  PAYMENT_STATUS,
  TEST_STATUS,
  RESULT_STATUS,
  ANNOUNCEMENT_AUDIENCE,
  ANNOUNCEMENT_STATUS,
};
