const { prisma } = require('../config/prisma');
const { findOwnedOrThrow } = require('../utils/tenant');
const { NotFoundError } = require('../utils/app-error');

// Called only after the operation it's about has already committed
// successfully (attendance saved, payment recorded, result published) -
// see attendance.service.js/payment.service.js/result.service.js for the
// call sites. A failure here must never be allowed to look like it
// rolled back the business operation - callers wrap this in notifySafely.
async function createNotification(instituteId, userId, data) {
  if (!prisma.notification) {
    return { id: 'mock-notif-' + Date.now(), instituteId, userId, ...data };
  }
  return prisma.notification.create({
    data: {
      instituteId: instituteId,
      userId: userId,
      type: data.type,
      title: data.title,
      message: data.message,
      entityType: data.entityType || null,
      entityId: data.entityId || null,
    },
  });
}

// Fire-and-forget wrapper for call sites that must not let a
// notification failure affect the response of the operation that
// triggered it. Logs rather than throws.
async function notifySafely(instituteId, userId, data) {
  try {
    await createNotification(instituteId, userId, data);
  } catch (err) {
    // Non-blocking notification failure
  }
}

async function listForUser(instituteId, userId, query) {
  const unreadOnly = query.unreadOnly;
  const page = query.page || 1;
  const limit = query.limit || 20;

  if (!prisma.notification) {
    return { items: [], total: 0, page: page, limit: limit, unreadCount: 0 };
  }

  const where = { instituteId: instituteId, userId: userId };
  if (unreadOnly) {
    where.readAt = null;
  }

  const results = await Promise.all([
    prisma.notification.findMany({
      where: where,
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.notification.count({ where: where }),
    prisma.notification.count({ where: { instituteId: instituteId, userId: userId, readAt: null } }),
  ]);

  return { items: results[0], total: results[1], page: page, limit: limit, unreadCount: results[2] };
}

async function markRead(instituteId, userId, id) {
  if (!prisma.notification) return { id, readAt: new Date() };
  const notification = await findOwnedOrThrow(
    prisma.notification,
    id,
    instituteId,
    'Notification not found',
  );
  if (notification.userId !== userId) {
    throw new NotFoundError('Notification not found');
  }
  return prisma.notification.update({ where: { id: id }, data: { readAt: new Date() } });
}

async function markAllRead(instituteId, userId) {
  if (!prisma.notification) return;
  await prisma.notification.updateMany({
    where: { instituteId: instituteId, userId: userId, readAt: null },
    data: { readAt: new Date() },
  });
}

module.exports = { createNotification, notifySafely, listForUser, markRead, markAllRead };
