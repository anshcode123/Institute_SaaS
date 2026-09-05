const { Router } = require('express');
const { validateBody, validateQuery } = require('../middleware/validate');
const {
  createParentSchema,
  updateParentSchema,
  listParentsQuerySchema,
} = require('../validators/parent.validators');
const {
  createParent,
  listParents,
  getParent,
  updateParent,
  deactivateParent,
} = require('../controllers/parent.controller');

const router = Router();

router.post('/', validateBody(createParentSchema), createParent);
router.get('/', validateQuery(listParentsQuerySchema), listParents);
router.get('/:id', getParent);
router.patch('/:id', validateBody(updateParentSchema), updateParent);
router.delete('/:id', deactivateParent);

module.exports = router;
