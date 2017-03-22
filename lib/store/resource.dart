import 'dart:async';
import 'gcloud.dart';
//import '../config.dart';

/// Abstract file store
abstract class AbstractStore {
    /// Fetch an object from the store
    Stream<List<int>> read(name);

    /// Add a new object to the store
    Future<bool> write(name, List<int> bytes);

    /// Delete an object from the store
    Future<bool> delete(name);

    /// Returns when the store is ready to process
    Future<bool> ready();
}

// The only available resource type, at this point.
AbstractStore storageFactory() {
    return new GCloudStore();
}