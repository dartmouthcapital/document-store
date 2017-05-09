import 'dart:async';
import 'dart:io';
import 'resource.dart';

/// Local, file system storage class
class LocalStore extends StoreResource {
    String filePath;
    Directory _storageDirectory;

    LocalStore(String baseDirectory) {
        _storageDirectory = new Directory(baseDirectory);
        if (!_storageDirectory.existsSync()) {
            _storageDirectory.createSync();
        }
    }
    
    String get storagePath => _storageDirectory.path;
    File _file(String name) {
        // remove subdirectories
        List parts = name.split(new RegExp(r'/|\\'));
        name = parts.length == 1 ? name : parts.last;
        return new File(_storageDirectory.path + Platform.pathSeparator + name);
    }

    /// Fetch an object from the store
    Stream<List<int>> read(String name) {
        File file = _file(name);
        if (!file.existsSync()) {
            throw new Exception('File does not exist.');
        }
        return file.openRead();
    }

    /// Add a new object to the store
    Future<bool> write(String name, List<int> bytes, {String contentType}) {
        return _file(name)
            .writeAsBytes(bytes)
            .then((file) => true);
    }

    /// Add a new object in stream form to the store
    Future streamWrite(String name, Stream<List<int>> byteStream) async {
        File file = _file(name);
        IOSink output = file.openWrite();
        await for (List<int> bytes in byteStream) {
            output.add(bytes);
        }
        output.close();
    }

    /// Open a write sink for a given file
    IOSink writeSink(String name) {
        return _file(name).openWrite();
    }

    /// Delete an object from the store
    Future<bool> delete(String name) {
        return _file(name)
            .delete()
            .then((fse) => true)
            .catchError((e) => false);
    }

    /// Delete an object from the store synchronously
    bool deleteSync(String name) {
        try {
            _file(name).deleteSync();
            return true;
        } catch (e) {
            return false;
        }
    }

    /// Returns when the store is ready to process
    Future<bool> ready() => new Future.value(true);

    /// Purge all files from the store
    Future<bool> purge() async {
        await for (FileSystemEntity file in _storageDirectory.list(followLinks: false)) {
            if (file is File) {
                await file.delete();
            }
        }
        return true;
    }

    /// Does the file exist in the store?
    Future<bool> exists(String name) {
        return _file(name).exists();
    }

    /// Does the file exist in the store?
    bool existsSync(String name) {
        return _file(name).existsSync();
    }
}