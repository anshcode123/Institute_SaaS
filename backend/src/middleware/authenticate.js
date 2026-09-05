const { verifyAccessToken } = require('../utils/jwt');
const { UnauthorizedError, ForbiddenError } = require('../utils/app-error');
const { asyncHandler } = require('./async-handler');
const { prisma } = require('../config/prisma');
const { INSTITUTE_STATUS } = require('../constants/roles');

// Verifies the Bearer access token and attaches a trusted auth context.
// Every downstream handler must read tenant/role info from req.auth -
// NEVER from req.body/req.query/req.params - since those come from the
// client and can't be trusted for authorization or tenant scoping.
const authenticate = asyncHandler(async (req, res, next) => {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    throw new UnauthorizedError('Missing or malformed Authorization header');
  }

  let payload;
  try {
    payload = verifyAccessToken(token);
  } catch {
    throw new UnauthorizedError('Invalid or expired access token');
  }

  req.auth = {
    userId: payload.sub,
    role: payload.role,
    instituteId: payload.instituteId ?? null,
  };

  // Access tokens are short-lived (15m default), but a suspension must
  // still take effect immediately rather than waiting for expiry - so
  // any institute-scoped request re-checks status on every request.
  // SUPER_ADMIN has instituteId = null and is exempt (it isn't tied to
  // any institute). Every other role - INSTITUTE_ADMIN, TEACHER, and
  // future STUDENT/PARENT logins - carries an instituteId and is checked.
  if (req.auth.instituteId) {
    const institute = await prisma.institute.findUnique({
      where: { id: req.auth.instituteId },
      select: { status: true },
    });
    if (!institute || institute.status !== INSTITUTE_STATUS.ACTIVE) {
      throw new ForbiddenError('This institute account is suspended');
    }
  }

  next();
});

module.exports = { authenticate };
