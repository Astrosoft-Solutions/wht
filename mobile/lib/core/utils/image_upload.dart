import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

/// Builds a multipart image part with a real filename + MIME type.
/// On web, [XFile.name] is often blank or extension-less ("blob"), which makes
/// Laravel's `image` / `mimes` rules reject the upload.
MultipartFile imageMultipart(XFile file, List<int> bytes, {required String fallbackName}) {
  final mime = file.mimeType;
  final filename = _filenameFor(file, fallbackName: fallbackName, mime: mime);
  return MultipartFile.fromBytes(
    bytes,
    filename: filename,
    contentType: _mediaType(mime, filename),
  );
}

String _filenameFor(XFile file, {required String fallbackName, String? mime}) {
  final raw = file.name.trim();
  if (raw.isNotEmpty && raw.contains('.') && !raw.toLowerCase().startsWith('blob')) {
    return raw.split(RegExp(r'[\\/]')).last;
  }
  final ext = _extensionFor(mime) ?? _extensionFromName(fallbackName) ?? 'jpg';
  final base = fallbackName.contains('.') ? fallbackName.split('.').first : fallbackName;
  return '$base.$ext';
}

MediaType _mediaType(String? mime, String filename) {
  if (mime != null && mime.contains('/')) {
    final parts = mime.split('/');
    return MediaType(parts[0], parts[1]);
  }
  return switch (_extensionFromName(filename)) {
    'png' => MediaType('image', 'png'),
    'webp' => MediaType('image', 'webp'),
    'gif' => MediaType('image', 'gif'),
    _ => MediaType('image', 'jpeg'),
  };
}

String? _extensionFor(String? mime) => switch (mime) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/gif' => 'gif',
      'image/jpeg' || 'image/jpg' => 'jpg',
      _ => null,
    };

String? _extensionFromName(String name) {
  final i = name.lastIndexOf('.');
  if (i < 0 || i == name.length - 1) return null;
  return name.substring(i + 1).toLowerCase();
}
