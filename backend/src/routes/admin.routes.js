const { Router } = require('express');
const { authenticate } = require('../middleware/authenticate');
const { authorize } = require('../middleware/authorize');
const { validateBody } = require('../middleware/validate');
const { ROLES } = require('../constants/roles');
const {
  createInstituteSchema,
  updateInstituteStatusSchema,
} = require('../validators/institute.validators');
const {
  createInstitute,
  listInstitutes,
  getInstitute,
  updateInstituteStatus,
} = require('../controllers/institute.controller');

const router = Router();

// Every route below: authenticate -> authorize(SUPER_ADMIN) -> controller.
router.use(authenticate, authorize(ROLES.SUPER_ADMIN));

router.post('/institutes', validateBody(createInstituteSchema), createInstitute);
router.get('/institutes', listInstitutes);
router.get('/institutes/:id', getInstitute);
router.patch('/institutes/:id/status', validateBody(updateInstituteStatusSchema), updateInstituteStatus);

module.exports = router;
