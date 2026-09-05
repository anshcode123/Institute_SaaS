const { ValidationError } = require('../utils/app-error');

// validateBody(schema) parses+replaces req.body with the zod-parsed
// (and thus typed/trimmed) result, or throws a 400 with field errors.
function validateBody(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      throw new ValidationError('Validation failed', result.error.flatten().fieldErrors);
    }
    req.body = result.data;
    next();
  };
}

// Same idea for query strings (used by list endpoints: search/filter/paging).
function validateQuery(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.query);
    if (!result.success) {
      throw new ValidationError('Validation failed', result.error.flatten().fieldErrors);
    }
    req.validatedQuery = result.data;
    next();
  };
}

module.exports = { validateBody, validateQuery };
