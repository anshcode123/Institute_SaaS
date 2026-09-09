const { Router } = require('express');
const controller = require('../controllers/parent-portal.controller');

var router = Router();

router.get('/me', controller.getMe);
router.get('/children', controller.getChildren);
router.get('/children/:studentId/dashboard', controller.getChildDashboard);
router.get('/children/:studentId/attendance', controller.getChildAttendance);
router.get('/children/:studentId/fees', controller.getChildFees);
router.get('/children/:studentId/payments', controller.getChildPayments);
router.get('/children/:studentId/receipts/:receiptId', controller.getChildReceipt);
router.get('/children/:studentId/results', controller.getChildResults);
router.get('/children/:studentId/results/:resultId', controller.getChildResultById);
router.get('/children/:studentId/announcements', controller.getChildAnnouncements);

module.exports = router;
