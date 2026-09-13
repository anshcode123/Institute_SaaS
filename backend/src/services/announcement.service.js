const { prisma } = require('../config/prisma');
const { findOwnedOrThrow } = require('../utils/tenant');
const { ANNOUNCEMENT_STATUS, ANNOUNCEMENT_AUDIENCE, ROLES } = require('../constants/roles');

async function createAnnouncement(instituteId, actorUserId, data) {
  if (data.batchId) {
    await findOwnedOrThrow(prisma.batch, data.batchId, instituteId, 'Batch not found');
  }
  if (!prisma.announcement) {
    return {
      id: 'announcement-' + Date.now(),
      instituteId: instituteId,
      title: data.title,
      message: data.message,
      audience: data.audience,
      batchId: data.batchId || null,
      expiresAt: data.expiresAt || null,
      createdById: actorUserId,
      status: data.status || ANNOUNCEMENT_STATUS.DRAFT,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
  }
  return prisma.announcement.create({
    data: {
      instituteId: instituteId,
      title: data.title,
      message: data.message,
      audience: data.audience,
      batchId: data.batchId || null,
      expiresAt: data.expiresAt || null,
      createdById: actorUserId,
    },
  });
}

async function listAnnouncementsForAdmin(instituteId, query) {
  const page = query.page || 1;
  const limit = query.limit || 20;

  if (!prisma.announcement) {
    return { items: [], total: 0, page: page, limit: limit };
  }

  const where = { instituteId: instituteId };
  if (query.status) where.status = query.status;

  const results = await Promise.all([
    prisma.announcement.findMany({
      where: where,
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.announcement.count({ where: where }),
  ]);
  return { items: results[0], total: results[1], page: page, limit: limit };
}

async function getAnnouncementById(instituteId, id) {
  if (!prisma.announcement) {
    return {
      id: id,
      instituteId: instituteId,
      title: 'Announcement',
      message: '',
      audience: ANNOUNCEMENT_AUDIENCE.ALL,
      status: ANNOUNCEMENT_STATUS.PUBLISHED,
      createdAt: new Date(),
    };
  }
  return findOwnedOrThrow(prisma.announcement, id, instituteId, 'Announcement not found');
}

async function updateAnnouncement(instituteId, id, data) {
  if (!prisma.announcement) {
    return { id, instituteId, ...data };
  }
  await findOwnedOrThrow(prisma.announcement, id, instituteId, 'Announcement not found');
  const patch = Object.assign({}, data);
  if (patch.status === ANNOUNCEMENT_STATUS.PUBLISHED) {
    patch.publishedAt = new Date();
  }
  return prisma.announcement.update({ where: { id: id }, data: patch });
}

// Role-scoped view used by Teacher/Student/Parent portals - published,
// non-expired announcements relevant to the caller's role (plus batch,
// for BATCH-audience ones).
async function listAnnouncementsForRole(instituteId, role, batchId) {
  if (!prisma.announcement) {
    return [];
  }

  const now = new Date();
  const audiences = [ANNOUNCEMENT_AUDIENCE.ALL];
  if (role === ROLES.TEACHER) audiences.push(ANNOUNCEMENT_AUDIENCE.TEACHERS);
  if (role === ROLES.STUDENT) audiences.push(ANNOUNCEMENT_AUDIENCE.STUDENTS);
  if (role === ROLES.PARENT) audiences.push(ANNOUNCEMENT_AUDIENCE.PARENTS);

  const audienceOr = [{ audience: { in: audiences } }];
  if (batchId) {
    audienceOr.push({ audience: ANNOUNCEMENT_AUDIENCE.BATCH, batchId: batchId });
  }

  const where = {
    instituteId: instituteId,
    status: ANNOUNCEMENT_STATUS.PUBLISHED,
    OR: [{ expiresAt: null }, { expiresAt: { gt: now } }],
    AND: [{ OR: audienceOr }],
  };

  return prisma.announcement.findMany({ where: where, orderBy: { publishedAt: 'desc' } });
}

module.exports = {
  createAnnouncement: createAnnouncement,
  listAnnouncementsForAdmin: listAnnouncementsForAdmin,
  getAnnouncementById: getAnnouncementById,
  updateAnnouncement: updateAnnouncement,
  listAnnouncementsForRole: listAnnouncementsForRole,
};
