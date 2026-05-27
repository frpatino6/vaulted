import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

Future<Uint8List> compressImageBytes(
  Uint8List bytes, {
  int maxDimension = 1920,
  int quality = 80,
}) async {
  final result = await FlutterImageCompress.compressWithList(
    bytes,
    minWidth: maxDimension,
    minHeight: maxDimension,
    quality: quality,
    format: CompressFormat.jpeg,
    keepExif: false,
  );
  if (result.length >= bytes.length) return bytes;
  return Uint8List.fromList(result);
}
