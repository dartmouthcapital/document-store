import 'dart:async';
import 'dart:convert';
import 'db/resource.dart';
import 'mime_type.dart' as mime;
import 'store/resource.dart';

/// Base Document class
class Document {
    String collection = 'documents';
    String id;
    String contentType;
    List<int> content;

    AbstractResource _resource;
    AbstractStore _store;

    Document([this.id]);

    Document.fromJson(Map json) :
            this.id = json['id'],
            this.contentType = json['content_type'];

    Map toMap() => {
        'id': id,
        'content_type': contentType
    };

    String toJson() => JSON.encode(toMap());

    String get name => id + '.' + mime.extension(contentType);

    /// Get the resource model for interacting with the DB.
    AbstractResource resource() {
        if (_resource == null) {
            _resource = resourceFactory({'collection': collection});
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
    Future<bool> load([String newId = null]) {
        if (newId != null) {
            id = newId;
        }
        return resource().findById(id).then((Map data) async {
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
        if (id == null) {
            var newId = await resource().insert(toMap());
            if (newId != null) {
                id = newId;
                await store().ready();
                return store().write(name, content);
            }
            return false;
        }
        else {
            await resource().update(toMap());
            await store().ready();
            return store().write(name, content);
        }
    }

    /// Delete the document from the file store.
    /// Returns true if the document was found and deleted, and false otherwise.
    Future<bool> delete() async {
        if (id == null) {
            throw 'Cannot delete file without an ID.';
        }
        if (await load()) {
            if (await store().delete(name)) {
                return resource().deleteById(id);
            }
            throw 'Error deleting document.';
        }
        return new Future.value(false);
    }
}