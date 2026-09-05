const { Router } = require('express');
const { validateBody, validateQuery } = require('../middleware/validate');
const { recordPaymentSchema, listPaymentsQuerySchema } = require('../validators/payment.validators');
const {
  recordPayment,
  listPayments,
  getPayment,
  getReceipt,
} = require('../controllers/payment.controller');

const paymentsRouter = Router();
paymentsRouter.post('/', validateBody(recordPaymentSchema), recordPayment);
paymentsRouter.get('/', validateQuery(listPaymentsQuerySchema), listPayments);
paymentsRouter.get('/:id', getPayment);

const receiptsRouter = Router();
receiptsRouter.get('/:id', getReceipt);

module.exports = { paymentsRouter, receiptsRouter };
