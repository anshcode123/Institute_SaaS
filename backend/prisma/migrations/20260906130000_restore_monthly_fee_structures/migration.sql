-- Additive restoration of fee-structure configuration. This migration never
-- rewrites or deletes existing fee/payment/receipt rows.
CREATE TYPE "MonthlyPricingType" AS ENUM ('SUBJECT_WISE', 'COMBINED');

ALTER TABLE "fee_structures"
  ADD COLUMN "courseId" TEXT,
  ADD COLUMN "monthlyDueDay" INTEGER,
  ADD COLUMN "lateFee" DECIMAL(12,2) NOT NULL DEFAULT 0,
  ADD COLUMN "gracePeriodDays" INTEGER;

ALTER TABLE "fee_structures"
  ADD CONSTRAINT "fee_structures_courseId_fkey"
  FOREIGN KEY ("courseId") REFERENCES "courses"("id") ON DELETE SET NULL ON UPDATE CASCADE;
CREATE INDEX "fee_structures_courseId_idx" ON "fee_structures"("courseId");

-- Existing assignments retain a safe historical start date. New assignments
-- must explicitly supply feeStartDate through the validated API.
ALTER TABLE "student_fees"
  ADD COLUMN "feeStartDate" DATE NOT NULL DEFAULT CURRENT_DATE,
  ADD COLUMN "monthlyFeeGroupId" TEXT;
ALTER TABLE "student_fees" ALTER COLUMN "feeStartDate" DROP DEFAULT;

CREATE TABLE "monthly_fee_groups" (
  "id" TEXT NOT NULL,
  "feeStructureId" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "applicableLevel" TEXT NOT NULL,
  "pricingType" "MonthlyPricingType" NOT NULL,
  "combinedAmount" DECIMAL(12,2),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "monthly_fee_groups_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "monthly_fee_groups_feeStructureId_fkey"
    FOREIGN KEY ("feeStructureId") REFERENCES "fee_structures"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "monthly_fee_groups_feeStructureId_idx" ON "monthly_fee_groups"("feeStructureId");

CREATE TABLE "monthly_fee_group_subjects" (
  "id" TEXT NOT NULL,
  "monthlyFeeGroupId" TEXT NOT NULL,
  "subjectId" TEXT NOT NULL,
  "monthlyAmount" DECIMAL(12,2) NOT NULL,
  CONSTRAINT "monthly_fee_group_subjects_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "monthly_fee_group_subjects_monthlyFeeGroupId_fkey"
    FOREIGN KEY ("monthlyFeeGroupId") REFERENCES "monthly_fee_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "monthly_fee_group_subjects_subjectId_fkey"
    FOREIGN KEY ("subjectId") REFERENCES "subjects"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "monthly_fee_group_subjects_monthlyFeeGroupId_subjectId_key"
  ON "monthly_fee_group_subjects"("monthlyFeeGroupId", "subjectId");
CREATE INDEX "monthly_fee_group_subjects_subjectId_idx" ON "monthly_fee_group_subjects"("subjectId");

ALTER TABLE "student_fees"
  ADD CONSTRAINT "student_fees_monthlyFeeGroupId_fkey"
  FOREIGN KEY ("monthlyFeeGroupId") REFERENCES "monthly_fee_groups"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
CREATE INDEX "student_fees_monthlyFeeGroupId_idx" ON "student_fees"("monthlyFeeGroupId");
