import 'dart:async';
import 'dart:convert' show UTF8;
import 'package:gcloud/storage.dart';
import 'package:http_exception/http_exception.dart';
import 'gcloud.dart';
import 'resource.dart';

const String testEncryptionKey = '0PkKJMC0TR6Erq1KE19NLLeNhtwMyaw3vox1eIXmyUs=';

/// Test storage adapter
class TestStore implements StoreResource {
    String encryptionKey = testEncryptionKey;

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

/// Test GCloud storage adapter
class TestGCloudStore extends GCloudStore {
    TestGCloudStore(client): super(client) {
        GCloudStore.bucket = new TestGCloudBucket();
    }
}

/// Test GCloud bucket implementation
class TestGCloudBucket implements Bucket {
    String bucketName = 'test-bucket';
    String absoluteObjectName(String objectName) => 'test//' + bucketName + '/' + objectName;

    Future<ObjectInfo> writeBytes(String name, List<int> bytes,
        {ObjectMetadata metadata,
            Acl acl, PredefinedAcl predefinedAcl, String contentType}) {
        if (name.contains('fail')) {
            return new Future.error('Write error');
        }
        return new Future.value(new TestObjectInfo()..name = name);
    }

    Stream<List<int>> read(String objectName, {int offset, int length}) {
        if (objectName.contains('fail')) {
            throw new NotFoundException();
        }
        List<List<int>> bytes = [
            UTF8.encode('test'),
            UTF8.encode(' file'),
            UTF8.encode(' contents')
        ];
        return new Stream.fromIterable(bytes);
    }

    Future delete(String name) {
        if (name.contains('fail')) {
            return new Future.error('Delete error');
        }
        return new Future.value(true);
    }

    Future<ObjectInfo> info(String name) => new Future.value(new TestObjectInfo()..name = name);

    StreamSink<List<int>> write(String objectName,
        {int length, ObjectMetadata metadata,
            Acl acl, PredefinedAcl predefinedAcl, String contentType}) {
        throw 'Not implemented.';
    }

    Future updateMetadata(String objectName, ObjectMetadata metadata) {
        throw 'Not implemented.';
    }

    Stream<BucketEntry> list({String prefix}) {
        throw 'Not implemented.';
    }

    Future<Page<BucketEntry>> page({String prefix, int pageSize: 50}) {
        throw 'Not implemented.';
    }
}

class TestObjectInfo implements ObjectInfo {
    String name = 'test';
    int length = 4;
    DateTime get updated => new DateTime.now();
    String etag = 'etag-test';
    List<int> md5Hash = [1,2,3,4];
    int crc32CChecksum = 16;
    Uri get downloadLink => new Uri(scheme: 'http', host: 'test.com');
    ObjectGeneration get generation => new ObjectGeneration('gen', 1);
    ObjectMetadata get metadata => new ObjectMetadata();
}
