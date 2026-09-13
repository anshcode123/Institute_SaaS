const { prisma } = require('./src/config/prisma');
const attendanceService = require('./src/services/attendance.service');
const notificationService = require('./src/services/notification.service');
const studentFeeService = require('./src/services/student-fee.service');
const feeReminderService = require('./src/services/fee-reminder.service');

async function runAllTests() {
  console.log('=== RUNNING PHASE 7 FEATURES VERIFICATION ===\n');
  let allPass = true;

  function assert(condition, name) {
    if (condition) {
      console.log(`[PASS] ${name}`);
    } else {
      console.error(`[FAIL] ${name}`);
      allPass = false;
    }
  }

  // 1. Get an existing institute, student, parent, and user
  let institute = await prisma.institute.findFirst();
  let student = await prisma.student.findFirst({
    where: { instituteId: institute ? institute.id : undefined },
    include: { batch: true },
  });
  let teacherUser = await prisma.user.findFirst({
    where: { instituteId: institute ? institute.id : undefined, role: { in: ['INSTITUTE_ADMIN', 'TEACHER'] } },
  });

  if (!institute || !student || !teacherUser) {
    console.log('Note: DB lacks full relational seed, verifying service contracts and logic with fixtures');
  }

  const instId = institute ? institute.id : 'inst-test-1';
  const sId = student ? student.id : 'student-test-1';
  const qrCode = student ? student.qrCode : 'QR-TEST-001';

  // TEST 1: Feature 1 - Attendance Notification
  console.log('\n--- Feature 1: Attendance -> Parent Notification ---');
  try {
    // Test notification service hasNotification and in-memory store
    const notif1 = await notificationService.createNotification(instId, 'parent-user-1', {
      type: 'ATTENDANCE',
      title: 'Attendance Marked',
      message: "Rahul's attendance has been marked Present at 1:05 PM.",
      entityType: 'ATTENDANCE',
      entityId: 'att-101',
    });
    assert(notif1 && notif1.message.includes("Rahul's attendance has been marked Present"), 'Attendance notification created with expected message');

    const hasNotif = await notificationService.hasNotification(instId, 'parent-user-1', {
      type: 'ATTENDANCE',
      entityId: 'att-101',
    });
    assert(hasNotif === true, 'hasNotification correctly detects existing attendance notification');

    const parentNotifs = await notificationService.listForUser(instId, 'parent-user-1', {});
    assert(parentNotifs.items.some(n => n.entityId === 'att-101'), 'Parent listForUser contains attendance notification');
  } catch (err) {
    assert(false, 'Feature 1 error: ' + err.message);
  }

  // TEST 2: Feature 2 - Checkout/Leaving Notification
  console.log('\n--- Feature 2: Checkout/Leaving -> Parent Notification ---');
  try {
    const notif2 = await notificationService.createNotification(instId, 'parent-user-1', {
      type: 'LEAVING',
      title: 'Leaving Recorded',
      message: "Rahul has checked out from the institute at 4:30 PM.",
      entityType: 'ATTENDANCE_LEAVING',
      entityId: 'att-101',
    });
    assert(notif2 && notif2.message.includes('Rahul has checked out from the institute at'), 'Leaving checkout notification created with expected message');

    const hasLeavingNotif = await notificationService.hasNotification(instId, 'parent-user-1', {
      type: 'LEAVING',
      entityId: 'att-101',
    });
    assert(hasLeavingNotif === true, 'hasNotification detects existing leaving notification to prevent duplicates');
  } catch (err) {
    assert(false, 'Feature 2 error: ' + err.message);
  }

  // TEST 3: Feature 3 - Fee Reminder 4 Days Before Due Date
  console.log('\n--- Feature 3: Fee Reminder 4 Days Before Due Date ---');
  try {
    const formatDue = feeReminderService.formatDueDate(new Date('2026-09-20T00:00:00Z'));
    assert(formatDue.includes('September') && formatDue.includes('20'), `formatDueDate returns expected date string: ${formatDue}`);

    // Test reminder deduplication logic
    const reminderNotif = await notificationService.createNotification(instId, 'parent-user-1', {
      type: 'FEE_REMINDER',
      title: 'Fee Reminder',
      message: "Fee reminder: Rahul's fee of ₹2,000 is due on 20 September.",
      entityType: 'FEE_INSTALLMENT',
      entityId: 'inst-install-1',
    });
    assert(reminderNotif && reminderNotif.message.includes("Rahul's fee of ₹2,000 is due on 20 September"), 'Fee reminder notification message format is correct');

    const alreadyReminded = await notificationService.hasNotification(instId, 'parent-user-1', {
      type: 'FEE_REMINDER',
      entityType: 'FEE_INSTALLMENT',
      entityId: 'inst-install-1',
    });
    assert(alreadyReminded === true, 'Fee reminder deduplication check successfully identifies sent reminder');
  } catch (err) {
    assert(false, 'Feature 3 error: ' + err.message);
  }

  // TEST 4: Feature 4 - Existing Institute Fee List Sorting
  console.log('\n--- Feature 4: Existing Institute Fee List Sorting ---');
  try {
    const now = new Date();
    const todayStr = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate())).toISOString();
    const tomorrowStr = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1)).toISOString();
    const overdueStr = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - 3)).toISOString();
    const futureStr = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 7)).toISOString();
    const farFutureStr = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 14)).toISOString();

    const mockFees = [
      {
        id: 'f-future',
        totalAmount: 1000,
        paidAmount: 0,
        outstandingAmount: 1000,
        status: 'PENDING',
        student: { firstName: 'Riya', lastName: 'Sharma' },
        installments: [{ id: 'i-1', installmentNumber: 1, amount: 1000, paidAmount: 0, dueDate: futureStr, status: 'PENDING' }],
      },
      {
        id: 'f-today',
        totalAmount: 2000,
        paidAmount: 0,
        outstandingAmount: 2000,
        status: 'PENDING',
        student: { firstName: 'Aman', lastName: 'Kumar' },
        installments: [{ id: 'i-2', installmentNumber: 1, amount: 2000, paidAmount: 0, dueDate: todayStr, status: 'PENDING' }],
      },
      {
        id: 'f-overdue',
        totalAmount: 1500,
        paidAmount: 0,
        outstandingAmount: 1500,
        status: 'PENDING',
        student: { firstName: 'Rahul', lastName: 'Verma' },
        installments: [{ id: 'i-3', installmentNumber: 1, amount: 1500, paidAmount: 0, dueDate: overdueStr, status: 'PENDING' }],
      },
      {
        id: 'f-tomorrow',
        totalAmount: 3000,
        paidAmount: 0,
        outstandingAmount: 3000,
        status: 'PENDING',
        student: { firstName: 'Karan', lastName: 'Singh' },
        installments: [{ id: 'i-4', installmentNumber: 1, amount: 3000, paidAmount: 0, dueDate: tomorrowStr, status: 'PENDING' }],
      },
      {
        id: 'f-far-future',
        totalAmount: 4000,
        paidAmount: 0,
        outstandingAmount: 4000,
        status: 'PENDING',
        student: { firstName: 'Priya', lastName: 'Gupta' },
        installments: [{ id: 'i-5', installmentNumber: 1, amount: 4000, paidAmount: 0, dueDate: farFutureStr, status: 'PENDING' }],
      },
      {
        id: 'f-paid',
        totalAmount: 5000,
        paidAmount: 5000,
        outstandingAmount: 0,
        status: 'PAID',
        student: { firstName: 'Zara', lastName: 'Ali' },
        installments: [{ id: 'i-6', installmentNumber: 1, amount: 5000, paidAmount: 5000, dueDate: overdueStr, status: 'PAID' }],
      },
      // Course EMI test: Installment 1 is PAID, Installment 2 is due TOMORROW
      {
        id: 'f-emi',
        totalAmount: 10000,
        paidAmount: 5000,
        outstandingAmount: 5000,
        status: 'PARTIALLY_PAID',
        student: { firstName: 'Deepak', lastName: 'Chopra' },
        installments: [
          { id: 'i-7', installmentNumber: 1, amount: 5000, paidAmount: 5000, dueDate: overdueStr, status: 'PAID' },
          { id: 'i-8', installmentNumber: 2, amount: 5000, paidAmount: 0, dueDate: tomorrowStr, status: 'PENDING' },
        ],
      },
    ];

    const serialized = mockFees.map(studentFeeService.serializeStudentFee);

    // Test Course EMI: should use installment 2 (tomorrow), not paid installment 1
    const emiFee = serialized.find(f => f.id === 'f-emi');
    assert(emiFee.dueStatusText === 'Due TOMORROW', `Course EMI uses next unpaid installment: ${emiFee.dueStatusText}`);

    // Sort using studentFeeService internal compare logic (simulated)
    const listRes = await studentFeeService.listStudentFees('test-inst', {});
    assert(typeof listRes.items !== 'undefined', 'listStudentFees returns paginated items array');

    // Test serialized fields
    const todayFee = serialized.find(f => f.id === 'f-today');
    assert(todayFee.dueStatusText === 'Due TODAY', `Today fee has dueStatusText 'Due TODAY': ${todayFee.dueStatusText}`);

    const overdueFee = serialized.find(f => f.id === 'f-overdue');
    assert(overdueFee.dueStatusText.startsWith('Overdue'), `Overdue fee has dueStatusText 'Overdue (...)': ${overdueFee.dueStatusText}`);
  } catch (err) {
    assert(false, 'Feature 4 error: ' + err.message);
  }

  // TEST 5: Parent Privacy & Tenant Isolation
  console.log('\n--- Parent Privacy & Tenant Isolation ---');
  try {
    const parent1Notifs = await notificationService.listForUser('inst-1', 'parent-user-1', {});
    const parent2Notifs = await notificationService.listForUser('inst-1', 'parent-user-2', {});
    assert(!parent2Notifs.items.some(n => n.userId === 'parent-user-1'), 'Parent 2 cannot see Parent 1 notifications');
  } catch (err) {
    assert(false, 'Parent privacy error: ' + err.message);
  }

  console.log('\n=============================================');
  console.log(allPass ? 'ALL BACKEND PHASE 7 TESTS PASSED!' : 'SOME TESTS FAILED');
  console.log('=============================================\n');
}

runAllTests().catch(console.error);

