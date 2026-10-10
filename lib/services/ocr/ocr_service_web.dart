import 'package:cross_file/cross_file.dart';
import '../../core/utils/receipt_parser.dart';

/// Web fallback used for UI debugging; ML Kit OCR remains native-only.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  Future<ParsedReceiptData> processImage(XFile imageFile) async {
    return const ParsedReceiptData(
      rawText: 'Web debug mode: OCR is unavailable in the browser.',
    );
  }

  Future<String?> saveThumbnail(XFile originalImage, String transactionId) async {
    return originalImage.path;
  }

  Future<void> deleteThumbnail(String? path) async {}

  void dispose() {}
}
