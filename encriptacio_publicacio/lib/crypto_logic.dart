import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/export.dart';

class CryptoLogic {
  static const String magicHeader = 'RSAFILE1';

  Future<void> encryptFile({
    required String publicKeyPath,
    required String inputFilePath,
    required String outputFilePath,
  }) async {
    final publicKeyPem = await File(publicKeyPath).readAsString();

    final publicKey = CryptoUtils.rsaPublicKeyFromPem(publicKeyPem);

    final cipher = OAEPEncoding(RSAEngine())
      ..init(
        true,
        PublicKeyParameter<RSAPublicKey>(publicKey),
      );

    final inputBytes = await File(inputFilePath).readAsBytes();

    final blockSize = cipher.inputBlockSize;

    final encryptedBlocks = <Uint8List>[];

    for (int offset = 0; offset < inputBytes.length; offset += blockSize) {
      final end = min(offset + blockSize, inputBytes.length);

      final block = Uint8List.fromList(
        inputBytes.sublist(offset, end),
      );

      final encryptedBlock = cipher.process(block);

      encryptedBlocks.add(encryptedBlock);
    }

    final output = BytesBuilder();

    final header = utf8.encode(magicHeader);
    output.add(_int32(header.length));
    output.add(header);

    output.add(_int32(encryptedBlocks.length));

    for (final block in encryptedBlocks) {
      output.add(_int32(block.length));
      output.add(block);
    }

    await File(outputFilePath).writeAsBytes(output.toBytes());
  }

  Future<void> decryptFile({
    required String privateKeyPath,
    required String encryptedFilePath,
    required String outputFilePath,
  }) async {
    final privateKeyPem = await File(privateKeyPath).readAsString();

    final privateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);

    final cipher = OAEPEncoding(RSAEngine())
      ..init(
        false,
        PrivateKeyParameter<RSAPrivateKey>(privateKey),
      );

    final encryptedBytes = await File(encryptedFilePath).readAsBytes();

    int cursor = 0;

    int readInt32() {
      final value = ByteData.sublistView(
        Uint8List.fromList(encryptedBytes.sublist(cursor, cursor + 4)),
      ).getUint32(0, Endian.big);

      cursor += 4;
      return value;
    }

    Uint8List readBytes(int length) {
      final value = Uint8List.fromList(
        encryptedBytes.sublist(cursor, cursor + length),
      );

      cursor += length;
      return value;
    }

    final headerLength = readInt32();
    final header = utf8.decode(readBytes(headerLength));

    if (header != magicHeader) {
      throw Exception(
        'Aquest arxiu no sembla haver estat xifrat per aquesta aplicació.',
      );
    }

    final blockCount = readInt32();

    final output = BytesBuilder();

    for (int i = 0; i < blockCount; i++) {
      final blockLength = readInt32();

      final encryptedBlock = readBytes(blockLength);

      final decryptedBlock = cipher.process(encryptedBlock);

      output.add(decryptedBlock);
    }

    await File(outputFilePath).writeAsBytes(output.toBytes());
  }

  Uint8List _int32(int value) {
    final bytes = ByteData(4);
    bytes.setUint32(0, value, Endian.big);
    return bytes.buffer.asUint8List();
  }
}