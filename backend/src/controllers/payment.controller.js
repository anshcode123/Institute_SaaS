const { asyncHandler } = require('../middleware/async-handler');
const { sendSuccess } = require('../utils/response');
const paymentService = require('../services/payment.service');

const recordPayment = asyncHandler(async (req, res) => {
  const payment = await paymentService.recordPayment(req.auth.instituteId, req.auth.userId, req.body);
  sendSuccess(res, payment, 'Payment recorded', 201);
});

const listPayments = asyncHandler(async (req, res) => {
  const result = await paymentService.listPayments(req.auth.instituteId, req.validatedQuery);
  sendSuccess(res, result, 'Payments retrieved');
});

const getPayment = asyncHandler(async (req, res) => {
  const payment = await paymentService.getPaymentById(req.auth.instituteId, req.params.id);
  sendSuccess(res, payment, 'Payment retrieved');
});

const getReceipt = asyncHandler(async (req, res) => {
  const receipt = await paymentService.getReceiptById(req.auth.instituteId, req.params.id);
  sendSuccess(res, receipt, 'Receipt retrieved');
});

module.exports = { recordPayment, listPayments, getPayment, getReceipt };
