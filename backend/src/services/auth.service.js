const { prisma } = require('../config/prisma');
const { comparePassword } = require('../utils/password');
const { UnauthorizedError, ForbiddenError } = require('../utils/app-error');
const { issueTokenPair } = require('./token.service');
const { ROLES, INSTITUTE_STATUS } = require('../constants/roles');

// Never let a passwordHash leave the service layer.
function toSafeUser(user) {
  const { passwordHash, ...safe } = user;
  return safe;
}

async function superAdminLogin({ email, password }) {
  const user = await prisma.user.findUnique({ where: { email } });

  // Same generic error whether the email doesn't exist or the password is
  // wrong - don't leak which one it was.
  if (!user || user.role !== ROLES.SUPER_ADMIN) {
    throw new UnauthorizedError('Invalid email or password');
  }

  const valid = await comparePassword(password, user.passwordHash);
  if (!valid) {
    throw new UnauthorizedError('Invalid email or password');
  }

  const tokens = await issueTokenPair(user);
  return { user: toSafeUser(user), ...tokens };
}

async function instituteLogin({ instituteCode, password }) {
  // 1. Institute exists
  const institute = await prisma.institute.findUnique({ where: { instituteCode } });
  if (!institute) {
    throw new UnauthorizedError('Invalid institute ID or password');
  }

  // 2. Institute is active
  if (institute.status !== INSTITUTE_STATUS.ACTIVE) {
    throw new ForbiddenError('This institute account is suspended');
  }

  // 3. Institute administrator exists
  const admin = await prisma.user.findFirst({
    where: { instituteId: institute.id, role: ROLES.INSTITUTE_ADMIN },
  });
  if (!admin) {
    throw new UnauthorizedError('Invalid institute ID or password');
  }

  // 4. Password is correct
  const valid = await comparePassword(password, admin.passwordHash);
  if (!valid) {
    throw new UnauthorizedError('Invalid institute ID or password');
  }

  // 5. Account is active - re-checked defensively in case status changed
  // between the read above and now (best-effort, not a lock).
  const freshInstitute = await prisma.institute.findUnique({ where: { id: institute.id } });
  if (!freshInstitute || freshInstitute.status !== INSTITUTE_STATUS.ACTIVE) {
    throw new ForbiddenError('This institute account is suspended');
  }

  const tokens = await issueTokenPair(admin);
  return {
    user: toSafeUser(admin),
    institute: {
      id: institute.id,
      instituteCode: institute.instituteCode,
      name: institute.name,
      status: institute.status,
    },
    ...tokens,
  };
}

async function teacherLogin({ email, password }) {
  const user = await prisma.user.findUnique({ where: { email } });

  // Same generic error whether the email doesn't exist, isn't a teacher
  // account, or the password is wrong.
  if (!user || user.role !== ROLES.TEACHER) {
    throw new UnauthorizedError('Invalid email or password');
  }

  const valid = await comparePassword(password, user.passwordHash);
  if (!valid) {
    throw new UnauthorizedError('Invalid email or password');
  }

  // Institute suspension is also re-checked on every request by
  // `authenticate`, but reject it at login time too rather than issuing
  // tokens that would immediately fail.
  if (user.instituteId) {
    const institute = await prisma.institute.findUnique({ where: { id: user.instituteId } });
    if (!institute || institute.status !== INSTITUTE_STATUS.ACTIVE) {
      throw new ForbiddenError('This institute account is suspended');
    }
  }

  const tokens = await issueTokenPair(user);
  return { user: toSafeUser(user), ...tokens };
}

async function studentLogin({ email, password }) {
  const user = await prisma.user.findUnique({ where: { email } });

  if (!user || user.role !== ROLES.STUDENT) {
    throw new UnauthorizedError('Invalid email or password');
  }

  const valid = await comparePassword(password, user.passwordHash);
  if (!valid) {
    throw new UnauthorizedError('Invalid email or password');
  }

  if (user.instituteId) {
    const institute = await prisma.institute.findUnique({ where: { id: user.instituteId } });
    if (!institute || institute.status !== INSTITUTE_STATUS.ACTIVE) {
      throw new ForbiddenError('This institute account is suspended');
    }
  }

  const tokens = await issueTokenPair(user);
  return { user: toSafeUser(user), ...tokens };
}

async function parentLogin({ email, password }) {
  const user = await prisma.user.findUnique({ where: { email } });

  if (!user || user.role !== ROLES.PARENT) {
    throw new UnauthorizedError('Invalid email or password');
  }

  const valid = await comparePassword(password, user.passwordHash);
  if (!valid) {
    throw new UnauthorizedError('Invalid email or password');
  }

  if (user.instituteId) {
    const institute = await prisma.institute.findUnique({ where: { id: user.instituteId } });
    if (!institute || institute.status !== INSTITUTE_STATUS.ACTIVE) {
      throw new ForbiddenError('This institute account is suspended');
    }
  }

  const tokens = await issueTokenPair(user);
  return { user: toSafeUser(user), ...tokens };
}

module.exports = {
  superAdminLogin,
  instituteLogin,
  teacherLogin,
  studentLogin,
  parentLogin,
  toSafeUser,
};
