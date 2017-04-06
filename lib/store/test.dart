import 'dart:async';
import 'dart:convert' show UTF8;
import 'package:http_exception/http_exception.dart';
import 'resource.dart';

/// Test storage adapter
class TestStore implements StoreResource {
    String encryptionKey = '0PkKJMC0TR6Erq1KE19NLLeNhtwMyaw3vox1eIXmyUs=';

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

    /// Generate a new encryption key
    String generateKey() => encryptionKey;
}