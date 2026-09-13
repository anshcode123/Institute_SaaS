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

const { ROLES } = require('../constants/roles');
const { ValidationError, ConflictError } = require('../utils/app-error');
const { hashPassword, generateTempPassword } = require('../utils/password');

async function getParentById(instituteId, id) {
  const parent = await findOwnedOrThrow(prisma.parent, id, instituteId, 'Parent not found', {
    include: { students: { include: { student: true } } },
  });

  let hasLogin = false;
  let loginEmail = null;
  if (parent.email) {
    const user = await prisma.user.findFirst({
      where: { instituteId, email: parent.email, role: ROLES.PARENT },
      select: { id: true, email: true },
    });
    if (user) {
      hasLogin = true;
      loginEmail = user.email;
    }
  }

  return { ...parent, hasLogin, loginEmail };
}

async function createParentLogin(instituteId, parentId, data = {}) {
  const parent = await findOwnedOrThrow(prisma.parent, parentId, instituteId, 'Parent not found');

  const loginId = (data.loginId && data.loginId.trim()) || parent.email || `${(parent.phone || parent.id.substring(0, 8)).toLowerCase()}@parent.local`;
  const plainPassword = (data.password && data.password.trim()) || generateTempPassword();
  const passwordHash = await hashPassword(plainPassword);

  if (parent.email) {
    const existing = await prisma.user.findFirst({
      where: { instituteId, email: parent.email, role: ROLES.PARENT },
    });
    if (existing) {
      throw new ConflictError('This parent already has a login account');
    }
  }

  try {
    const user = await prisma.$transaction(async (tx) => {
      const created = await tx.user.create({
        data: {
          instituteId,
          name: parent.name,
          email: loginId,
          passwordHash,
          role: ROLES.PARENT,
        },
      });
      if (parent.email !== loginId) {
        await tx.parent.update({ where: { id: parentId }, data: { email: loginId } });
      }
      return created;
    });

    return { userId: user.id, email: user.email, initialPassword: plainPassword };
  } catch (err) {
    if (err.code === 'P2002') {
      throw new ConflictError('A login with that email/ID already exists');
    }
    throw err;
  }
}

async function resetParentPassword(instituteId, parentId, data = {}) {
  const parent = await findOwnedOrThrow(prisma.parent, parentId, instituteId, 'Parent not found');

  if (!parent.email) {
    throw new ValidationError('Parent does not have an email/login account');
  }

  const user = await prisma.user.findFirst({
    where: { instituteId, email: parent.email, role: ROLES.PARENT },
  });

  if (!user) {
    throw new ValidationError('No login account found for this parent');
  }

  const newPlainPassword = (data.newPassword && data.newPassword.trim()) || generateTempPassword();
  const passwordHash = await hashPassword(newPlainPassword);

  await prisma.user.update({
    where: { id: user.id },
    data: { passwordHash },
  });

  return { email: user.email, newPassword: newPlainPassword };
}

async function updateParent(instituteId, id, data) {
  await findOwnedOrThrow(prisma.parent, id, instituteId, 'Parent not found');
  return prisma.parent.update({ where: { id }, data });
}

async function deactivateParent(instituteId, id) {
  await findOwnedOrThrow(prisma.parent, id, instituteId, 'Parent not found');
  return prisma.parent.update({ where: { id }, data: { status: RECORD_STATUS.INACTIVE } });
}

module.exports = {
  createParent,
  listParents,
  getParentById,
  updateParent,
  deactivateParent,
  createParentLogin,
  resetParentPassword,
};
