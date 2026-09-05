const { ForbiddenError, UnauthorizedError } = require('../utils/app-error');

// authorize(ROLES.SUPER_ADMIN) or authorize(ROLES.SUPER_ADMIN, ROLES.INSTITUTE_ADMIN).
// Must run after `authenticate` - reads the role set by the verified token,
// never from anything client-supplied.
function authorize(...allowedRoles) {
  return (req, res, next) => {
    if (!req.auth) {
      throw new UnauthorizedError('Authentication required');
    }
    if (!allowedRoles.includes(req.auth.role)) {
      throw new ForbiddenError('You do not have permission to perform this action');
    }
    next();
  };
}

module.exports = { authorize };
