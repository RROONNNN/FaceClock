import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:flutter/services.dart' show rootBundle;


class RSAUtil {
  final RSAPublicKey? _publicKey;
  final RSAPrivateKey? _privateKey;
  late final Encrypter _encrypter;

  /// Khởi tạo từ PEM strings (public/private có thể null nếu chỉ cần 1 chiều)
  RSAUtil({
    RSAPublicKey? publicKey,
    RSAPrivateKey? privateKey,
  })  : _publicKey = publicKey,
        _privateKey = privateKey {
    if (_publicKey == null && _privateKey == null) {
      throw ArgumentError('Cần ít nhất publicKey hoặc privateKey');
    }
    _encrypter = Encrypter(
      RSA(
        publicKey: _publicKey,
        privateKey: _privateKey,
        encoding: RSAEncoding.OAEP,
        digest: RSADigest.SHA256,
      ),
    );
  }

  /// Parse PEM -> RSA key objects
  static RSAPublicKey parsePublicKeyFromPem(String pem) {
    final parser = RSAKeyParser();
    final key = parser.parse(pem);
    if (key is! RSAPublicKey) {
      throw ArgumentError('PEM không phải PUBLIC KEY hợp lệ');
    }
    return key;
    }
  static RSAPrivateKey parsePrivateKeyFromPem(String pem) {
    final parser = RSAKeyParser();
    final key = parser.parse(pem);
    if (key is! RSAPrivateKey) {
      throw ArgumentError('PEM không phải PRIVATE KEY hợp lệ');
    }
    return key;
  }

  /// Helper: tạo từ PEM strings (tiện nếu bạn load thủ công trước đó)
  factory RSAUtil.fromPemStrings({
    String? publicPem,
    String? privatePem,
  }) {
    RSAPublicKey? pub;
    RSAPrivateKey? pri;
    if (publicPem != null) pub = parsePublicKeyFromPem(publicPem);
    if (privatePem != null) pri = parsePrivateKeyFromPem(privatePem);
    return RSAUtil(publicKey: pub, privateKey: pri);
  }

  /// Helper: tạo từ assets Flutter (chỉ public, chỉ private, hoặc cả hai)
  static Future<RSAUtil> fromAsset({
    String? publicAssetPath,
    String? privateAssetPath,
  }) async {
    RSAPublicKey? pub;
    RSAPrivateKey? pri;

    if (publicAssetPath != null) {
      final publicPem = await rootBundle.loadString(publicAssetPath);
      pub = parsePublicKeyFromPem(publicPem);
    }
    if (privateAssetPath != null) {
      final privatePem = await rootBundle.loadString(privateAssetPath);
      pri = parsePrivateKeyFromPem(privatePem);
    }
    return RSAUtil(publicKey: pub, privateKey: pri);
  }

  /// Encrypt (yêu cầu _publicKey != null)
  String encryptToBase64(String plainText) {
    if (_publicKey == null) {
      throw StateError('Không có publicKey để mã hóa');
    }
    final encrypted = _encrypter.encrypt(plainText);
    return encrypted.base64;
  }

  /// Decrypt (yêu cầu _privateKey != null)
  String decryptFromBase64(String base64Cipher) {
    if (_privateKey == null) {
      throw StateError('Không có privateKey để giải mã');
    }
    final encrypted = Encrypted.fromBase64(base64Cipher);
    return _encrypter.decrypt(encrypted);
  }
}
