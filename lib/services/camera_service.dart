import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (photo == null) return null;
    return _compressAndSave(photo);
  }

  Future<File?> pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (photo == null) return null;
    return _compressAndSave(photo);
  }

  Future<File?> _compressAndSave(XFile xFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.webp';
    final targetPath = p.join(appDir.path, fileName);

    // WebP로 압축 변환
    final result = await FlutterImageCompress.compressAndGetFile(
      xFile.path,
      targetPath,
      quality: 85,
      format: CompressFormat.webp,
      minWidth: 1280,
      minHeight: 1280,
    );

    // 원본 임시 파일 삭제
    try {
      await File(xFile.path).delete();
    } catch (_) {}

    await _clearTempImages();

    if (result == null) return null;
    return File(result.path);
  }

  Future<void> _clearTempImages() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      for (final file in files) {
        if (file is File &&
            (file.path.endsWith('.jpg') ||
                file.path.endsWith('.jpeg') ||
                file.path.endsWith('.png'))) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
