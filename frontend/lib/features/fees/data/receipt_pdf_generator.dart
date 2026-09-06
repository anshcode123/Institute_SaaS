import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../domain/fee_models.dart';
import '../../../shared/widgets/currency_text.dart';

/// Renders a receipt as a simple one-page PDF for print/share. Kept to a
/// single lightweight dependency pair (pdf + printing) rather than a
/// heavier templating solution, per "do not add unnecessary dependencies".
Future<pw.Document> buildReceiptPdf(Receipt receipt) async {
  final doc = pw.Document();
  final dateFormat = DateFormat.yMMMd();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(receipt.instituteName,
              style: const pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text('Institute ID: ${receipt.instituteCode}'),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Receipt No: ${receipt.receiptNumber}',
                  style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(dateFormat.format(receipt.paymentDate)),
            ],
          ),
          pw.Divider(),
          pw.SizedBox(height: 8),
          _kv('Student', '${receipt.studentName} (${receipt.studentCode})'),
          if (receipt.parentName != null)
            _kv('Parent/Guardian', receipt.parentName!),
          _kv('Fee Structure', receipt.feeStructureName),
          _kv('Installment', '#${receipt.installmentNumber}'),
          pw.SizedBox(height: 8),
          pw.Divider(),
          _kv('Amount Paid', formatCurrency(receipt.amountPaid), bold: true),
          _kv('Payment Method', receipt.paymentMethod.replaceAll('_', ' ')),
          if (receipt.transactionReference != null)
            _kv('Transaction Ref', receipt.transactionReference!),
          pw.Divider(),
          _kv('Previous Outstanding',
              formatCurrency(receipt.previousOutstanding)),
          _kv('Remaining Outstanding',
              formatCurrency(receipt.remainingOutstanding)),
          pw.Divider(),
          _kv('Received By', receipt.receivedByName),
          pw.SizedBox(height: 16),
          pw.Text(
            'This is a computer-generated receipt.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    ),
  );

  return doc;
}

pw.Widget _kv(String label, String value, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label),
        pw.Text(value,
            style: pw.TextStyle(
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    ),
  );
}
