const { prisma } = require('../config/prisma');
const { findOwnedOrThrow } = require('../utils/tenant');
const { ValidationError } = require('../utils/app-error');
const { toDecimal, add } = require('../utils/money');

const structureInclude = {
  installments: { orderBy: { installmentNumber: 'asc' } },
  batch: { select: { id: true, name: true } },
  course: { select: { id: true, name: true } },
  monthlyGroups: { include: { subjectPrices: { include: { subject: { select: { id: true, name: true } } } } } },
};

function monthlyGroupTotal(group) {
  return group.pricingType === 'COMBINED'
    ? toDecimal(group.combinedAmount)
    : group.subjects.reduce((sum, subject) => add(sum, subject.monthlyAmount), toDecimal(0));
}

async function createFeeStructure(instituteId, actorUserId, data) {
  if (data.batchId) await findOwnedOrThrow(prisma.batch, data.batchId, instituteId, 'Batch not found');
  if (data.feeType === 'COURSE') {
    await findOwnedOrThrow(prisma.course, data.courseId, instituteId, 'Course not found');
    if (data.coursePaymentMode === 'EMI') {
      const sum = data.installments.reduce((acc, item) => add(acc, item.amount), toDecimal(0));
      if (!sum.equals(toDecimal(data.totalAmount))) throw new ValidationError('EMI amounts must sum to the final payable amount');
    }
  } else {
    const subjectIds = data.monthlyGroups.flatMap((group) => group.subjects?.map((subject) => subject.subjectId) ?? []);
    if (subjectIds.length) {
      const count = await prisma.subject.count({ where: { id: { in: subjectIds }, instituteId } });
      if (count !== subjectIds.length) throw new ValidationError('One or more subjects are invalid for this institute');
    }
  }

  const totalAmount = data.feeType === 'MONTHLY'
    ? data.monthlyGroups.map(monthlyGroupTotal).reduce((largest, total) => total.greaterThan(largest) ? total : largest, toDecimal(0))
    : toDecimal(data.totalAmount);

  const structure = await prisma.$transaction(async (tx) => {
    const created = await tx.feeStructure.create({
      data: {
        name: data.name, description: data.description ?? null, currency: data.currency ?? 'INR', batchId: data.batchId ?? null,
        instituteId, createdById: actorUserId, feeType: data.feeType, totalAmount,
        ...(data.feeType === 'MONTHLY'
          ? { monthlyDueDay: data.monthlyDueDay, lateFee: data.lateFee ?? '0', gracePeriodDays: data.gracePeriodDays ?? null }
          : { courseId: data.courseId, coursePaymentMode: data.coursePaymentMode }),
      },
    });
    if (data.feeType === 'COURSE' && data.coursePaymentMode === 'EMI') {
      await tx.feeStructureInstallment.createMany({ data: data.installments.map((item) => ({ feeStructureId: created.id, installmentNumber: item.installmentNumber, amount: item.amount, dueDate: item.dueDate })) });
    }
    if (data.feeType === 'MONTHLY') {
      for (const group of data.monthlyGroups) {
        const savedGroup = await tx.monthlyFeeGroup.create({ data: { feeStructureId: created.id, name: group.name, applicableLevel: group.applicableLevel, pricingType: group.pricingType, combinedAmount: group.pricingType === 'COMBINED' ? group.combinedAmount : null } });
        if (group.pricingType === 'SUBJECT_WISE') await tx.monthlyFeeGroupSubject.createMany({ data: group.subjects.map((subject) => ({ monthlyFeeGroupId: savedGroup.id, subjectId: subject.subjectId, monthlyAmount: subject.monthlyAmount })) });
      }
    }
    return created.id;
  });
  return prisma.feeStructure.findUnique({ where: { id: structure }, include: structureInclude });
}

async function listFeeStructures(instituteId, query) {
  const { status, batchId, page = 1, limit = 20 } = query;
  const where = { instituteId, ...(status ? { status } : {}), ...(batchId ? { batchId } : {}) };
  const [items, total] = await Promise.all([prisma.feeStructure.findMany({ where, include: structureInclude, orderBy: { createdAt: 'desc' }, skip: (page - 1) * limit, take: limit }), prisma.feeStructure.count({ where })]);
  return { items, total, page, limit };
}

async function getFeeStructureById(instituteId, id) { return findOwnedOrThrow(prisma.feeStructure, id, instituteId, 'Fee structure not found', { include: structureInclude }); }
async function updateFeeStructure(instituteId, id, data) { await findOwnedOrThrow(prisma.feeStructure, id, instituteId, 'Fee structure not found'); return prisma.feeStructure.update({ where: { id }, data }); }
module.exports = { createFeeStructure, listFeeStructures, getFeeStructureById, updateFeeStructure };
