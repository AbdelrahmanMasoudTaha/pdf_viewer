import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfScreen extends StatefulWidget {
  const PdfScreen({super.key});

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  PdfControllerPinch? _pdfControllerPinch;
  int totalPages = 0;
  int currentpage = 0;
  bool _isloading = false;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    if (_pdfControllerPinch != null) {
      _pdfControllerPinch!.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('pdf veiwer'),
      ),
      body: Center(
        child: _pdfControllerPinch == null
            ? ElevatedButton(
                onPressed: _pickPdfFile,
                child: const Text('Select PDF From Your Device'),
              )
            : _isloading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _buildUi(),
      ),
    );
  }

  Widget _buildUi() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: () {
                    _pdfControllerPinch!.previousPage(
                        duration: Duration(milliseconds: 400),
                        curve: Curves.linear);
                  },
                  icon: const Icon(Icons.arrow_back)),
              Text(
                'Current Page : $currentpage / $totalPages',
                style: TextStyle(fontSize: 18),
              ),
              IconButton(
                  onPressed: () {
                    _pdfControllerPinch!.nextPage(
                        duration: Duration(milliseconds: 400),
                        curve: Curves.linear);
                  },
                  icon: const Icon(Icons.arrow_forward)),
            ],
          ),
        ),
        _pdfViewr(),
      ],
    );
  }

  Widget _pdfViewr() {
    return Expanded(
      child: PdfViewPinch(
        controller: _pdfControllerPinch!,
        onDocumentLoaded: (document) => setState(() {
          totalPages = document.pagesCount;
        }),
        onPageChanged: (page) => setState(() {
          currentpage = page;
        }),
      ),
    );
  }

  Future<void> _pickPdfFile() async {
    setState(() {
      _isloading = true;
    });
    FilePickerResult? pdfFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (pdfFile != null && pdfFile.paths.isNotEmpty) {
      setState(() {
        _pdfControllerPinch = PdfControllerPinch(
          document: PdfDocument.openFile(pdfFile.paths.first!),
        );
        _isloading = false;
      });
    }
  }
}
