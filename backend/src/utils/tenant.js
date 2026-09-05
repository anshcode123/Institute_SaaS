const { NotFoundError } = require('./app-error');

// Every Phase 3 lookup goes through this: fetch by id AND instituteId in
// the same query, so a cross-tenant id simply doesn't match anything and
// returns 404 - never "found, but you're not allowed to see it" (which
// would confirm the record's existence to another tenant).
async function findOwnedOrThrow(model, id, instituteId, notFoundMessage, extraArgs = {}) {
  const record = await model.findFirst({
    where: { id, instituteId },
    ...extraArgs,
  });
  if (!record) {
    throw new NotFoundError(notFoundMessage);
  }
  return record;
}

module.exports = { findOwnedOrThrow };
