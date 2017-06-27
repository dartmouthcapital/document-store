import 'dart:async';
import 'dart:convert' show BASE64;
import 'dart:math' show Random;
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto show sha256;
import 'package:googleapis_auth/auth_io.dart';
import 'package:gcloud/storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_exception/http_exception.dart';
import 'resource.dart';

/// Google Cloud storage class
/// See https://github.com/dart-lang/gcloud
class GCloudStore extends EncryptableStoreResource {
    static Map<String, Bucket> buckets = {};
    static GCloudStoreClient _client;
    String project;
    String bucketName;
    String accountCredentials;

    GCloudStore(this.project, this.bucketName, this.accountCredentials);

    /// Add a new object to the store
    Future<bool> write(String name, List<int> bytes, {String contentType}) async {
        if (name == null) {
            throw new BadRequestException({}, 'Name is required.');
        }
        try {
            await bucket.writeBytes(name, bytes, contentType: contentType);
            return true;
        } catch (e) {
            throw _handleException(e);
        }
    }

    /// Fetch an object from the store
    Stream<List<int>> read(String name) {
        return bucket.read(name).handleError((e) {
            throw _handleException(e);
        });
    }

    /// Delete an object from the store
    Future<bool> delete(String name) async {
        try {
            await bucket.delete(name);
            return true;
        } catch (e) {
            throw _handleException(e);
        }
    }

    /// Purge all files from the store - not available
    Future<bool> purge() => new Future.value(false);

    /// Authorize the app with Google
    Future<bool> ready() async {
        if (project == null || bucketName == null) {
            throw new GCloudException('Both project and bucket name must be specified.');
        }
        var bucketKey = project + '-' + bucketName;
        if (GCloudStore.buckets.containsKey(bucketKey)) {
            return new Future.value(true);
        }
        var credentials = new ServiceAccountCredentials.fromJson(accountCredentials);
        // Get an HTTP authenticated client using the service account credentials.
        var scopes = []
            ..addAll(Storage.SCOPES);
        var apiClient = await clientViaServiceAccount(credentials, scopes, baseClient: client);

        // Instantiate objects to access Cloud Storage API.
        if (project == null || bucketName == null) {
            throw new BadRequestException({}, 'GCloud project and bucket name must be specified.');
        }
        try {
            var storage = new Storage(apiClient, project);
            if (await storage.bucketExists(bucketName)) {
                GCloudStore.buckets[bucketKey] = storage.bucket(bucketName);
                return true;
            }
            else {
                throw new NotFoundException({}, 'GCloud bucket "{$bucketName}" does not exist.');
            }
        } catch (e) {
            throw _handleException(e);
        }
    }

    /// Close the store connection
    void close() {
        client.close();
        _client = null;
    }

    Bucket get bucket => GCloudStore.buckets[project + '-' + bucketName];

    GCloudStoreClient get client {
        if (_client == null) {
            _client = new GCloudStoreClient();
        }
        return _client;
    }

    /// Returns the encryption key used, if available
    String get encryptionKey => client.encryptionKey;

    /// Set the encryption key to be used, if available
    set encryptionKey(String key) => client.encryptionKey = key;

    /// Generate a new encryption key
    String generateKey() {
        return client.generateKey();
    }

    _handleException(e) {
        if (e is HttpException || e is Error) {
            return e;
        }
        try {
            switch (e.status) {
                case 400:
                    return new BadRequestException();
                case 403:
                    return new ForbiddenException();
                case 404:
                    return new NotFoundException();
                case 405:
                    return new MethodNotAllowed();
            }
        } catch (f) {}  // e.status doesn't exist

        return e;
    }
}

/// GCloud HTTP client for managing customer-supplied encryption.
class GCloudStoreClient extends http.IOClient {
    EncryptionKey keyGen;

    GCloudStoreClient([this.keyGen]);

    String get encryptionKey {
        if (keyGen != null) {
            return keyGen.key;
        }
        return '';
    }

    set encryptionKey(String key) {
        if (key == null || key.isEmpty) {
            keyGen = null;
        }
        else {
            keyGen == null
                ? keyGen = new EncryptionKey(key)
                : keyGen.key = key;
        }
    }

    /// Generate a new encryption key
    String generateKey() {
        keyGen = new EncryptionKey();
        return keyGen.key;
    }

    Future<http.StreamedResponse> send(request) {
        if (keyGen != null) {
            request.headers['x-goog-encryption-algorithm'] = keyGen.algorithm;
            request.headers['x-goog-encryption-key'] = keyGen.key;
            request.headers['x-goog-encryption-key-sha256'] = keyGen.keyHash;
        }
        return super.send(request);
    }
}

/// Encryption key generation and encoding.
class EncryptionKey {
    final String algorithm = 'AES256';
    Uint8List _key;

    EncryptionKey([String base64Key]) {
        if (base64Key != null) {
            key = base64Key;
        }
    }

    /// Set a Base64-encoded string of the key.
    set key (String base64Key) => _key = new Uint8List.fromList(BASE64.decode(base64Key));

    /// Base64-encoded string of key;
    String get key {
        if (_key == null) {
            _generate();
        }
        return BASE64.encode(_key);
    }

    /// Base64-encoded string of hash of key.
    String get keyHash {
        if (_key == null) {
            _generate();
        }
        return BASE64.encode(crypto.sha256.convert(_key).bytes);
    }

    Map toMap() => {'key': key};

    void fromMap(Map data) {
        if (data.containsKey('key')) {
            key = data['key'];
        }
    }

    String toString() => key;

    /// Generate random bytes to form the encryption key.
    void _generate ([int length = 32]) {
        var generator = new Random.secure();
        _key = new Uint8List(length);
        for (var i = 0; i < length; i++) {
            _key[i] = generator.nextInt(256);
        }
    }
}

class GCloudException implements Exception
{
    final message;

    GCloudException([this.message]);

    String toString() {
        if (message == null) {
            return 'GCloudException';
        }
        return 'GCloudException: $message';
    }
}
