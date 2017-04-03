library document_store;

import 'dart:async';
import 'package:image/image.dart';
import 'config.dart';
import 'db/model.dart';
import 'mime_type.dart' as mime;
import 'store/resource.dart';

/// Base Document class
class Document extends Model {
    String _id;
    String contentType;
    List<int> content;

    AbstractStore _store;

    Document([this._id]);

    Document.fromJson(Map json) :
            this._id = json['id'],
            this.contentType = json['content_type'];

    /// Prepare the model for saving in the DB.
    Map toMap() => {
        'id': _id,
        'content_type': contentType
    };

    /// Populate the model with data from the DB.
    void fromMap(Map map) {
        if (map.containsKey('content_type')) {
            contentType = map['content_type'];
        }
    }

    String get collection => 'documents';
    String get id => _id;
    set id (String newId) => _id = newId;

    String get name {
        String ext = mime.extension(contentType);
        if (ext == null) {
            throw new Exception('Could not determine file extension from content type.');
        }
        return _id + '.' + ext;
    }

    /// Get the storage model for reading and saving files.
    AbstractStore store() {
        if (_store == null) {
            _store = storageFactory();
        }
        return _store;
    }

    /// Load the document from the file store.
    Future<bool> load([String id = null, String field = 'id']) async {
        if (field != 'id') {
            throw 'Loading by a field other than ID is not supported.';
        }
        if (await super.load(id, field)) {
            return store().ready();
        }
        return new Future.value(false);
    }

    Stream<List<int>> streamContent() {
        return store().read(name);
    }

    /// Save the document to the file store.
    Future<bool> save() async {
        if (content == null) {
            throw 'Document content has not been set.';
        }
        _resizeImage();
        await super.save();
        await store().ready();
        return store().write(name, content, contentType: contentType);
    }

    /// Delete the document from the file store.
    /// Returns true if the document was found and deleted, and false otherwise.
    Future<bool> delete() async {
        if (_id == null) {
            throw 'Cannot delete file without an ID.';
        }
        if (await load()) {
            if (await store().delete(name)) {
                return super.delete();
            }
            throw 'Error deleting document.';
        }
        return new Future.value(false);
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
            Image original = decodeImage(content);
            if (original != null && original.width > maxWidth) {
                Image resized = copyResize(original, maxWidth);
                switch (contentType) {
                    case 'image/png':
                        content = encodePng(resized);
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