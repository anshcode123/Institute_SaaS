const { Router } = require('express');
const controller = require('../controllers/student-portal.controller');

var router = Router();

router.get('/me', controller.getMe);
router.get('/dashboard', controller.getDashboard);
router.get('/attendance', controller.getAttendance);
router.get('/attendance-qr', controller.getQrCodes);
router.get('/leaving-qr', controller.getQrCodes);
router.get('/fees', controller.getFees);
router.get('/payments', controller.getPayments);
router.get('/receipts/:id', controller.getReceipt);
router.get('/results', controller.getResults);
router.get('/results/:id', controller.getResultById);
router.get('/announcements', controller.getAnnouncements);

module.exports = router;
