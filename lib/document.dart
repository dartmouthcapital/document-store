import 'dart:async';
import 'db/resource_model.dart';

// Base Document class
class Document {
    String collection = 'documents';
    String id;
    String path;
    ResourceModel _resource;

    Document([this.id]);

    Document.fromJson(Map json) :
            this.id = json['id'],
            this.path = json['path'];

    Map toJson() => {
        'id': id,
        'path': path
    };

    // Get the resource model for interacting with the DB.
    ResourceModel resource () {
        if (_resource == null) {
            _resource = resourceFactory({'collection': collection});
        }
        return _resource;
    }

    // Load the document from the file store.
    Future<bool> load([String newId = null]) {
        if (newId != null) {
            id = newId;
        }
        return resource().findById(id).then((Map data) {
            if (data.length > 0) {
                path = data['path'];
                return true;
            }
            else {
                return false;
            }
        });
    }

    // Save the document to the file store.
    Future<bool> save() {
        if (id == null) {
            return resource().insert(toJson()).then((newId) {
                if (newId != null) {
                    id = newId;
                    return true;
                }
                return false;
            });
        }
        else {
            return resource().update(toJson());
        }
    }

    // Delete the document from the file store.
    // Returns true if the document was found and deleted, and false otherwise.
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