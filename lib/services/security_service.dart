import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypto/crypto.dart';

class SecurityService {
  static Key? _cachedKey;
  static Encrypter? _cachedEncrypter;

  static Key get _key {
    if (_cachedKey != null) return _cachedKey!;
    final keyStr = dotenv.env['ENCRYPTION_KEY'] ?? 'QubicoTransportes2024SecureKey!!';
    _cachedKey = Key.fromUtf8(keyStr);
    return _cachedKey!;
  }

  static IV get _iv {
    final ivStr = dotenv.env['ENCRYPTION_IV'] ?? 'QubicoIV16Bytes!';
    return IV.fromUtf8(ivStr);
  }

  static Encrypter get _encrypter {
    _cachedEncrypter ??= Encrypter(AES(_key));
    return _cachedEncrypter!;
  }

  /// Genera un hash determinista (SHA-256) ideal para Indexación Ciega en bases de datos NoSQL
  static String generateHash(String text) {
    if (text.isEmpty) return text;
    final bytes = utf8.encode(text.toLowerCase().trim());
    return sha256.convert(bytes).toString();
  }

  /// Encrypts a string using AES-256
  static String encrypt(String text) {
    if (text.isEmpty) return text;
    final encrypted = _encrypter.encrypt(text, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypts a base64 string using AES-256
  static String decrypt(String base64Text) {
    if (base64Text.isEmpty) return base64Text;
    try {
      return _encrypter.decrypt64(base64Text, iv: _iv);
    } catch (e) {
      // If decryption fails (e.g. it wasn't encrypted), return original
      return base64Text;
    }
  }
}
