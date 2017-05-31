import 'dart:async';
import 'dart:io';
import 'gcloud.dart';
import 'local.dart';
import 'test.dart';
import '../config.dart';

/// Abstract file store
abstract class StoreResource {
    /// Storage factory
    factory StoreResource([String type = null]) {
        String adapter = type ?? Config.get('storage/adapter');
        switch (adapter) {
            case 'test':
                return new TestGCloudStore();
            case 'local':
                return new LocalStore(Config.tempPath + Platform.pathSeparator + 'doc_cache');
            case 'remote':
            case 'gcloud':
            default:
                return new GCloudStore(
                    Config.get('gcloud/project'),
                    Config.get('gcloud/bucket'),
                    Config.get('gcloud/service_account')
                );
        }
    }

    /// Fetch an object from the store
    Stream<List<int>> read(String name);

    /// Add a new object to the store
    Future<bool> write(String name, List<int> bytes, {String contentType});

    /// Delete an object from the store
    Future<bool> delete(String name);

    /// Returns when the store is ready to process
    Future<bool> ready();

    /// Purge all files from the store
    Future<bool> purge();
}

/// File store that supports encryption
abstract class EncryptableStoreResource implements StoreResource {
    String encryptionKey;

    /// Generate a new encryption key
    String generateKey();
}
