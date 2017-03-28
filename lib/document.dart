import 'dart:async';
import 'dart:convert';
import 'package:image/image.dart';
import 'config.dart';
import 'db/resource.dart';
import 'mime_type.dart' as mime;
import 'store/resource.dart';

/// Base Document class
class Document {
    String _collection = 'documents';
    String _id;
    String contentType;
    List<int> content;

    AbstractResource _resource;
    AbstractStore _store;

    Document([this._id]);

    Document.fromJson(Map json) :
            this._id = json['id'],
            this.contentType = json['content_type'];

    Map toMap() => {
        'id': _id,
        'content_type': contentType
    };

    String toJson() => JSON.encode(toMap());

    String get id => _id;
    String get name {
        String ext = mime.extension(contentType);
        if (ext == null) {
            throw new Exception('Could not determine file extension from content type.');
        }
        return _id + '.' + ext;
    }

    /// Get the resource model for interacting with the DB.
    AbstractResource resource() {
        if (_resource == null) {
            _resource = resourceFactory({'collection': _collection});
        }
        return _resource;
    }

    /// Get the storage model for reading and saving files.
    AbstractStore store() {
        if (_store == null) {
            _store = storageFactory();
        }
        return _store;
    }

    /// Load the document from the file store.
    Future<bool> load([String id = null]) {
        if (id != null) {
            _id = id;
        }
        return resource().findById(_id).then((Map data) async {
            if (data.length > 0) {
                contentType = data['content_type'];
                return store().ready();
            }
            else {
                return false;
            }
        });
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
        if (_id == null) {
            var newId = await resource().insert(toMap());
            if (newId != null) {
                _id = newId;
                await store().ready();
                return store().write(name, content, contentType: contentType);
            }
            return false;
        }
        else {
            await resource().update(toMap());
            await store().ready();
            return store().write(name, content, contentType: contentType);
        }
    }

    /// Delete the document from the file store.
    /// Returns true if the document was found and deleted, and false otherwise.
    Future<bool> delete() async {
        if (_id == null) {
            throw 'Cannot delete file without an ID.';
        }
        if (await load()) {
            if (await store().delete(name)) {
                return resource().deleteById(_id);
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