import 'dart:io';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../core/utils/receipt_parser.dart'; 

class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _isDisposed = false;

  Future<ParsedReceiptData> processImage(XFile imageFile) async {
    if (_isDisposed) throw StateError('OcrService has been disposed');
    final recognized = await _textRecognizer.processImage(
      InputImage.fromFile(File(imageFile.path)),
    );
    return ReceiptParser.parse(_buildRowText(recognized));
  }

  String _buildRowText(RecognizedText r) {
    final lines = <TextLine>[for (final b in r.blocks) ...b.lines];
    if (lines.isEmpty) return r.text;

    lines.sort((a, b) =>
        a.boundingBox.center.dy.compareTo(b.boundingBox.center.dy));

    final rows = <List<TextLine>>[];
    for (final l in lines) {
      if (rows.isNotEmpty) {
        final ref = rows.last.first.boundingBox;
        final box = l.boundingBox;
        final overlap =
            math.min(ref.bottom, box.bottom) - math.max(ref.top, box.top);
        if (overlap > 0.5 * math.min(ref.height, box.height)) {
          rows.last.add(l);
          continue;
        }
      }
      rows.add([l]);
    }

    return rows.map((row) {
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      return row.map((l) => l.text).join('  ');
    }).join('\n');
  }

  Future<String?> saveThumbnail(XFile originalImage, String transactionId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final thumbnailDir = Directory(p.join(dir.path, 'thumbnails'));
      if (!thumbnailDir.existsSync()) {
        thumbnailDir.createSync(recursive: true);
      }
      final targetPath = p.join(thumbnailDir.path, '$transactionId.jpg');
      final result = await FlutterImageCompress.compressAndGetFile(
        originalImage.path,
        targetPath,
        quality: 60,
        minWidth: 300,
        minHeight: 300,
      );
      return result?.path;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteThumbnail(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }

  void dispose() {
    if (!_isDisposed) {
      _textRecognizer.close();
      _isDisposed = true;
    }
  }
}
