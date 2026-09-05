-- Additive Phase 5 fee classification. Existing rows retain their data and
-- receive the backwards-compatible MONTHLY classification.
CREATE TYPE "FeeType" AS ENUM ('MONTHLY', 'COURSE');
CREATE TYPE "CoursePaymentMode" AS ENUM ('FULL', 'EMI');

ALTER TABLE "fee_structures"
  ADD COLUMN "feeType" "FeeType" NOT NULL DEFAULT 'MONTHLY',
  ADD COLUMN "coursePaymentMode" "CoursePaymentMode";
