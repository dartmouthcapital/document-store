import 'dart:async';
import 'dart:convert';
import 'db/resource_model.dart';

/// Base Document class
class Document {
    String collection = 'documents';
    String id;
    String _path;
    String contentType;
    String content;

    ResourceModel _resource;

    Document([this.id]);

    Document.fromJson(Map json) :
            this.id = json['id'],
            this._path = json['path'],
            this.contentType = json['content_type'];

    Map toMap() => {
        'id': id,
        'path': _path,
        'content_type': contentType
    };

    String toJson() => JSON.encode(toMap());

    String get name => _path.split('/').last;

    /// Get the resource model for interacting with the DB.
    ResourceModel resource () {
        if (_resource == null) {
            _resource = resourceFactory({'collection': collection});
        }
        return _resource;
    }

    /// Load the document from the file store.
    Future<bool> load([String newId = null]) {
        if (newId != null) {
            id = newId;
        }
        return resource().findById(id).then((Map data) {
            if (data.length > 0) {
                _path = data['path'];
                contentType = data['content_type'];
                return true;
            }
            else {
                return false;
            }
        });
    }

    /// Save the document to the file store.
    Future<bool> save() {
        if (id == null) {
            return resource().insert(toMap()).then((newId) {
                if (newId != null) {
                    id = newId;
                    return true;
                }
                return false;
            });
        }
        else {
            return resource().update(toMap());
        }
    }

    /// Delete the document from the file store.
    /// Returns true if the document was found and deleted, and false otherwise.
    Future<bool> delete([String id = null]) {
        if (id == null) {
            id = this.id;
        }
        if (id == null) {
            throw 'Cannot delete file without an ID.';
        }
        return resource().deleteById(id);
    }
}