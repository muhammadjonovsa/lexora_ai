import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

class ExportService {
  // Export as Plain Text TXT file
  Future<File> exportAsTxt(String title, String content) async {
    try {
      final directory = await getTemporaryDirectory();
      final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_');
      final file = File('${directory.path}/$sanitizedTitle.txt');
      
      await file.writeAsString(content);
      return file;
    } catch (e) {
      print("TXT Export error: $e");
      throw Exception("Matn faylini yaratishda xatolik: $e");
    }
  }

  // Export as Beautiful PDF document
  Future<File> exportAsPdf(String title, String content) async {
    final pdf = pw.Document();
    
    // Add page with beautiful layout
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Premium Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    title.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900,
                    ),
                  ),
                  pw.Text(
                    "Matn Muharriri Hujjati",
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Document Body Content
            pw.Paragraph(
              text: content,
              style: const pw.TextStyle(
                fontSize: 12,
                lineSpacing: 2.0,
              ),
            ),
            
            // Footer details (handled automatically by MultiPage)
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 24),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              "Sahifa ${context.pageNumber} / ${context.pagesCount}",
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          );
        }
      ),
    );

    try {
      final directory = await getTemporaryDirectory();
      final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_');
      final file = File('${directory.path}/$sanitizedTitle.pdf');
      
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      print("PDF Export error: $e");
      throw Exception("PDF faylini yaratishda xatolik: $e");
    }
  }

  // Share file natively
  Future<void> shareFile(File file, String documentTitle) async {
    try {
      final XFile xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        text: "'$documentTitle' - Matn Muharriri da yaratilgan premium hujjat.",
      );
    } catch (e) {
      print("Sharing failed: $e");
      throw Exception("Hujjatni ulashishda xatolik yuz berdi.");
    }
  }

  // Trigger Native Print Dialog
  Future<void> printDocument(File pdfFile) async {
    try {
      final pdfBytes = await pdfFile.readAsBytes();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      print("Printing failed: $e");
      throw Exception("Chop etishda xatolik yuz berdi.");
    }
  }
}
