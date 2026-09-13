const { Router } = require('express');
const { validateBody, validateQuery } = require('../middleware/validate');
const {
  createAnnouncementSchema,
  updateAnnouncementSchema,
  listAnnouncementsQuerySchema,
} = require('../validators/announcement.validators');
const announcementController = require('../controllers/announcement.controller');

// Institute Admin only, mounted with that authorize() in routes/index.js
// - Teacher does not get creation permission unless explicitly required,
// which the spec says it isn't.
const router = Router();

router.post('/', validateBody(createAnnouncementSchema), announcementController.createAnnouncement);
router.get('/', validateQuery(listAnnouncementsQuerySchema), announcementController.listAnnouncements);
router.get('/:id', announcementController.getAnnouncement);
router.patch('/:id', validateBody(updateAnnouncementSchema), announcementController.updateAnnouncement);

module.exports = router;
