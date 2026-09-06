const { prisma } = require('../config/prisma');
const { findOwnedOrThrow } = require('../utils/tenant');
const { ValidationError } = require('../utils/app-error');
const { toDecimal, add } = require('../utils/money');
const { FEE_TYPE, COURSE_PAYMENT_MODE, normalizeFeeType, normalizeCoursePaymentMode } = require('../constants/roles');

async function createFeeStructure(instituteId, actorUserId, data) {
  const { batchId, installments = [], ...rest } = data;
  const normalizedFeeType = normalizeFeeType(rest.feeType);
  const normalizedCoursePaymentMode = normalizeCoursePaymentMode(rest.coursePaymentMode);

  if (batchId) {
    await findOwnedOrThrow(prisma.batch, batchId, instituteId, 'Batch not found');
  }

  const isCourseFee = normalizedFeeType === FEE_TYPE.COURSE_FEE;
  if (isCourseFee && !normalizedCoursePaymentMode) {
    throw new ValidationError('coursePaymentMode is required for COURSE fees');
  }
  if (!isCourseFee && normalizedCoursePaymentMode) {
    throw new ValidationError('coursePaymentMode is only valid for COURSE fees');
  }
  if (isCourseFee && installments.length === 0) {
    throw new ValidationError('At least one installment is required for COURSE fees');
  }

  if (installments.length > 0) {
    const sum = installments.reduce((acc, i) => add(acc, i.amount), toDecimal(0));
    if (!sum.equals(toDecimal(rest.totalAmount))) {
      throw new ValidationError('Installment amounts must sum to the total amount');
    }
  }

  if (isCourseFee && normalizedCoursePaymentMode === COURSE_PAYMENT_MODE.FULL && installments.length !== 1) {
    throw new ValidationError('COURSE FULL fees require exactly one installment');
  }
  if (isCourseFee && normalizedCoursePaymentMode === COURSE_PAYMENT_MODE.EMI && installments.length < 2) {
    throw new ValidationError('COURSE EMI fees require at least two installments');
  }

  return prisma.$transaction(async (tx) => {
    const structure = await tx.feeStructure.create({
      data: {
        ...rest,
        feeType: normalizedFeeType,
        coursePaymentMode: isCourseFee ? normalizedCoursePaymentMode : null,
        instituteId,
        batchId: batchId ?? null,
        createdById: actorUserId,
      },
    });

    if (installments.length > 0) {
      await tx.feeStructureInstallment.createMany({
        data: installments.map((i) => ({
          feeStructureId: structure.id,
          installmentNumber: i.installmentNumber,
          amount: i.amount,
          dueDate: i.dueDate,
        })),
      });
    }

    return tx.feeStructure.findUnique({
      where: { id: structure.id },
      include: { installments: { orderBy: { installmentNumber: 'asc' } } },
    });
  });
}

async function listFeeStructures(instituteId, query) {
  const { status, batchId, page = 1, limit = 20 } = query;

  const where = {
    instituteId,
    ...(status ? { status } : {}),
    ...(batchId ? { batchId } : {}),
  };

  const [items, total] = await Promise.all([
    prisma.feeStructure.findMany({
      where,
      include: {
        installments: { orderBy: { installmentNumber: 'asc' } },
        batch: { select: { id: true, name: true } },
      },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.feeStructure.count({ where }),
  ]);

  return { items, total, page, limit };
}

async function getFeeStructureById(instituteId, id) {
  return findOwnedOrThrow(prisma.feeStructure, id, instituteId, 'Fee structure not found', {
    include: {
      installments: { orderBy: { installmentNumber: 'asc' } },
      batch: { select: { id: true, name: true } },
    },
  });
}

// Deliberately limited to name/description/status. totalAmount and the
// installment schedule are NOT editable after creation - StudentFee rows
// snapshot their numbers at assignment time, so allowing that here would
// silently desync already-assigned students from the "current" template.
async function updateFeeStructure(instituteId, id, data) {
  await findOwnedOrThrow(prisma.feeStructure, id, instituteId, 'Fee structure not found');
  return prisma.feeStructure.update({ where: { id }, data });
}

module.exports = {
  createFeeStructure,
  listFeeStructures,
  getFeeStructureById,
  updateFeeStructure,
};
