// ignore_for_file: avoid_print
import 'dart:io';

void main() async {
  final file = File(r'c:\Users\user\Desktop\maacare\lib\services\insforge_service.dart');
  var content = await file.readAsString();
  
  content = content.replaceAll(
    'await http.post(\n      url,\n      headers: {\n        ..._headers,\n        \'Prefer\': \'resolution=merge-duplicates\',\n      },\n      body: jsonEncode([user.toMap()]), // InsForge requires array\n    );',
    'final response = await http.post(\n      url,\n      headers: {\n        ..._headers,\n        \'Prefer\': \'resolution=merge-duplicates\',\n      },\n      body: jsonEncode([user.toMap()]),\n    );\n    if (response.statusCode >= 400) throw Exception(response.body);'
  );
  
  await file.writeAsString(content);
  print('Done');
}
