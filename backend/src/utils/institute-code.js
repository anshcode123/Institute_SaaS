const CODE_PREFIX = 'P';
const CODE_START = 10001;

// Generates the next sequential "P10001"-style code by looking at the
// highest existing code. Retries on unique-constraint collision (e.g. two
// concurrent creations) rather than assuming this call is race-free.
async function generateNextInstituteCode(prisma) {
  const last = await prisma.institute.findFirst({
    where: { instituteCode: { startsWith: CODE_PREFIX } },
    orderBy: { instituteCode: 'desc' },
    select: { instituteCode: true },
  });

  let nextNumber = CODE_START;
  if (last) {
    const parsed = parseInt(last.instituteCode.slice(CODE_PREFIX.length), 10);
    if (!Number.isNaN(parsed) && parsed + 1 > nextNumber) {
      nextNumber = parsed + 1;
    }
  }

  return `${CODE_PREFIX}${nextNumber}`;
}

module.exports = { generateNextInstituteCode };
