const { Router } = require('express');
const { z } = require('zod');
const { validateQuery } = require('../middleware/validate');
const notificationController = require('../controllers/notification.controller');

var listNotificationsQuerySchema = z.object({
  unreadOnly: z.coerce.boolean().optional(),
  page: z.coerce.number().int().min(1).optional(),
  limit: z.coerce.number().int().min(1).max(100).optional(),
});

var router = Router();

router.get('/', validateQuery(listNotificationsQuerySchema), notificationController.listNotifications);
router.post('/read-all', notificationController.markAllRead);
router.post('/:id/read', notificationController.markRead);

module.exports = router;
