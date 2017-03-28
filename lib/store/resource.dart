import 'dart:async';
import 'dart:convert';
import 'package:http_exception/http_exception.dart';
import 'gcloud.dart';
import '../config.dart';

/// Abstract file store
abstract class AbstractStore {
    /// Fetch an object from the store
    Stream<List<int>> read(String name);

    /// Add a new object to the store
    Future<bool> write(String name, List<int> bytes, {String contentType});

    /// Delete an object from the store
    Future<bool> delete(String name);

    /// Returns when the store is ready to process
    Future<bool> ready();
}

// Instantiate a new storage factory.
AbstractStore storageFactory() {
    String adapter = Config.get('storage/adapter');
    switch (adapter) {
        case 'test':
            return new TestStore();
        case 'gcloud':
        default:
            return new GCloudStore();
    }
}

/// Test storage adapter
class TestStore implements AbstractStore {
    /// Fetch an object from the store
    /// Pass a name containing 'fail' for a negative result.
    /// Otherwise, a stream of 'test file contents' is returned.
    Stream<List<int>> read(String name) {
        if (name.contains('fail')) {
            throw new NotFoundException();
        }
        List<List<int>> bytes = [
            UTF8.encode('test'),
            UTF8.encode(' file'),
            UTF8.encode(' contents')
        ];
        return new Stream.fromIterable(bytes);
    }

    /// Add a new object to the store
    Future<bool> write(String name, List<int> bytes, {String contentType}) {
        if (name.contains('fail')) {
            return new Future.value(false);
        }
        return new Future.value(true);
    }

    /// Delete an object from the store
    Future<bool> delete(String name) {
        if (name.contains('fail')) {
            return new Future.value(false);
        }
        return new Future.value(true);
    }

    /// Returns when the store is ready to process
    Future<bool> ready() => new Future.value(true);
}
