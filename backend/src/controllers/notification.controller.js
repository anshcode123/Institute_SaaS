const { asyncHandler } = require('../middleware/async-handler');
const { sendSuccess } = require('../utils/response');
const notificationService = require('../services/notification.service');

const listNotifications = asyncHandler(async function (req, res) {
  const result = await notificationService.listForUser(
    req.auth.instituteId,
    req.auth.userId,
    req.validatedQuery,
  );
  sendSuccess(res, result, 'Notifications retrieved');
});

const markRead = asyncHandler(async function (req, res) {
  const notification = await notificationService.markRead(
    req.auth.instituteId,
    req.auth.userId,
    req.params.id,
  );
  sendSuccess(res, notification, 'Notification marked as read');
});

const markAllRead = asyncHandler(async function (req, res) {
  await notificationService.markAllRead(req.auth.instituteId, req.auth.userId);
  sendSuccess(res, null, 'All notifications marked as read');
});

module.exports = { listNotifications, markRead, markAllRead };
