const { Router } = require('express');
const { checkHealth } = require('../controllers/health.controller');

const router = Router();

router.get('/health', checkHealth);

module.exports = router;
