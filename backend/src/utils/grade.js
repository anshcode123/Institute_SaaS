const { toDecimal } = require('./money');

// Single source of truth for grade boundaries. If the institute ever
// needs configurable grading, this is the one place to change - no
// controller/service should ever compute a grade inline.
const GRADE_BANDS = [
  { min: 90, grade: 'A+' },
  { min: 80, grade: 'A' },
  { min: 70, grade: 'B+' },
  { min: 60, grade: 'B' },
  { min: 50, grade: 'C' },
  { min: 40, grade: 'D' },
  { min: 0, grade: 'F' },
];

// percentage is a Decimal (or decimal-like string/number) - compared
// with Decimal, not float, so a boundary like exactly 90.00 lands in the
// correct band without float rounding risk.
function calculateGrade(percentage) {
  const pct = toDecimal(percentage);
  for (const band of GRADE_BANDS) {
    if (pct.greaterThanOrEqualTo(band.min)) return band.grade;
  }
  return 'F';
}

// Computes percentage, grade, and pass/fail from raw marks. This is the
// one function every mark-save / publish path calls - never trust a
// percentage/grade/status sent by the client.
//
// Pass rule (spec's preferred default): a student passes only if BOTH
// the overall passing-marks requirement is met AND every individual
// subject's passing-marks requirement is met. This is a fixed policy,
// not per-institute configurable yet - flagged in the README as a
// design decision an institute might want to override later.
function computeResult({ totalMarks, obtainedMarks, passingMarks, subjectResults }) {
  const percentage = toDecimal(obtainedMarks).dividedBy(totalMarks).times(100).toDecimalPlaces(2);
  const grade = calculateGrade(percentage);

  const overallPassed = obtainedMarks >= passingMarks;
  const allSubjectsPassed = subjectResults.every((s) => s.obtainedMarks >= s.passingMarks);
  const status = overallPassed && allSubjectsPassed ? 'PASS' : 'FAIL';

  return { percentage, grade, status };
}

module.exports = { calculateGrade, computeResult, GRADE_BANDS };
