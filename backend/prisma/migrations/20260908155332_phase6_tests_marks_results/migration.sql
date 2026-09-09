-- CreateEnum
CREATE TYPE "TestStatus" AS ENUM ('DRAFT', 'SCHEDULED', 'COMPLETED', 'PUBLISHED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "ResultStatus" AS ENUM ('PASS', 'FAIL');

-- CreateTable
CREATE TABLE "tests" (
    "id" TEXT NOT NULL,
    "instituteId" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "testDate" DATE NOT NULL,
    "durationMinutes" INTEGER,
    "totalMarks" INTEGER NOT NULL,
    "passingMarks" INTEGER NOT NULL,
    "status" "TestStatus" NOT NULL DEFAULT 'DRAFT',
    "createdById" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "tests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "test_subjects" (
    "id" TEXT NOT NULL,
    "testId" TEXT NOT NULL,
    "subjectId" TEXT NOT NULL,
    "maxMarks" INTEGER NOT NULL,
    "passingMarks" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "test_subjects_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "student_subject_marks" (
    "id" TEXT NOT NULL,
    "instituteId" TEXT NOT NULL,
    "testId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "subjectId" TEXT NOT NULL,
    "maxMarks" INTEGER NOT NULL,
    "obtainedMarks" INTEGER NOT NULL,
    "enteredById" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "student_subject_marks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "student_test_results" (
    "id" TEXT NOT NULL,
    "instituteId" TEXT NOT NULL,
    "testId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "totalMarks" INTEGER NOT NULL,
    "obtainedMarks" INTEGER NOT NULL,
    "percentage" DECIMAL(5,2) NOT NULL,
    "grade" TEXT NOT NULL,
    "status" "ResultStatus" NOT NULL,
    "publishedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "student_test_results_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "tests_instituteId_idx" ON "tests"("instituteId");

-- CreateIndex
CREATE INDEX "tests_instituteId_status_idx" ON "tests"("instituteId", "status");

-- CreateIndex
CREATE INDEX "tests_batchId_idx" ON "tests"("batchId");

-- CreateIndex
CREATE UNIQUE INDEX "test_subjects_testId_subjectId_key" ON "test_subjects"("testId", "subjectId");

-- CreateIndex
CREATE INDEX "student_subject_marks_instituteId_idx" ON "student_subject_marks"("instituteId");

-- CreateIndex
CREATE INDEX "student_subject_marks_testId_studentId_idx" ON "student_subject_marks"("testId", "studentId");

-- CreateIndex
CREATE UNIQUE INDEX "student_subject_marks_testId_studentId_subjectId_key" ON "student_subject_marks"("testId", "studentId", "subjectId");

-- CreateIndex
CREATE INDEX "student_test_results_instituteId_idx" ON "student_test_results"("instituteId");

-- CreateIndex
CREATE INDEX "student_test_results_testId_idx" ON "student_test_results"("testId");

-- CreateIndex
CREATE INDEX "student_test_results_studentId_idx" ON "student_test_results"("studentId");

-- CreateIndex
CREATE UNIQUE INDEX "student_test_results_testId_studentId_key" ON "student_test_results"("testId", "studentId");

-- AddForeignKey
ALTER TABLE "tests" ADD CONSTRAINT "tests_instituteId_fkey" FOREIGN KEY ("instituteId") REFERENCES "institutes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tests" ADD CONSTRAINT "tests_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "batches"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tests" ADD CONSTRAINT "tests_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "test_subjects" ADD CONSTRAINT "test_subjects_testId_fkey" FOREIGN KEY ("testId") REFERENCES "tests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "test_subjects" ADD CONSTRAINT "test_subjects_subjectId_fkey" FOREIGN KEY ("subjectId") REFERENCES "subjects"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_subject_marks" ADD CONSTRAINT "student_subject_marks_instituteId_fkey" FOREIGN KEY ("instituteId") REFERENCES "institutes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_subject_marks" ADD CONSTRAINT "student_subject_marks_testId_fkey" FOREIGN KEY ("testId") REFERENCES "tests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_subject_marks" ADD CONSTRAINT "student_subject_marks_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_subject_marks" ADD CONSTRAINT "student_subject_marks_subjectId_fkey" FOREIGN KEY ("subjectId") REFERENCES "subjects"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_subject_marks" ADD CONSTRAINT "student_subject_marks_enteredById_fkey" FOREIGN KEY ("enteredById") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_test_results" ADD CONSTRAINT "student_test_results_instituteId_fkey" FOREIGN KEY ("instituteId") REFERENCES "institutes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_test_results" ADD CONSTRAINT "student_test_results_testId_fkey" FOREIGN KEY ("testId") REFERENCES "tests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_test_results" ADD CONSTRAINT "student_test_results_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;
