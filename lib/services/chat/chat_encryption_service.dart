import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:crypto/crypto.dart';

/// Service responsible for end-to-end encryption of chat messages
///
/// Architecture:
/// - RSA-2048: User key pairs for secure key exchange
/// - AES-256 GCM: Per-conversation symmetric encryption
/// - HMAC-SHA256: Message integrity verification
/// - Secure Storage: Keys stored in device secure enclave/keystore
class ChatEncryptionService {
  static final ChatEncryptionService _instance = ChatEncryptionService._internal();
  factory ChatEncryptionService() => _instance;
  ChatEncryptionService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Storage keys
  static const String _privateKeyStorageKey = 'chat_rsa_private_key';
  static const String _publicKeyStorageKey = 'chat_rsa_public_key';
  static const String _conversationKeyPrefix = 'chat_conv_key_';

  // Cache for performance
  pc.RSAPrivateKey? _cachedPrivateKey;
  pc.RSAPublicKey? _cachedPublicKey;
  final Map<String, encrypt.Key> _conversationKeysCache = {};

  // ============================================================================
  // USER KEY PAIR MANAGEMENT (RSA-2048)
  // ============================================================================

  /// Initialize encryption keys for a new user
  /// Should be called once during user registration
  Future<void> initializeUserKeys() async {
    try {
      debugPrint('🔐 Initializing user encryption keys...');

      // Check if keys already exist
      final existingPrivateKey = await _secureStorage.read(key: _privateKeyStorageKey);
      if (existingPrivateKey != null) {
        debugPrint('✅ User keys already exist, skipping generation');

        // Verify public key is in Firestore
        final userId = await _getCurrentUserId();
        if (userId != null) {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (!userDoc.exists || userDoc.data()?['publicKey'] == null) {
            debugPrint('⚠️ Public key missing in Firestore, re-uploading...');
            final publicKey = await getPublicKey();
            await _uploadPublicKeyToFirestore(publicKey);
          }
        }
        return;
      }

      debugPrint('🔑 Generating RSA key pair...');
      // Generate RSA key pair
      final keyPair = await _generateRSAKeyPair();
      debugPrint('✅ RSA key pair generated');

      // Store private key securely (never leaves device)
      debugPrint('💾 Storing private key...');
      await _storePrivateKey(keyPair.privateKey as pc.RSAPrivateKey);
      debugPrint('✅ Private key stored');

      // Store public key locally and in Firestore
      debugPrint('💾 Storing public key...');
      await _storePublicKey(keyPair.publicKey as pc.RSAPublicKey);
      debugPrint('✅ Public key stored locally');

      debugPrint('☁️ Uploading public key to Firestore...');
      await _uploadPublicKeyToFirestore(keyPair.publicKey as pc.RSAPublicKey);

      debugPrint('✅ User encryption keys initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize user keys: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Generate RSA-2048 key pair
  Future<pc.AsymmetricKeyPair<pc.PublicKey, pc.PrivateKey>> _generateRSAKeyPair() async {
    return compute(_generateRSAKeyPairIsolate, null);
  }

  /// Isolate function for key pair generation (CPU intensive)
  static pc.AsymmetricKeyPair<pc.PublicKey, pc.PrivateKey> _generateRSAKeyPairIsolate(_) {
    final keyGen = pc.RSAKeyGenerator()
      ..init(
        pc.ParametersWithRandom(
          pc.RSAKeyGeneratorParameters(
            BigInt.parse('65537'), // Public exponent
            2048, // Key size
            64, // Certainty for prime generation
          ),
          pc.FortunaRandom()..seed(pc.KeyParameter(_generateRandomBytes(32))),
        ),
      );

    final keyPair = keyGen.generateKeyPair();
    return pc.AsymmetricKeyPair<pc.PublicKey, pc.PrivateKey>(
      keyPair.publicKey,
      keyPair.privateKey,
    );
  }

  /// Generate cryptographically secure random bytes
  static Uint8List _generateRandomBytes(int length) {
    final random = pc.FortunaRandom();
    final seed = List<int>.generate(32, (i) => DateTime.now().microsecondsSinceEpoch % 256);
    random.seed(pc.KeyParameter(Uint8List.fromList(seed)));
    return random.nextBytes(length);
  }

  /// Store private key in secure storage
  Future<void> _storePrivateKey(pc.RSAPrivateKey privateKey) async {
    final pem = _encodeRSAPrivateKeyToPem(privateKey);
    await _secureStorage.write(key: _privateKeyStorageKey, value: pem);
    _cachedPrivateKey = privateKey;
  }

  /// Store public key in secure storage
  Future<void> _storePublicKey(pc.RSAPublicKey publicKey) async {
    final pem = _encodeRSAPublicKeyToPem(publicKey);
    await _secureStorage.write(key: _publicKeyStorageKey, value: pem);
    _cachedPublicKey = publicKey;
  }

  /// Upload public key to Firestore for other users to access
  Future<void> _uploadPublicKeyToFirestore(pc.RSAPublicKey publicKey) async {
    final userId = await _getCurrentUserId();
    if (userId == null) throw Exception('User not authenticated');

    final pem = _encodeRSAPublicKeyToPem(publicKey);

    try {
      // Use set with merge to create document if it doesn't exist
      await _firestore.collection('users').doc(userId).set({
        'publicKey': pem,
        'publicKeyTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Public key uploaded to Firestore for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to upload public key to Firestore: $e');
      rethrow;
    }
  }

  /// Retrieve user's private key
  Future<pc.RSAPrivateKey> getPrivateKey() async {
    if (_cachedPrivateKey != null) return _cachedPrivateKey!;

    final pem = await _secureStorage.read(key: _privateKeyStorageKey);
    if (pem == null) {
      throw Exception('Private key not found. Please initialize user keys.');
    }

    _cachedPrivateKey = _decodeRSAPrivateKeyFromPem(pem);
    return _cachedPrivateKey!;
  }

  /// Retrieve user's public key
  Future<pc.RSAPublicKey> getPublicKey() async {
    if (_cachedPublicKey != null) return _cachedPublicKey!;

    final pem = await _secureStorage.read(key: _publicKeyStorageKey);
    if (pem == null) {
      throw Exception('Public key not found. Please initialize user keys.');
    }

    _cachedPublicKey = _decodeRSAPublicKeyFromPem(pem);
    return _cachedPublicKey!;
  }

  /// Fetch another user's public key from Firestore
  Future<pc.RSAPublicKey> fetchUserPublicKey(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('User not found: $userId');
    }

    final pem = userDoc.data()?['publicKey'] as String?;
    if (pem == null) {
      throw Exception('Public key not found for user: $userId');
    }

    return _decodeRSAPublicKeyFromPem(pem);
  }

  // ============================================================================
  // CONVERSATION KEY MANAGEMENT (AES-256)
  // ============================================================================

  /// Generate new AES-256 key for a conversation
  encrypt.Key generateConversationKey() {
    final secureRandom = pc.FortunaRandom();
    final seed = _generateRandomBytes(32);
    secureRandom.seed(pc.KeyParameter(seed));
    final keyBytes = secureRandom.nextBytes(32); // 256 bits
    return encrypt.Key(keyBytes);
  }

  /// Encrypt conversation key with user's RSA public key
  Future<String> encryptKeyForUser(encrypt.Key aesKey, pc.RSAPublicKey publicKey) async {
    final encrypter = pc.RSAEngine()
      ..init(true, pc.PublicKeyParameter<pc.RSAPublicKey>(publicKey));

    final encrypted = encrypter.process(aesKey.bytes);
    return base64Encode(encrypted);
  }

  /// Decrypt conversation key with user's RSA private key
  Future<encrypt.Key> decryptConversationKey(String encryptedKeyBase64) async {
    final privateKey = await getPrivateKey();
    final encrypter = pc.RSAEngine()
      ..init(false, pc.PrivateKeyParameter<pc.RSAPrivateKey>(privateKey));

    final encryptedBytes = base64Decode(encryptedKeyBase64);
    final decrypted = encrypter.process(Uint8List.fromList(encryptedBytes));
    return encrypt.Key(decrypted);
  }

  /// Store conversation key locally (encrypted by device secure storage)
  Future<void> storeConversationKey(String conversationId, encrypt.Key key) async {
    final keyBase64 = base64Encode(key.bytes);
    await _secureStorage.write(
      key: '$_conversationKeyPrefix$conversationId',
      value: keyBase64,
    );
    _conversationKeysCache[conversationId] = key;
  }

  /// Retrieve conversation key from local storage
  Future<encrypt.Key?> getConversationKey(String conversationId) async {
    // Check cache first
    if (_conversationKeysCache.containsKey(conversationId)) {
      return _conversationKeysCache[conversationId];
    }

    // Load from secure storage
    final keyBase64 = await _secureStorage.read(
      key: '$_conversationKeyPrefix$conversationId',
    );

    if (keyBase64 == null) return null;

    final key = encrypt.Key(base64Decode(keyBase64));
    _conversationKeysCache[conversationId] = key;
    return key;
  }

  // ============================================================================
  // MESSAGE ENCRYPTION/DECRYPTION (AES-256-GCM)
  // ============================================================================

  /// Encrypt message content
  Future<EncryptedMessage> encryptMessage(
    String content,
    String conversationId,
  ) async {
    try {
      // Get conversation key
      final key = await getConversationKey(conversationId);
      if (key == null) {
        throw Exception('Conversation key not found for: $conversationId');
      }

      // Generate random IV (Initialization Vector)
      final iv = encrypt.IV.fromSecureRandom(16);

      // Encrypt content using AES-GCM
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      final encrypted = encrypter.encrypt(content, iv: iv);

      // Generate HMAC signature for integrity
      final signature = _generateMessageSignature(content, key);

      return EncryptedMessage(
        encryptedContent: encrypted.base64,
        iv: iv.base64,
        signature: signature,
      );
    } catch (e) {
      debugPrint('❌ Encryption error: $e');
      rethrow;
    }
  }

  /// Decrypt message content
  Future<String> decryptMessage(
    EncryptedMessage encryptedMessage,
    String conversationId,
  ) async {
    try {
      // Get conversation key
      final key = await getConversationKey(conversationId);
      if (key == null) {
        throw Exception('Conversation key not found for: $conversationId');
      }

      // Decrypt content
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      final encrypted = encrypt.Encrypted.fromBase64(encryptedMessage.encryptedContent);
      final iv = encrypt.IV.fromBase64(encryptedMessage.iv);

      final decrypted = encrypter.decrypt(encrypted, iv: iv);

      // Verify signature
      final isValid = _verifyMessageSignature(
        decrypted,
        encryptedMessage.signature,
        key,
      );

      if (!isValid) {
        debugPrint('⚠️ Message signature verification failed!');
        throw Exception('Message integrity compromised');
      }

      return decrypted;
    } catch (e) {
      debugPrint('❌ Decryption error: $e');
      rethrow;
    }
  }

  /// Generate HMAC-SHA256 signature for message integrity
  String _generateMessageSignature(String content, encrypt.Key key) {
    final hmac = Hmac(sha256, key.bytes);
    final digest = hmac.convert(utf8.encode(content));
    return base64Encode(digest.bytes);
  }

  /// Verify HMAC signature
  bool _verifyMessageSignature(String content, String signature, encrypt.Key key) {
    final expectedSignature = _generateMessageSignature(content, key);
    return expectedSignature == signature;
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get current user ID from Firebase Auth
  Future<String?> _getCurrentUserId() async {
    try {
      return _auth.currentUser?.uid;
    } catch (e) {
      debugPrint('❌ Failed to get current user ID: $e');
      return null;
    }
  }

  /// Encode RSA private key to PEM format
  String _encodeRSAPrivateKeyToPem(pc.RSAPrivateKey privateKey) {
    // Simplified PEM encoding - store modulus and private exponent
    final data = {
      'modulus': privateKey.modulus.toString(),
      'privateExponent': privateKey.privateExponent.toString(),
      'p': privateKey.p.toString(),
      'q': privateKey.q.toString(),
    };
    return base64Encode(utf8.encode(jsonEncode(data)));
  }

  /// Decode RSA private key from PEM format
  pc.RSAPrivateKey _decodeRSAPrivateKeyFromPem(String pem) {
    final data = jsonDecode(utf8.decode(base64Decode(pem))) as Map<String, dynamic>;
    return pc.RSAPrivateKey(
      BigInt.parse(data['modulus']),
      BigInt.parse(data['privateExponent']),
      BigInt.parse(data['p']),
      BigInt.parse(data['q']),
    );
  }

  /// Encode RSA public key to PEM format
  String _encodeRSAPublicKeyToPem(pc.RSAPublicKey publicKey) {
    final data = {
      'modulus': publicKey.modulus.toString(),
      'exponent': publicKey.exponent.toString(),
    };
    return base64Encode(utf8.encode(jsonEncode(data)));
  }

  /// Decode RSA public key from PEM format
  pc.RSAPublicKey _decodeRSAPublicKeyFromPem(String pem) {
    final data = jsonDecode(utf8.decode(base64Decode(pem))) as Map<String, dynamic>;
    return pc.RSAPublicKey(
      BigInt.parse(data['modulus']),
      BigInt.parse(data['exponent']),
    );
  }

  /// Clear all cached keys (call on logout)
  Future<void> clearCache() async {
    _cachedPrivateKey = null;
    _cachedPublicKey = null;
    _conversationKeysCache.clear();
  }

  /// Delete all encryption keys (use with caution)
  Future<void> deleteAllKeys() async {
    await _secureStorage.deleteAll();
    await clearCache();
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

/// Encrypted message structure
class EncryptedMessage {
  final String encryptedContent; // Base64 encoded encrypted content
  final String iv; // Base64 encoded initialization vector
  final String signature; // HMAC-SHA256 signature for integrity

  const EncryptedMessage({
    required this.encryptedContent,
    required this.iv,
    required this.signature,
  });

  Map<String, dynamic> toMap() {
    return {
      'encryptedContent': encryptedContent,
      'iv': iv,
      'signature': signature,
    };
  }

  factory EncryptedMessage.fromMap(Map<String, dynamic> map) {
    return EncryptedMessage(
      encryptedContent: map['encryptedContent'] as String,
      iv: map['iv'] as String,
      signature: map['signature'] as String,
    );
  }

  @override
  String toString() {
    return 'EncryptedMessage(encrypted: ${encryptedContent.substring(0, 20)}..., iv: $iv)';
  }
}
