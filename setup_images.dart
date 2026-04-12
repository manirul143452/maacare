// ignore_for_file: avoid_print
import 'dart:io';

void main() async {
  final sourceDir = Directory('image1');
  final destDir = Directory('assets/images/weeks');

  if (!await destDir.exists()) {
    await destDir.create(recursive: true);
  }

  if (!await sourceDir.exists()) {
    print('Source directory image1 not found!');
    return;
  }

  final files = await sourceDir.list().toList();
  int count = 0;
  for (var file in files) {
    if (file is File) {
      // Use string operations to get filename
      final pathParts = file.path.split(RegExp(r'[\\/]'));
      final name = pathParts.last;
      
      if (name.contains('-fetaldev')) {
        final prefix = name.substring(0, 2);
        final weekNum = int.tryParse(prefix);
        if (weekNum != null) {
          final destPath = '${destDir.path}/week_$weekNum.jpg';
          await file.copy(destPath);
          print('Copied $name to week_$weekNum.jpg');
          count++;
        }
      }
    }
  }
  print('Done! Copied $count images to assets/images/weeks.');
}
