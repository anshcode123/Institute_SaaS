const { Router } = require('express');
const { validateBody, validateQuery } = require('../middleware/validate');
const {
  createParentSchema,
  updateParentSchema,
  listParentsQuerySchema,
  createParentLoginSchema,
  resetParentPasswordSchema,
} = require('../validators/parent.validators');
const {
  createParent,
  listParents,
  getParent,
  updateParent,
  deactivateParent,
  createLogin,
  resetPassword,
} = require('../controllers/parent.controller');

const router = Router();

router.post('/', validateBody(createParentSchema), createParent);
router.get('/', validateQuery(listParentsQuerySchema), listParents);
router.get('/:id', getParent);
router.patch('/:id', validateBody(updateParentSchema), updateParent);
router.delete('/:id', deactivateParent);

router.post('/:id/login', validateBody(createParentLoginSchema), createLogin);
router.post('/:id/login/reset-password', validateBody(resetParentPasswordSchema), resetPassword);

module.exports = router;
