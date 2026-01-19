import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class LocalImageCache {
  Future<Directory> _folder() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory("${dir.path}/product_images");
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder;
  }

  String _safeVersion(String version) {
    // Make it filename-safe
    return version.replaceAll(":", "-").replaceAll(".", "-");
  }

  Future<File> _fileFor(int productId, String version) async {
    final folder = await _folder();
    final v = _safeVersion(version);
    return File("${folder.path}/${productId}_$v.jpg");
  }

  Future<File?> getLocalIfExists(int productId, String version) async {
    final f = await _fileFor(productId, version);
    return await f.exists() ? f : null;
  }

  Future<File?> downloadAndSave(
    int productId,
    String version,
    String imageUrl,
  ) async {
    try {
      final res = await http.get(Uri.parse(imageUrl));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;

      final f = await _fileFor(productId, version);
      await f.writeAsBytes(res.bodyBytes, flush: true);
      return f;
    } catch (_) {
      return null;
    }
  }

  // optional cleanup: delete older cached versions for this product
  Future<void> cleanupOldVersions(int productId, String keepVersion) async {
    final folder = await _folder();
    final keep = _safeVersion(keepVersion);
    final files = folder.listSync().whereType<File>();
    for (final f in files) {
      final name = f.path.split(Platform.pathSeparator).last;
      if (name.startsWith("${productId}_") && !name.contains("_$keep")) {
        try {
          await f.delete();
        } catch (_) {}
      }
    }
  }
}
