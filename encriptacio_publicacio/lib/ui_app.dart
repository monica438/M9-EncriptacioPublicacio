import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'crypto_logic.dart';

class FileCryptoPage extends StatefulWidget {
  const FileCryptoPage({super.key});

  @override
  State<FileCryptoPage> createState() => _FileCryptoPageState();
}

class _FileCryptoPageState extends State<FileCryptoPage> {
  final CryptoService cryptoService = CryptoService();

  String publicKeyPath = '';
  String fileToEncryptPath = '';
  String encryptedOutputPath = '';

  String privateKeyPath = _defaultPrivateKeyPath();
  String encryptedInputPath = '';
  String decryptedOutputPath = '';

  bool loading = false;
  String message = '';

  static String _defaultPrivateKeyPath() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';

    if (home.isEmpty) return '';

    return p.join(home, '.ssh', 'id_rsa');
  }

  Future<String?> pickFile({
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: allowedExtensions == null
          ? FileType.any
          : FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    return result.files.single.path;
  }

  Future<String?> saveFile({
    required String suggestedName,
  }) async {
    return FilePicker.platform.saveFile(
      dialogTitle: 'Selecciona arxiu destí',
      fileName: suggestedName,
    );
  }

  Future<void> encrypt() async {
    if (publicKeyPath.isEmpty || fileToEncryptPath.isEmpty) {
      setState(() {
        message = 'Selecciona una clau pública i un arxiu a encriptar.';
      });
      return;
    }

    final output = encryptedOutputPath.isNotEmpty
        ? encryptedOutputPath
        : '$fileToEncryptPath.enc';

    setState(() {
      loading = true;
      message = 'Encriptant...';
    });

    try {
      await cryptoService.encryptFile(
        publicKeyPath: publicKeyPath,
        inputFilePath: fileToEncryptPath,
        outputFilePath: output,
      );

      setState(() {
        encryptedOutputPath = output;
        message = 'Arxiu encriptat correctament:\n$output';
      });
    } catch (e) {
      setState(() {
        message = 'Error encriptant:\n$e';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> decrypt() async {
    if (privateKeyPath.isEmpty ||
        encryptedInputPath.isEmpty ||
        decryptedOutputPath.isEmpty) {
      setState(() {
        message =
            'Selecciona clau privada, arxiu xifrat i arxiu destí.';
      });
      return;
    }

    setState(() {
      loading = true;
      message = 'Desencriptant...';
    });

    try {
      await cryptoService.decryptFile(
        privateKeyPath: privateKeyPath,
        encryptedFilePath: encryptedInputPath,
        outputFilePath: decryptedOutputPath,
      );

      setState(() {
        message = 'Arxiu desencriptat correctament:\n$decryptedOutputPath';
      });
    } catch (e) {
      setState(() {
        message = 'Error desencriptant:\n$e';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Widget labeledField({
    required String label,
    required String value,
    required VoidCallback onPick,
    required String buttonText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                readOnly: true,
                controller: TextEditingController(text: value),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: loading ? null : onPick,
              child: Text(buttonText),
            ),
          ],
        ),
      ],
    );
  }

  Widget editableField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    required VoidCallback onPick,
    required String buttonText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(text: value)
                  ..selection = TextSelection.collapsed(
                    offset: value.length,
                  ),
                onChanged: onChanged,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: loading ? null : onPick,
              child: Text(buttonText),
            ),
          ],
        ),
      ],
    );
  }

  Widget sectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RSA File Encryptor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (loading) const LinearProgressIndicator(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: encryptPanel()),
                  const VerticalDivider(width: 48),
                  Expanded(child: decryptPanel()),
                ],
              ),
            ),
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(
                message.isEmpty
                    ? 'Llest. Selecciona una operació.'
                    : message,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget encryptPanel() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('Encriptar Arxiu'),
          labeledField(
            label: 'Clau pública RSA:',
            value: publicKeyPath,
            buttonText: 'Selecciona...',
            onPick: () async {
              final file = await pickFile(
                allowedExtensions: ['pem', 'pub'],
              );

              if (file != null) {
                setState(() {
                  publicKeyPath = file;
                });
              }
            },
          ),
          const SizedBox(height: 24),
          labeledField(
            label: 'Arxiu a encriptar:',
            value: fileToEncryptPath,
            buttonText: 'Navega...',
            onPick: () async {
              final file = await pickFile();

              if (file != null) {
                setState(() {
                  fileToEncryptPath = file;
                  encryptedOutputPath = '$file.enc';
                });
              }
            },
          ),
          const SizedBox(height: 24),
          labeledField(
            label: 'Arxiu xifrat destí:',
            value: encryptedOutputPath,
            buttonText: 'Desa com...',
            onPick: () async {
              final output = await saveFile(
                suggestedName: fileToEncryptPath.isEmpty
                    ? 'document.txt.enc'
                    : '${p.basename(fileToEncryptPath)}.enc',
              );

              if (output != null) {
                setState(() {
                  encryptedOutputPath = output;
                });
              }
            },
          ),
          const SizedBox(height: 32),
          Center(
            child: SizedBox(
              width: 260,
              height: 48,
              child: FilledButton(
                onPressed: loading ? null : encrypt,
                child: const Text(
                  'Encripta Arxiu',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget decryptPanel() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('Desencriptar Arxiu'),
          editableField(
            label: 'Clau privada RSA:',
            value: privateKeyPath,
            buttonText: 'Selecciona...',
            onChanged: (value) {
              privateKeyPath = value;
            },
            onPick: () async {
              final file = await pickFile(
                allowedExtensions: ['pem', 'key', 'rsa'],
              );

              if (file != null) {
                setState(() {
                  privateKeyPath = file;
                });
              }
            },
          ),
          const SizedBox(height: 24),
          labeledField(
            label: 'Arxiu xifrat:',
            value: encryptedInputPath,
            buttonText: 'Navega...',
            onPick: () async {
              final file = await pickFile();

              if (file != null) {
                setState(() {
                  encryptedInputPath = file;

                  final base = p.basenameWithoutExtension(file);
                  decryptedOutputPath = p.join(
                    p.dirname(file),
                    '${base}_desxifrat',
                  );
                });
              }
            },
          ),
          const SizedBox(height: 24),
          labeledField(
            label: 'Arxiu desxifrat destí:',
            value: decryptedOutputPath,
            buttonText: 'Navega...',
            onPick: () async {
              final output = await saveFile(
                suggestedName: 'document_desxifrat.txt',
              );

              if (output != null) {
                setState(() {
                  decryptedOutputPath = output;
                });
              }
            },
          ),
          const SizedBox(height: 32),
          Center(
            child: SizedBox(
              width: 260,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: loading ? null : decrypt,
                child: const Text(
                  'Desencripta Arxiu',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}