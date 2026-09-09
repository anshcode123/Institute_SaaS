// Generates "ST10001" / "PR10001" style globally-unique portal login
// ids - same retry-on-collision pattern as institute-code.js. Global
// (not per-institute) because a login identifier has to be unique across
// the whole SaaS, the same way instituteCode is - studentCode is only
// unique per-institute and is not suitable as a login key on its own.
var START_SEQ = 10001;

async function generateNextPortalLoginId(model, prefix) {
  var last = await model.findFirst({
    where: { portalLoginId: { startsWith: prefix } },
    orderBy: { portalLoginId: 'desc' },
    select: { portalLoginId: true },
  });

  var next = START_SEQ;
  if (last && last.portalLoginId) {
    var parsed = parseInt(last.portalLoginId.slice(prefix.length), 10);
    if (!isNaN(parsed) && parsed + 1 > next) {
      next = parsed + 1;
    }
  }

  return prefix + next;
}

async function generateStudentPortalLoginId(prisma) {
  return generateNextPortalLoginId(prisma.student, 'ST');
}

async function generateParentPortalLoginId(prisma) {
  return generateNextPortalLoginId(prisma.parent, 'PR');
}

module.exports = {
  generateStudentPortalLoginId: generateStudentPortalLoginId,
  generateParentPortalLoginId: generateParentPortalLoginId,
};
