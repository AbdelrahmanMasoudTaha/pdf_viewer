import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../pdf_manipulation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';

import '../pdf_screen.dart';

class ManipulationScreen extends StatelessWidget {
  const ManipulationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Manipulation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () => _openPdfFolder(context),
            tooltip: 'Open PDF Folder',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Open PDF From Your Device',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PdfScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.file_present),
                        label: const Text('Open PDF'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Merge PDFs',
                description: 'Combine multiple PDF files into one',
                onPressed: () => _mergePDFs(context),
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Split PDF',
                description: 'Split a PDF file into two parts',
                onPressed: () => _splitPDF(context),
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Photos to PDF',
                description: 'Create a PDF from selected photos',
                onPressed: () => _createPDFFromPhotos(context),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your New PDFs Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'All New PDFs are Saved in the Folder:\n${PdfManipulation.folderName}',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _openPdfFolder(context),
                        icon: const Icon(Icons.folder_open),
                        label: const Text('How to Access Your PDFs'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPdfFolder(BuildContext context) async {
    final folderPath = await PdfManipulation.getStorageDirectory();
    if (folderPath == null) {
      _showMessage(context, 'Could not access the PDF folder');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Folder Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your PDFs are saved in:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(folderPath),
            const SizedBox(height: 16),
            const Text(
              'To access your PDFs:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('1. Open your device\'s file manager'),
            const Text('2. Navigate to Internal Storage'),
            const Text('3. Look for the "PDF_Manipulator" folder'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onPressed,
              child: Text('Start $title'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mergePDFs(BuildContext context) async {
    final files = await PdfManipulation.pickPdfFiles();
    if (files == null || files.isEmpty) {
      _showMessage(context, 'No PDFs selected');
      return;
    }

    if (files.length < 2) {
      _showMessage(context, 'Please select at least 2 PDFs to merge');
      return;
    }

    final result = await PdfManipulation.mergePdfs(context, files);
    if (result != null) {
      _showSuccessMessage(context, 'PDFs merged successfully!', result.path);
    } else {
      _showMessage(context, 'Failed to merge PDFs');
    }
  }

  Future<void> _splitPDF(BuildContext context) async {
    final files = await PdfManipulation.pickPdfFiles();
    if (files == null || files.isEmpty) {
      _showMessage(context, 'No PDF selected');
      return;
    }

    final pageRange = await _showSplitDialog(context, files.first);
    if (pageRange == null) return;

    final result = await PdfManipulation.splitPdf(
      context,
      files.first,
      pageRange['startPage']!,
      pageRange['endPage']!,
    );

    if (result != null) {
      _showSuccessMessage(
        context,
        'PDF split successfully!',
        'Extracted pages ${pageRange['startPage']} to ${pageRange['endPage']}\nSaved as: ${result.path}',
      );
    } else {
      _showMessage(context, 'Failed to split PDF');
    }
  }

  Future<void> _createPDFFromPhotos(BuildContext context) async {
    final photos = await PdfManipulation.pickPhotos();
    if (photos == null || photos.isEmpty) {
      _showMessage(context, 'No photos selected');
      return;
    }

    final result = await PdfManipulation.createPdfFromPhotos(context, photos);
    if (result != null) {
      _showSuccessMessage(context, 'PDF created successfully!', result.path);
    } else {
      _showMessage(context, 'Failed to create PDF from photos');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccessMessage(
      BuildContext context, String title, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('File saved at:'),
            const SizedBox(height: 8),
            Text(
              filePath,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('You can find all PDFs in the PDF_Manipulator folder.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openPdfFolder(context);
            },
            child: const Text('Open Folder'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>?> _showSplitDialog(
      BuildContext context, File pdfFile) async {
    double startPage = 1;
    double endPage = 2;
    int totalPages = 0;

    // Get total pages
    final pdfData = await pdfFile.readAsBytes();
    final raster = await Printing.raster(pdfData);
    await for (final _ in raster) {
      totalPages++;
    }

    if (totalPages <= 1) {
      _showMessage(context, 'PDF has only one page');
      return null;
    }

    return showDialog<Map<String, int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Split PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total pages: $totalPages'),
              const SizedBox(height: 16),
              const Text('Split from page:'),
              Row(
                children: [
                  const SizedBox(width: 16),
                  Text('${startPage.toInt()}'),
                  Expanded(
                    child: Slider(
                      min: 1,
                      max: (totalPages - 1).toDouble(),
                      divisions: totalPages - 2,
                      value: startPage,
                      onChanged: (value) {
                        setState(() {
                          startPage = value;
                          if (endPage <= startPage) {
                            endPage = startPage + 1;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const Text('To page:'),
              Row(
                children: [
                  const SizedBox(width: 16),
                  Text('${endPage.toInt()}'),
                  Expanded(
                    child: Slider(
                      min: startPage + 1,
                      max: totalPages.toDouble(),
                      divisions: (totalPages - startPage - 1).toInt(),
                      value: endPage,
                      onChanged: (value) {
                        setState(() {
                          endPage = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              Text(
                'This will create a new PDF with pages ${startPage.toInt()} to ${endPage.toInt()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                {
                  'startPage': startPage.toInt(),
                  'endPage': endPage.toInt(),
                },
              ),
              child: const Text('Split'),
            ),
          ],
        ),
      ),
    );
  }
}
