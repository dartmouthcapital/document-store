import 'dart:async';
import 'dart:io';
import 'package:http_exception/http_exception.dart';
import 'package:image/image.dart';
import 'config.dart';
import 'db/model.dart';
import 'mime_type.dart' as mime;
import 'store/local.dart';
import 'store/resource.dart';

/// Base Document class
class Document extends Model {
    String _id;
    String contentType;
    String directory;
    String encryptionKey;
    List<int> content;
    EncryptableStoreResource _remoteStore;
    LocalStore _localStore;

    Document([this._id]) {
        _localStore = new StoreResource('local');
    }

    Document.fromJson(Map json) :
            this._id = json['id'],
            this.contentType = json['content_type'],
            this.directory = json['directory'],
            this.encryptionKey = json.containsKey('encryption_key') ? json['encryption_key'] : '' {
        _localStore = new StoreResource('local');
    }

    /// Prepare the model for saving in the DB.
    Map toMap() {
        Map map = {
            'id': _id,
            'content_type': contentType
        };
        if (directory != null && directory.isNotEmpty) {
            map['directory'] = directory;
        }
        if (encryptionKey != null && encryptionKey.isNotEmpty) {
            map['encryption_key'] = encryptionKey;
        }
        return map;
    }

    /// Populate the model with data from the DB.
    void fromMap(Map map) {
        if (map.containsKey('content_type')) {
            contentType = map['content_type'];
        }
        if (map.containsKey('directory')) {
            directory = map['directory'];
        }
        encryptionKey = map.containsKey('encryption_key')
            ? encryptionKey = map['encryption_key']
            : '';
    }

    String get collection => 'documents';
    String get id => _id;
    set id (String newId) => _id = newId;

    String get name {
        String ext = mime.extension(contentType);
        if (ext == null) {
            throw new Exception('Could not determine file extension from content type.');
        }
        return (directory != null ? directory + '/' : '') + _id + '.' + ext;
    }

    /// Is the file cached in local storage?
    Future<bool> get isLocal => _localStore.exists(name);

    /// Get the storage model for reading and saving files.
    EncryptableStoreResource get store {
        if (_remoteStore == null) {
            _remoteStore = new StoreResource();
            if (encryptionKey != null) {
                _remoteStore.encryptionKey = encryptionKey;
            }
            else if (Config.get('storage/encrypt')) {
                encryptionKey = _remoteStore.generateKey();
            }
        }
        return _remoteStore;
    }

    /// Load the document from the file store.
    Future<bool> load([String id = null, String field = 'id']) async {
        if (field != 'id') {
            throw 'Loading by a field other than ID is not supported.';
        }
        if (await super.load(id, field)) {
            if (encryptionKey.isEmpty) {  // document isn't encrypted
                store.encryptionKey = '';
            }
            return true;
        }
        return false;
    }

    /// Stream file contents. The system first tries to load the file locally. If not available
    /// locally, the remote store is accessed, and a local version is cached.
    Stream<List<int>> streamContent() {
        try {
            return _localStore.read(name);
        } catch (e) {
            IOSink writeSink = _localStore.writeSink(name);
            Stream<List<int>> streamSave(Stream<List<int>> stream) async* {
                try {
                    await for (var data in stream) {
                        writeSink.add(data);
                        yield data;
                    }
                } catch (e) {
                    writeSink.close().then((_) {
                        _localStore.deleteSync(name);
                    });
                    throw e;
                }
                writeSink.close();
            }
            return streamSave(store.read(name));
        }
    }

    /// Save the document to the file store.
    Future<bool> save() async {
        if (content == null) {
            throw 'Document content has not been set.';
        }
        _resizeImage();
        store;  // make sure the store is initialized (ie. encryption key generated)
        await super.save();
        try {
            await _localStore.write(name, content);  // cache local copy
            return store.write(name, content, contentType: contentType);
        } catch (e) {
            await super.delete();
            throw e;
        }
    }

    /// Delete the document from the file store.
    /// Returns true if the document was found and deleted, and false otherwise.
    Future<bool> delete([String id = null, String field = 'id']) async {
        if (field != 'id') {
            throw 'Document deletion must only be by ID.';
        }
        if (_id == null) {
            throw 'Cannot delete file without an ID.';
        }
        if (await load()) {
            if (await store.delete(name)) {
                _localStore.delete(name);  // clear local cache
                return super.delete();
            }
            throw 'Error deleting document.';
        }
        return false;
    }

    bool _canResize () {
        switch (contentType) {
            case 'image/png':
            case 'image/jpeg':
            case 'image/gif':
                return true;
            default:
                return false;
        }
    }

    void _resizeImage () {
        var maxWidth = Config.get('storage/resize_max_width');
        if (_canResize() && maxWidth is int && maxWidth > 0) {
            Image original;
            // Until https://github.com/brendan-duncan/image/issues/41 is fixed, 8-bit PNGs are
            // corrupted by the images package. Clone the content here so it's not affected.
            List<int> imageData = new List.from(content);
            try {
                switch (contentType) {
                    case 'image/png':
                        original = new PngDecoder().decodeImage(imageData);
                        break;
                    case 'image/jpeg':
                        original = new JpegDecoder().decodeImage(imageData);
                        break;
                    case 'image/gif':
                        original = new GifDecoder().decodeImage(imageData);
                        break;
                    default:
                        original = decodeImage(imageData);
                }
            } catch (e) {
                throw new UnsupportedMediaTypeException();
            }
            if (original.width > maxWidth || original.height > maxWidth) {
                int newWidth, newHeight;
                if (original.width >= original.height) {
                    newWidth = maxWidth;
                    newHeight = -1;
                }
                else {
                    newWidth = (maxWidth * (original.width / original.height)).toInt();
                    newHeight = maxWidth;
                }
                Image resized = copyResize(original, newWidth, newHeight);
                switch (contentType) {
                    case 'image/png':
                        // see above - don't encode 8-bit PNGs
                        if (!(content[24] == 8 && content[25] == 3)) {
                            content = encodePng(resized);
                        }
                        break;
                    case 'image/jpeg':
                        content = encodeJpg(resized, quality: 90);
                        break;
                    case 'image/gif':
                        content = encodeGif(resized);
                        break;
                    // no further action by default
                }
            }
        }
    }
}