const { prisma } = require('../config/prisma');
const { findOwnedOrThrow } = require('../utils/tenant');
const { RECORD_STATUS } = require('../constants/roles');

async function createParent(instituteId, data) {
  return prisma.parent.create({ data: { ...data, instituteId } });
}

async function listParents(instituteId, query) {
  const { q, status, page = 1, limit = 20 } = query;

  const where = {
    instituteId,
    ...(status ? { status } : {}),
    ...(q
      ? {
          OR: [
            { name: { contains: q, mode: 'insensitive' } },
            { email: { contains: q, mode: 'insensitive' } },
            { phone: { contains: q, mode: 'insensitive' } },
          ],
        }
      : {}),
  };

  const [items, total] = await Promise.all([
    prisma.parent.findMany({
      where,
      include: { students: { include: { student: true } } },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.parent.count({ where }),
  ]);

  return { items, total, page, limit };
}

async function getParentById(instituteId, id) {
  return findOwnedOrThrow(prisma.parent, id, instituteId, 'Parent not found', {
    include: { students: { include: { student: true } } },
  });
}

async function updateParent(instituteId, id, data) {
  await findOwnedOrThrow(prisma.parent, id, instituteId, 'Parent not found');
  return prisma.parent.update({ where: { id }, data });
}

async function deactivateParent(instituteId, id) {
  await findOwnedOrThrow(prisma.parent, id, instituteId, 'Parent not found');
  return prisma.parent.update({ where: { id }, data: { status: RECORD_STATUS.INACTIVE } });
}

module.exports = { createParent, listParents, getParentById, updateParent, deactivateParent };
