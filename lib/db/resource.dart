import 'dart:async';
import '../config.dart';
import 'resource/mongo.dart';

/// Base resource model
abstract class DbResource {
    /// Insert a new object into the store.
    Future<String> insert(Map data);

    /// Update an existing item in the store.
    Future<bool> update(Map data);

    /// Query the store.
    Future<List> find(Map query);

    /// Load an item by ID.
    Future<Map> findById(String id);

    /// Delete based on the provided query.
    Future<bool> delete(Map query);

    /// Delete an item by ID.
    Future<bool> deleteById(String id);

    /// Delete all objects from a collection.
    Future<bool> truncate();
}

// The only available resource type, at this point.
DbResource resourceFactory([Map customParams]) {
    var resource = new MongoResource(
        Config.get('db_name'),
        Config.get('db_uri'),
        Config.get('db_size')
    );
    if (customParams.containsKey('collection')) {
        resource.collectionName = customParams['collection'];
    }
    return resource;
}