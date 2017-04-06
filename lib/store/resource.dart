import 'dart:async';
import 'gcloud.dart';
import 'test.dart';
import '../config.dart';

/// Abstract file store
abstract class StoreResource {
    String encryptionKey;

    /// Fetch an object from the store
    Stream<List<int>> read(String name);

    /// Add a new object to the store
    Future<bool> write(String name, List<int> bytes, {String contentType});

    /// Delete an object from the store
    Future<bool> delete(String name);

    /// Returns when the store is ready to process
    Future<bool> ready();

    /// Generate a new encryption key
    String generateKey();
}

// Instantiate a new storage factory.
StoreResource storageFactory() {
    String adapter = Config.get('storage/adapter');
    switch (adapter) {
        case 'test':
            return new TestStore();
        case 'gcloud':
        default:
            var client = new GCloudStoreClient();
            return new GCloudStore(client);
    }
}
