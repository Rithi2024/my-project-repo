import 'dart:io';
import 'package:file_picker/file_picker.dart';

Future<File?> pickImageFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
  );

  if (result == null) return null;
  if (result.files.single.path == null) return null;

  return File(result.files.single.path!);
}
