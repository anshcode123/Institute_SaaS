const { asyncHandler } = require('../middleware/async-handler');
const { sendSuccess } = require('../utils/response');
const announcementService = require('../services/announcement.service');

const createAnnouncement = asyncHandler(async function (req, res) {
  const announcement = await announcementService.createAnnouncement(
    req.auth.instituteId,
    req.auth.userId,
    req.body,
  );
  sendSuccess(res, announcement, 'Announcement created', 201);
});

const listAnnouncements = asyncHandler(async function (req, res) {
  const result = await announcementService.listAnnouncementsForAdmin(
    req.auth.instituteId,
    req.validatedQuery,
  );
  sendSuccess(res, result, 'Announcements retrieved');
});

const getAnnouncement = asyncHandler(async function (req, res) {
  const announcement = await announcementService.getAnnouncementById(
    req.auth.instituteId,
    req.params.id,
  );
  sendSuccess(res, announcement, 'Announcement retrieved');
});

const updateAnnouncement = asyncHandler(async function (req, res) {
  const announcement = await announcementService.updateAnnouncement(
    req.auth.instituteId,
    req.params.id,
    req.body,
  );
  sendSuccess(res, announcement, 'Announcement updated');
});

module.exports = {
  createAnnouncement: createAnnouncement,
  listAnnouncements: listAnnouncements,
  getAnnouncement: getAnnouncement,
  updateAnnouncement: updateAnnouncement,
};
