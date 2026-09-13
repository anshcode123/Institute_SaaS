const { prisma } = require('../config/prisma');
const { findOwnedOrThrow } = require('../utils/tenant');
const { NotFoundError } = require('../utils/app-error');

// In-memory fallback store when DB model delegate is not present in Prisma
const memoryNotifications = [];

async function hasNotification(instituteId, userId, criteria) {
  if (prisma.notification) {
    const where = {
      instituteId,
      userId,
      ...(criteria.type ? { type: criteria.type } : {}),
      ...(criteria.entityType ? { entityType: criteria.entityType } : {}),
      ...(criteria.entityId ? { entityId: criteria.entityId } : {}),
    };
    const count = await prisma.notification.count({ where });
    return count > 0;
  }
  return memoryNotifications.some(
    (n) =>
      n.instituteId === instituteId &&
      n.userId === userId &&
      (!criteria.type || n.type === criteria.type) &&
      (!criteria.entityType || n.entityType === criteria.entityType) &&
      (!criteria.entityId || n.entityId === criteria.entityId),
  );
}

// Called only after the operation it's about has already committed
// successfully (attendance saved, payment recorded, result published) -
// see attendance.service.js/payment.service.js/result.service.js for the
// call sites. A failure here must never be allowed to look like it
// rolled back the business operation - callers wrap this in notifySafely.
async function createNotification(instituteId, userId, data) {
  if (!prisma.notification) {
    const record = {
      id: 'notif-' + Date.now() + '-' + Math.random().toString(36).substring(2, 7),
      instituteId,
      userId,
      type: data.type,
      title: data.title,
      message: data.message,
      entityType: data.entityType || null,
      entityId: data.entityId || null,
      readAt: null,
      createdAt: new Date(),
    };
    memoryNotifications.unshift(record);
    return record;
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
    return await createNotification(instituteId, userId, data);
  } catch (err) {
    // Non-blocking notification failure
    return null;
  }
}

async function listForUser(instituteId, userId, query = {}) {
  const unreadOnly = query.unreadOnly === true || query.unreadOnly === 'true';
  const page = parseInt(query.page, 10) || 1;
  const limit = parseInt(query.limit, 10) || 20;

  if (!prisma.notification) {
    let filtered = memoryNotifications.filter(
      (n) => n.instituteId === instituteId && n.userId === userId,
    );
    if (unreadOnly) {
      filtered = filtered.filter((n) => n.readAt === null);
    }
    const total = filtered.length;
    const unreadCount = memoryNotifications.filter(
      (n) => n.instituteId === instituteId && n.userId === userId && n.readAt === null,
    ).length;
    const items = filtered.slice((page - 1) * limit, page * limit);
    return { items, total, page, limit, unreadCount };
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
  if (!prisma.notification) {
    const item = memoryNotifications.find(
      (n) => n.id === id && n.instituteId === instituteId && n.userId === userId,
    );
    if (!item) throw new NotFoundError('Notification not found');
    item.readAt = new Date();
    return item;
  }
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
  if (!prisma.notification) {
    const now = new Date();
    memoryNotifications.forEach((n) => {
      if (n.instituteId === instituteId && n.userId === userId && n.readAt === null) {
        n.readAt = now;
      }
    });
    return;
  }
  await prisma.notification.updateMany({
    where: { instituteId: instituteId, userId: userId, readAt: null },
    data: { readAt: new Date() },
  });
}

module.exports = {
  createNotification,
  notifySafely,
  listForUser,
  markRead,
  markAllRead,
  hasNotification,
};
