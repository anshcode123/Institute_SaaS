const { prisma } = require('../config/prisma');
const { generateNextInstituteCode } = require('../utils/institute-code');
const { hashPassword, generateTempPassword } = require('../utils/password');
const { NotFoundError, ConflictError } = require('../utils/app-error');
const { ROLES } = require('../constants/roles');

// Creates an Institute plus its single INSTITUTE_ADMIN user in one
// transaction. The initial password is returned once, in plaintext, to
// the Super Admin - only its hash is ever persisted.
async function createInstitute({ name, email, phone, address, adminName }) {
  const instituteCode = await generateNextInstituteCode(prisma);
  const initialPassword = generateTempPassword();
  const passwordHash = await hashPassword(initialPassword);

  try {
    const institute = await prisma.$transaction(async (tx) => {
      const created = await tx.institute.create({
        data: { instituteCode, name, email, phone, address },
      });

      await tx.user.create({
        data: {
          instituteId: created.id,
          name: adminName,
          role: ROLES.INSTITUTE_ADMIN,
          passwordHash,
        },
      });

      return created;
    });

    return { institute, instituteCode, initialPassword };
  } catch (err) {
    if (err.code === 'P2002') {
      throw new ConflictError('An institute with that email or code already exists');
    }
    throw err;
  }
}

async function listInstitutes() {
  return prisma.institute.findMany({ orderBy: { createdAt: 'desc' } });
}

async function getInstituteById(id) {
  const institute = await prisma.institute.findUnique({ where: { id } });
  if (!institute) {
    throw new NotFoundError('Institute not found');
  }
  return institute;
}

async function updateInstituteStatus(id, status) {
  await getInstituteById(id);
  return prisma.institute.update({ where: { id }, data: { status } });
}

module.exports = { createInstitute, listInstitutes, getInstituteById, updateInstituteStatus };
