// Generates "REC-2026-000001" style numbers, sequential per institute
// per calendar year. Must be called with a transaction client (tx) from
// inside the same transaction that creates the receipt, so the
// "find highest, then create" isn't racing a concurrent payment.
async function generateReceiptNumber(tx, instituteId) {
  const year = new Date().getFullYear();
  const prefix = `REC-${year}-`;

  const last = await tx.paymentReceipt.findFirst({
    where: { instituteId, receiptNumber: { startsWith: prefix } },
    orderBy: { receiptNumber: 'desc' },
    select: { receiptNumber: true },
  });

  let nextSeq = 1;
  if (last) {
    const parsed = parseInt(last.receiptNumber.slice(prefix.length), 10);
    if (!Number.isNaN(parsed)) nextSeq = parsed + 1;
  }

  return `${prefix}${String(nextSeq).padStart(6, '0')}`;
}

module.exports = { generateReceiptNumber };
