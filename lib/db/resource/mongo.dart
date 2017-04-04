import 'dart:async';
import 'package:connection_pool/connection_pool.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../resource.dart';

/// MongoDB resource model
class MongoResource implements DbResource {
    String collectionName;
    MongoPool _dbPool;

    MongoResource(String databaseName, String databaseUrl, int databasePoolSize, [String collection]) {
        _dbPool = new MongoPool(databaseUrl + databaseName, databasePoolSize);
        collectionName = collection;
    }

    /// Insert a new object into the collection.
    Future<String> insert(Map data) {
        _checkCollection();
        assert(data['_id'] == null);
        data['_id'] = new ObjectId().toHexString();
        data.remove('id');
        return _dbPool.getConnection().then((ManagedConnection mc) {
            Db db = mc.conn;
            DbCollection collection = db.collection(collectionName);
            return collection.insert(data).then((status) {
                _dbPool.releaseConnection(mc);
                return (status['ok'] == 1) ? data['_id'] : null;
            });
        });
    }

    /// Update an existing item in the collection.
    Future<bool> update(Map data) {
        _checkCollection();
        String id;
        if (data.containsKey('id')) {
            id = data['id'];
            data.remove('id');
        }
        if (data.containsKey('_id')) {
            id = data['_id'];
            data.remove('_id');
        }
        assert(id != null);
        Map query = {'_id': id};
        return _dbPool.getConnection().then((ManagedConnection mc) {
            Db db = mc.conn;
            DbCollection collection = db.collection(collectionName);
            return collection.update(query, data).then((status) {
                _dbPool.releaseConnection(mc);
                return (status['ok'] == 1) ? true : false;
            });
        });
    }

    /// Query the collection.
    Future<List> find(Map query) {
        _checkCollection();
        return _dbPool.getConnection().then((ManagedConnection mc) async {
            DbCollection collection = new DbCollection(mc.conn, collectionName);
            List<Map> list = await collection.find(query).toList();
            _standardize(list);
            _dbPool.releaseConnection(mc);
            return list;
        });
    }

    /// Load an item by ID.
    Future<Map> findById(String id) {
        _checkCollection();
        assert(id != null);
        return find({'_id': id}).then((List items) {
            if (items.length > 0) {
                _standardize(items);
                return items.first;
            }
            return {};
        });
    }

    /// Delete based on the provided query.
    Future<bool> delete(Map query) {
        _checkCollection();
        return _dbPool.getConnection().then((ManagedConnection mc) {
            Db database = mc.conn;
            DbCollection collection = database.collection(collectionName);
            return collection.remove(query).then((status) {
                _dbPool.releaseConnection(mc);
                return status['ok'] == 1 && status['n'] > 0;
            });
        });
    }

    /// Delete an item by ID.
    Future<bool> deleteById(String id) {
        assert(id != null);
        return delete({'_id': id});
    }

    /// Delete all objects from a collection.
    Future<bool> truncate() {
        return delete({});
    }

    void _checkCollection() {
        if (collectionName == null) {
            throw 'Collection name must be specified.';
        }
    }

    /// Convert the internal _id field to a non-underscored field.
    void _standardize(List<Map> items) {
        for (Map item in items) {
            if (item.containsKey('_id')) {
                item['id'] = item['_id'];
                item.remove('_id');
            }
        }
    }
}

/// Mongo connection pool
class MongoPool extends ConnectionPool<Db> {
    String uri;
    MongoPool(String this.uri, int poolSize) : super(poolSize);

    Future<Db> openNewConnection() {
        var conn = new Db(uri);
        return conn.open().then((_) => conn);
    }

    void closeConnection(Db conn) {
        conn.close();
    }
}