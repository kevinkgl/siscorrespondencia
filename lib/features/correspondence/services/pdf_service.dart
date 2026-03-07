import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/correspondence_model.dart';

class PdfService {
  static Future<void> generateAndPrintCorrespondence(CorrespondenceModel doc) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('INSTITUCIÓN DE PRUEBA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                      pw.Text('Sistema de Correspondencia', style: pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.Container(
                    width: 60,
                    height: 60,
                    child: pw.PdfLogo(), // Usamos un logo genérico por ahora
                  ),
                ],
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // CITE and Date
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('CITE: ${doc.cite}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(doc.fechaEmision)}'),
                ],
              ),
              pw.SizedBox(height: 20),

              // To/From
              pw.Text('De: ${doc.remitente}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Para: ${doc.destinatario ?? doc.destinatarioExterno ?? 'N/A'}'),
              pw.SizedBox(height: 10),
              pw.Text('Tipo: ${doc.tipo}'),
              pw.SizedBox(height: 20),

              // Subject
              pw.Text('REFERENCIA: ${doc.asunto}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
              pw.SizedBox(height: 30),

              // Content
              pw.Text(doc.contenido ?? 'Sin contenido detallado.'),
              
              pw.Spacer(),

              // Footer
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Clasificación: ${doc.clasificacion}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  pw.Text('Página 1 de 1', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<File> generateAndSavePdf(CorrespondenceModel doc, String path) async {
    final pdf = pw.Document();
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
