const { Prisma } = require('@prisma/client');

const { Decimal } = Prisma;

// Every authoritative money calculation in the backend goes through
// these - never plain JS `+`/`-`/`*` on amounts, which can silently
// misround currency values. Accepts Decimal, string, or number and
// always returns a Decimal.
function toDecimal(value) {
  if (value instanceof Decimal) return value;
  return new Decimal(value ?? 0);
}

function add(a, b) {
  return toDecimal(a).plus(toDecimal(b));
}

function subtract(a, b) {
  return toDecimal(a).minus(toDecimal(b));
}

function multiply(a, b) {
  return toDecimal(a).times(toDecimal(b));
}

function divide(a, b) {
  return toDecimal(a).dividedBy(toDecimal(b));
}

function isPositive(value) {
  return toDecimal(value).greaterThan(0);
}

function isNegative(value) {
  return toDecimal(value).lessThan(0);
}

function isZero(value) {
  return toDecimal(value).isZero();
}

function greaterThan(a, b) {
  return toDecimal(a).greaterThan(toDecimal(b));
}

function lessThanOrEqual(a, b) {
  return toDecimal(a).lessThanOrEqualTo(toDecimal(b));
}

// Rounds to 2 decimal places (currency precision) using standard
// half-up rounding - used when distributing a discount proportionally
// across installments, where naive division produces long decimals.
function round2(value) {
  return toDecimal(value).toDecimalPlaces(2, Decimal.ROUND_HALF_UP);
}

module.exports = {
  Decimal,
  toDecimal,
  add,
  subtract,
  multiply,
  divide,
  isPositive,
  isNegative,
  isZero,
  greaterThan,
  lessThanOrEqual,
  round2,
};
