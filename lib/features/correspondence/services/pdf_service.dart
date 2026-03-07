import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../models/correspondence_model.dart';

class PdfService {
  static Future<void> generateOfficialPdf(CorrespondenceModel doc) async {
    final pdf = pw.Document();

    // Cargar imagen de firma si existe
    pw.MemoryImage? signatureImage;
    if (doc.firmaUrl != null) {
      try {
        final response = await http.get(Uri.parse(doc.firmaUrl!));
        if (response.statusCode == 200) {
          signatureImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        print('Error cargando firma para el PDF: $e');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // CABECERA OFICIAL
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SISTEMA DE CORRESPONDENCIA',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        'REPUBLICA DE BOLIVIA', // Ajustar según país
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: doc.cite,
                    width: 60,
                    height: 60,
                  ),
                ],
              ),
              pw.Divider(thickness: 2, color: PdfColors.blue900),
              pw.SizedBox(height: 20),

              // DATOS DEL DOCUMENTO
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'CITE: ${doc.cite}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Fecha: ${doc.fechaEmision.day}/${doc.fechaEmision.month}/${doc.fechaEmision.year}',
              ),
              pw.SizedBox(height: 30),

              // CUERPO DE LA CORRESPONDENCIA
              pw.Text('A: ${doc.destinatario ?? doc.destinatarioExterno ?? "A quien corresponda"}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text('DE: ${doc.remitente}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 15),
              pw.Text('REF: ${doc.asunto}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  )),
              pw.SizedBox(height: 30),

              // CONTENIDO
              pw.Expanded(
                child: pw.Text(
                  doc.contenido ?? 'Sin contenido adicional.',
                  textAlign: pw.TextAlign.justify,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),

              // PIE DE PÁGINA CON FIRMA
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Column(
                    children: [
                      if (signatureImage != null)
                        pw.Image(signatureImage, height: 60),
                      pw.SizedBox(height: 5),
                      pw.Container(
                        width: 200,
                        height: 1,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(doc.remitente,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Firma Digital Autorizada',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Abrir vista previa de impresión
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Documento_${doc.cite}.pdf',
    );
  }
}
