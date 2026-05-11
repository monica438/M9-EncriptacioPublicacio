import 'package:flutter/material.dart';
import 'ui_app.dart';

void main() {
  runApp(const RsaFileEncryptorApp());
}

class RsaFileEncryptorApp extends StatelessWidget {
  const RsaFileEncryptorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RSA File Encryptor',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const UIapp(),
    );
  }
}