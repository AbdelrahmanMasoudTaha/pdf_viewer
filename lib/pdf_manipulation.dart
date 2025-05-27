import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:path/path.dart' as path;

class PdfManipulation {
  static const String folderName = 'PDF_Manipulator';

  // Create and get the external storage directory
  static Future<String?> getStorageDirectory() async {
    try {
      // Request storage permissions
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.request();
        final externalStatus = await Permission.manageExternalStorage.request();

        if (!storageStatus.isGranted) {
          debugPrint('Storage permission denied');
          return null;
        }

        // For Android 11 (API level 30) and above
        if (Platform.isAndroid &&
            await Permission.manageExternalStorage.isPermanentlyDenied) {
          debugPrint('Manage external storage permission permanently denied');
          return null;
        }
      }

      // Get the external storage directory
      Directory? directory;

      if (Platform.isAndroid) {
        // Try to get the external storage directory
        try {
          directory = Directory('/storage/emulated/0');
          if (!await directory.exists()) {
            final List<Directory>? extDirs =
                await getExternalStorageDirectories();
            if (extDirs != null && extDirs.isNotEmpty) {
              // Get the first external directory and navigate to root
              final String path = extDirs[0].path.split('Android')[0];
              directory = Directory(path);
            }
          }
        } catch (e) {
          debugPrint('Error accessing external storage: $e');
          // Fallback to application documents directory
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        // For iOS and other platforms, use application documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        debugPrint('Could not get storage directory');
        return null;
      }

      // Create PDF_Manipulator folder
      final String folderPath = path.join(directory.path, folderName);
      final Directory folder = Directory(folderPath);

      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      debugPrint('PDF folder path: $folderPath');
      return folderPath;
    } catch (e) {
      debugPrint('Error creating storage directory: $e');
      return null;
    }
  }

  // Pick PDF files
  static Future<List<File>?> pickPdfFiles() async {
    try {
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        return null;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null) {
        return result.paths.map((path) => File(path!)).toList();
      }
      return null;
    } catch (e) {
      debugPrint('Error picking PDF files: $e');
      return null;
    }
  }

  // Pick photos
  static Future<List<XFile>?> pickPhotos() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      return images.isNotEmpty ? images : null;
    } catch (e) {
      debugPrint('Error picking photos: $e');
      return null;
    }
  }

  // Get file name from user
  static Future<String?> _getFileName(
      BuildContext context, String defaultName, String title) async {
    final controller = TextEditingController(text: defaultName);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'File Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    return result?.trim();
  }

  // Merge PDFs
  static Future<File?> mergePdfs(
      BuildContext context, List<File> pdfFiles) async {
    try {
      final fileName = await _getFileName(context,
          'merged_${DateTime.now().millisecondsSinceEpoch}', 'Name Merged PDF');

      if (fileName == null) return null;

      final folderPath = await getStorageDirectory();
      if (folderPath == null) {
        debugPrint('Failed to get storage directory');
        return null;
      }

      final outputFile = File(path.join(folderPath, '$fileName.pdf'));

      final pdf = pw.Document();

      for (final file in pdfFiles) {
        final pdfData = await file.readAsBytes();
        final raster = await Printing.raster(pdfData);

        await for (final page in raster) {
          final pageImage = await page.toPng();
          if (pageImage != null) {
            pdf.addPage(
              pw.Page(
                build: (context) => pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(pageImage),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
            );
          }
        }
      }

      await outputFile.writeAsBytes(await pdf.save());
      return outputFile;
    } catch (e) {
      debugPrint('Error merging PDFs: $e');
      return null;
    }
  }

  // Split PDF
  static Future<File?> splitPdf(
    BuildContext context,
    File pdfFile,
    int startPage,
    int endPage,
  ) async {
    try {
      final baseName = pdfFile.path.split('/').last.split('.').first;

      final fileName = await _getFileName(context,
          '${baseName}_pages_${startPage}_to_$endPage', 'Name Split PDF');

      if (fileName == null) return null;

      final folderPath = await getStorageDirectory();
      if (folderPath == null) {
        debugPrint('Failed to get storage directory');
        return null;
      }

      final pdfData = await pdfFile.readAsBytes();
      final raster = await Printing.raster(pdfData);

      final pages = <pw.Page>[];
      int currentPage = 1;

      await for (final page in raster) {
        if (currentPage >= startPage && currentPage <= endPage) {
          final pageImage = await page.toPng();
          if (pageImage != null) {
            pages.add(
              pw.Page(
                build: (context) => pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(pageImage),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
            );
          }
        }
        currentPage++;
      }

      if (pages.isEmpty) {
        return null;
      }

      // Create new PDF with selected pages
      final newPdf = pw.Document();
      for (var page in pages) {
        newPdf.addPage(page);
      }

      final outputFile = File(path.join(folderPath, '$fileName.pdf'));
      await outputFile.writeAsBytes(await newPdf.save());

      return outputFile;
    } catch (e) {
      debugPrint('Error splitting PDF: $e');
      return null;
    }
  }

  // Create PDF from photos
  static Future<File?> createPdfFromPhotos(
      BuildContext context, List<XFile> photos) async {
    try {
      final fileName = await _getFileName(context,
          'photos_${DateTime.now().millisecondsSinceEpoch}', 'Name Photo PDF');

      if (fileName == null) return null;

      final folderPath = await getStorageDirectory();
      if (folderPath == null) {
        debugPrint('Failed to get storage directory');
        return null;
      }

      final pdf = pw.Document();

      for (final photo in photos) {
        final imageBytes = await photo.readAsBytes();
        pdf.addPage(
          pw.Page(
            build: (context) {
              return pw.Center(
                child: pw.Image(
                  pw.MemoryImage(imageBytes),
                  fit: pw.BoxFit.contain,
                ),
              );
            },
          ),
        );
      }

      final outputFile = File(path.join(folderPath, '$fileName.pdf'));
      await outputFile.writeAsBytes(await pdf.save());
      return outputFile;
    } catch (e) {
      debugPrint('Error creating PDF from photos: $e');
      return null;
    }
  }
}
