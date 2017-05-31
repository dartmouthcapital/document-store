import 'dart:async';
import 'dart:convert';
import 'resource.dart';

/// Abstract model for interacting with the DB.
abstract class Model {
    DbResource _resource;
    DateTime created;

    /// Collection/table for interacting with the DB.
    String get collection;

    /// Access to model's ID in the DB.
    String get id;
    set id (String newId);

    /// Get the resource model for interacting with the DB.
    DbResource get resource {
        if (_resource == null) {
            _resource = new DbResource({'collection': collection});
        }
        return _resource;
    }

    /// Prepare the model for saving in the DB.
    Map toMap();

    /// Populate the model with data from the DB.
    void fromMap(Map map);

    String toJson() => JSON.encode(toMap());

    /// Load the model from the file store.
    /// Optionally specify 'field' to load by a field other than ID.
    Future<bool> load([String id = null, String field = 'id']) async {
        if (id != null && field == 'id') {
            this.id = id;
        }
        Map data;
        if (field == 'id') {
            data = await resource.findById(this.id);
        }
        else {
            List results = await resource.find({field: id});
            data = results.length > 0 ? results.first : {};
        }
        if (data.length > 0) {
            if (data.containsKey('id')) {
                this.id = data['id'];
            }
            if (data.containsKey('created')) {
                created = DateTime.parse(data['created']);
            }
            fromMap(data);
            return true;
        }
        return false;
    }

    /// Save the model to the DB.
    Future<bool> save() async {
        if (id == null) {  // insert
            Map map = toMap();
            if (!map.containsKey('created')) {
                created = new DateTime.now();
                map['created'] = created.toUtc().toIso8601String();
            }
            var newId = await resource.insert(map);
            if (newId != null) {
                id = newId;
                return true;
            }
            return false;
        }
        else {  // update
            return resource.update(toMap());
        }
    }

    /// Delete the model from the file store.
    /// Optionally specify 'field' to delete by a field other than ID.
    Future<bool> delete([String id = null, String field = 'id']) async {
        if (id == null) {
            id = this.id;
        }
        if (id == null) {
            throw 'Cannot delete model without an ID.';
        }
        if (field == 'id') {
            return resource.deleteById(id);
        }
        else {
            return resource.delete({field: id});
        }
    }
}