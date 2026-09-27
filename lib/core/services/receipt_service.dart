import 'dart:io';
import 'dart:math';

import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/errors/validation_exception.dart';

class ReceiptService {
  ReceiptService({
    Future<XFile?> Function()? pickImage,
    Future<ImageScanResult?> Function()? scanImages,
    Future<Directory> Function()? documentsDirectory,
  }) : _pickImage =
           pickImage ??
           (() => ImagePicker().pickImage(source: ImageSource.gallery)),
       _scanImages =
           scanImages ??
           (() => FlutterDocScanner().getScannedDocumentAsImages(
             page: 1,
             imageFormat: ImageFormat.jpeg,
             useAutomaticSinglePictureProcessing: true,
           )),
       _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory;

  final Future<XFile?> Function() _pickImage;
  final Future<ImageScanResult?> Function() _scanImages;
  final Future<Directory> Function() _documentsDirectory;

  Future<String?> pickFromGallery() async {
    try {
      final image = await _pickImage();
      if (image == null) return null;
      return await _persist(image.path);
    } catch (_) {
      throw const ValidationException(
        'Could not add the photo. Check photo access and try again.',
      );
    }
  }

  Future<String?> scanReceipt() async {
    try {
      final scan = await _scanImages();
      if (scan == null) return null;
      if (scan.images.isEmpty) {
        throw const ValidationException('No receipt image was captured.');
      }
      return await _persist(scan.images.first);
    } catch (_) {
      throw const ValidationException(
        'Could not scan the receipt. Check camera access and try again.',
      );
    }
  }

  Future<String> _persist(String sourcePath) async {
    final uri = Uri.tryParse(sourcePath);
    if (uri == null || (uri.hasScheme && uri.scheme != 'file')) {
      throw const FormatException('Scanner did not return a local image file.');
    }
    final path = uri.scheme == 'file' ? uri.toFilePath() : sourcePath;
    final source = File(path);
    if (!await source.exists() || await source.length() == 0) {
      throw const FileSystemException('The selected receipt is unavailable.');
    }

    final extension = RegExp(
      r'\.(jpe?g|png|heic|heif|webp|gif|bmp)$',
      caseSensitive: false,
    ).firstMatch(path)?.group(1)?.toLowerCase();
    if (extension == null) {
      throw const FormatException('The receipt is not an image file.');
    }

    final parent = Directory('${(await _documentsDirectory()).path}/receipts');
    await parent.create(recursive: true);
    final random = Random.secure();
    final token = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    final target = File('${parent.path}/receipt-$token.$extension');
    try {
      await source.openRead().pipe(target.openWrite());
      return target.path;
    } catch (_) {
      if (await target.exists()) await target.delete();
      rethrow;
    }
  }
}
