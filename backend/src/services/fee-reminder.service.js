const { prisma } = require('../config/prisma');
const { notifySafely, hasNotification } = require('./notification.service');
const { toDecimal, subtract } = require('../utils/money');

function formatDueDate(d) {
  const date = new Date(d);
  return date.toLocaleDateString('en-US', { day: 'numeric', month: 'long', timeZone: 'UTC' });
}

function getStartAndEndOfDayUTC(daysAhead = 4) {
  const now = new Date();
  const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + daysAhead, 0, 0, 0, 0));
  const end = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + daysAhead, 23, 59, 59, 999));
  return { start, end };
}

/**
 * Checks for outstanding fees due in exactly targetDaysAhead (default: 4 days)
 * and dispatches parent portal notifications with deduplication.
 */
async function sendDueFeeReminders(daysAhead = 4) {
  const { start, end } = getStartAndEndOfDayUTC(daysAhead);
  let remindersSent = 0;

  try {
    const installments = await prisma.feeInstallment.findMany({
      where: {
        dueDate: {
          gte: start,
          lte: end,
        },
        status: {
          notIn: ['PAID', 'CANCELLED'],
        },
        studentFee: {
          status: {
            notIn: ['PAID', 'CANCELLED'],
          },
        },
      },
      include: {
        studentFee: {
          include: {
            student: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                instituteId: true,
                status: true,
              },
            },
            feeStructure: {
              select: {
                name: true,
                feeType: true,
                currency: true,
              },
            },
          },
        },
      },
    });

    for (const installment of installments) {
      const studentFee = installment.studentFee;
      if (!studentFee || !studentFee.student) continue;

      const student = studentFee.student;
      const instituteId = installment.instituteId;

      // Ensure amount still outstanding on this installment
      const installmentAmount = toDecimal(installment.amount);
      const paidAmount = toDecimal(installment.paidAmount);
      const remaining = subtract(installmentAmount, paidAmount);

      if (remaining.lessThanOrEqualTo(0)) {
        continue;
      }

      const formattedAmount = Number(remaining.toString()).toLocaleString('en-IN');
      const formattedDate = formatDueDate(installment.dueDate);
      const message = `Fee reminder: ${student.firstName}'s fee of ₹${formattedAmount} is due on ${formattedDate}.`;

      // Find all linked parents with active login accounts
      const links = await prisma.studentParent.findMany({
        where: { studentId: student.id },
        include: { parent: { select: { email: true } } },
      });

      for (const link of links) {
        const parent = link.parent;
        if (!parent || !parent.email) continue;

        const parentUser = await prisma.user.findFirst({
          where: { instituteId: instituteId, email: parent.email, role: 'PARENT' },
          select: { id: true },
        });

        if (!parentUser) continue;

        // Prevent duplicate reminders for this installment
        const alreadySent = await hasNotification(instituteId, parentUser.id, {
          type: 'FEE_REMINDER',
          entityType: 'FEE_INSTALLMENT',
          entityId: installment.id,
        });

        if (alreadySent) {
          continue;
        }

        await notifySafely(instituteId, parentUser.id, {
          type: 'FEE_REMINDER',
          title: 'Fee Reminder',
          message: message,
          entityType: 'FEE_INSTALLMENT',
          entityId: installment.id,
        });

        remindersSent++;
      }
    }
  } catch (err) {
    console.error('[fee-reminder] Error while processing 4-day fee reminders:', err);
  }

  return { remindersSent };
}

let reminderTimer = null;

function startFeeReminderScheduler() {
  if (reminderTimer) return;

  // Run once safely shortly after startup
  setTimeout(() => {
    sendDueFeeReminders(4).catch((err) => {
      console.error('[fee-reminder] Initial scheduler run error:', err);
    });
  }, 10000);

  // Run once every 24 hours
  const TWENTY_FOUR_HOURS = 24 * 60 * 60 * 1000;
  reminderTimer = setInterval(() => {
    sendDueFeeReminders(4).catch((err) => {
      console.error('[fee-reminder] Daily scheduler run error:', err);
    });
  }, TWENTY_FOUR_HOURS);

  if (reminderTimer.unref) {
    reminderTimer.unref();
  }

  console.log('[fee-reminder] 4-day fee reminder scheduler initialized');
}

function stopFeeReminderScheduler() {
  if (reminderTimer) {
    clearInterval(reminderTimer);
    reminderTimer = null;
  }
}

module.exports = {
  sendDueFeeReminders,
  startFeeReminderScheduler,
  stopFeeReminderScheduler,
  formatDueDate,
};

