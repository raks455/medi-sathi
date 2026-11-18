import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/scanned_medicine.dart';

/// Takes or picks a photo and reads its text on the device (ML Kit).
/// The picture is never uploaded.
abstract class PrescriptionScanner {
  /// Path of the chosen image, or null if the user cancelled.
  Future<String?> pickImage(ScanSource source);

  /// The text lines found in the image, top to bottom.
  Future<List<String>> readLines(String imagePath);
}

class PrescriptionScannerImpl implements PrescriptionScanner {
  final ImagePicker picker;

  /// Opens the app's own camera screen; returns the photo's path, or null
  /// if the user went back. (The phone's camera app is not used: see
  /// `takePhoto`.)
  final Future<String?> Function() takeCameraPhoto;

  PrescriptionScannerImpl(this.picker, {required this.takeCameraPhoto});

  @override
  Future<String?> pickImage(ScanSource source) async {
    if (source == ScanSource.camera) return takeCameraPhoto();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      // Large enough for small print, small enough to process quickly.
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 90,
    );
    return file?.path;
  }

  @override
  Future<List<String>> readLines(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(imagePath));
      return [
        for (final block in result.blocks)
          for (final line in block.lines) line.text,
      ];
    } finally {
      await recognizer.close();
    }
  }
}
