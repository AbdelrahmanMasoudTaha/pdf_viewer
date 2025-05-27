// import 'dart:developer';
// import 'dart:io';

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:printing/printing.dart';

// Future<bool> requestStoragePermission() async {
//   var status = await Permission.storage.request();
//   return status.isGranted;
// }

// Future<List<File>?> pickPdfFiles() async {
//   try {
//     // Request storage permission
//     if (!await requestStoragePermission()) {
//       return null;
//     }

//     // Allow multiple PDF file selection
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf'],
//       allowMultiple: true,
//     );

//     if (result != null) {
//       return result.paths.map((path) => File(path!)).toList();
//     }
//     return null;
//   } catch (e) {
//     log('Error picking PDF files: $e');
//     return null;
//   }
// }





// class PdfOperations {
//   // Merge multiple PDFs
//   static Future<File?> mergeSelectedPdfs(BuildContext context) async {
//     final pdfFiles = await pickPdfFiles();
//     if (pdfFiles == null || pdfFiles.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No PDFs selected')),
//       );
//       return null;
//     }

//     if (pdfFiles.length < 2) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select at least 2 PDFs to merge')),
//       );
//       return null;
//     }

//     final mergedFile = await _mergePdfs(pdfFiles);
//     if (mergedFile != null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('PDFs merged successfully: ${mergedFile.path}')),
//       );
//       return mergedFile;
//     }
//     return null;
//   }

//   static Future<File?> _mergePdfs(List<File> pdfFiles) async {
//     try {
//       final outputDir = await getApplicationDocumentsDirectory();
//       final outputFile = File('${outputDir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.pdf');
      
//       // Create a new PDF document
//       final pdf = pw.Document();

//       // Add all pages from each PDF
//       for (final file in pdfFiles) {
//         final pages = await Printing.document(
//           pdf: file.readAsBytesSync(),
//         );
        
//         for (var i = 0; i < pages.length; i++) {
//           pdf.addPage(pages[i]);
//         }
//       }

//       // Save the merged PDF
//       await outputFile.writeAsBytes(await pdf.save());
//       return outputFile;
//     } catch (e) {
//       print('Error merging PDFs: $e');
//       return null;
//     }
//   }

//   // Split a selected PDF
//   static Future<List<File>?> splitSelectedPdf(BuildContext context) async {
//     final pdfFiles = await pickPdfFiles();
//     if (pdfFiles == null || pdfFiles.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No PDF selected')),
//       );
//       return null;
//     }

//     // Show dialog to get split range
//     final splitAtPage = await showDialog<int>(
//       context: context,
//       builder: (context) => SplitDialog(pdfFiles.first),
//     );

//     if (splitAtPage == null) return null;

//     final splitFiles = await _splitPdf(pdfFiles.first, splitAtPage);
//     if (splitFiles != null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('PDF split into ${splitFiles.length} parts')),
//       );
//     }
//     return splitFiles;
//   }

//   static Future<List<File>?> _splitPdf(File pdfFile, int splitAtPage) async {
//     try {
//       final outputDir = await getApplicationDocumentsDirectory();
//       final baseName = pdfFile.path.split('/').last.split('.').first;
      
//       // Load the original PDF
//       final originalPdf = await Printing.document(
//         pdf: pdfFile.readAsBytesSync(),
//       );

//       if (originalPdf.length <= splitAtPage) {
//         return null;
//       }

//       // Create first part
//       final firstPart = pw.Document();
//       for (var i = 0; i < splitAtPage; i++) {
//         firstPart.addPage(originalPdf[i]);
//       }
//       final firstFile = File('${outputDir.path}/${baseName}_part1.pdf');
//       await firstFile.writeAsBytes(await firstPart.save());

//       // Create second part
//       final secondPart = pw.Document();
//       for (var i = splitAtPage; i < originalPdf.length; i++) {
//         secondPart.addPage(originalPdf[i]);
//       }
//       final secondFile = File('${outputDir.path}/${baseName}_part2.pdf');
//       await secondFile.writeAsBytes(await secondPart.save());

//       return [firstFile, secondFile];
//     } catch (e) {
//       print('Error splitting PDF: $e');
//       return null;
//     }
//   }

//   // Create PDF from selected photos
//   static Future<File?> createPdfFromSelectedPhotos(BuildContext context) async {
//     final photos = await pickPhotos();
//     if (photos == null || photos.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No photos selected')),
//       );
//       return null;
//     }

//     final pdfFile = await _createPdfFromPhotos(photos);
//     if (pdfFile != null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('PDF created: ${pdfFile.path}')),
//       );
//     }
//     return pdfFile;
//   }

//   static Future<File?> _createPdfFromPhotos(List<XFile> photos) async {
//     try {
//       final pdf = pw.Document();
      
//       for (final photo in photos) {
//         final imageBytes = await photo.readAsBytes();
//         pdf.addPage(
//           pw.Page(
//             build: (context) {
//               return pw.Center(
//                 child: pw.Image(
//                   pw.MemoryImage(imageBytes),
//                   fit: pw.BoxFit.contain,
//                 ),
//               );
//             },
//           ),
//         );
//       }

//       final outputDir = await getApplicationDocumentsDirectory();
//       final outputFile = File('${outputDir.path}/photos_${DateTime.now().millisecondsSinceEpoch}.pdf');
//       await outputFile.writeAsBytes(await pdf.save());
//       return outputFile;
//     } catch (e) {
//       print('Error creating PDF from photos: $e');
//       return null;
//     }
//   }
// }

// // Split Dialog Widget
// class SplitDialog extends StatefulWidget {
//   final File pdfFile;

//   const SplitDialog(this.pdfFile, {Key? key}) : super(key: key);

//   @override
//   _SplitDialogState createState() => _SplitDialogState();
// }

// class _SplitDialogState extends State<SplitDialog> {
//   int _totalPages = 0;
//   int _splitAtPage = 1;

//   @override
//   void initState() {
//     super.initState();
//     _getPageCount();
//   }

//   Future<void> _getPageCount() async {
//     final pdf = await Printing.document(pdf: widget.pdfFile.readAsBytesSync());
//     setState(() {
//       _totalPages = pdf.length;
//       _splitAtPage = (_totalPages / 2).floor();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Split PDF'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text('Total pages: $_totalPages'),
//           const SizedBox(height: 16),
//           Text('Split after page:'),
//           Slider(
//             min: 1,
//             max: _totalPages > 1 ? _totalPages - 1 : 1,
//             divisions: _totalPages > 1 ? _totalPages - 2 : null,
//             value: _splitAtPage.toDouble(),
//             onChanged: (value) {
//               setState(() {
//                 _splitAtPage = value.toInt();
//               });
//             },
//           ),
//           Text('$_splitAtPage'),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Cancel'),
//         ),
//         TextButton(
//           onPressed: () => Navigator.pop(context, _splitAtPage),
//           child: const Text('Split'),
//         ),
//       ],
//     );
//   }
// }