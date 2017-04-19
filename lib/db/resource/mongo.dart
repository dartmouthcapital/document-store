import 'dart:async';
import 'package:connection_pool/connection_pool.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../resource.dart';

/// MongoDB resource model
class MongoResource implements DbResource {
    static MongoPool _pool;
    String collectionName;

    MongoResource(String databaseName, String databaseUrl, int databasePoolSize, {Map auth, String collection}) {
        if (_pool == null) {
            _pool = new MongoPool(
                databaseUrl + databaseName,
                databasePoolSize,
                auth != null ? auth['username'] : null,
                auth != null ? auth['password'] : null,
                auth != null ? auth['source'] : null
            );
        }
        collectionName = collection;
    }

    /// Insert a new object into the collection.
    Future<String> insert(Map data) {
        _checkCollection();
        assert(data['_id'] == null);
        data['_id'] = new ObjectId().toHexString();
        data.remove('id');
        return _pool.getConnection().then((ManagedConnection mc) {
            Db db = mc.conn;
            DbCollection collection = db.collection(collectionName);
            return collection.insert(data).then((status) {
                _pool.releaseConnection(mc);
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
        return _pool.getConnection().then((ManagedConnection mc) {
            Db db = mc.conn;
            DbCollection collection = db.collection(collectionName);
            return collection.update(query, data).then((status) {
                _pool.releaseConnection(mc);
                return (status['ok'] == 1) ? true : false;
            });
        });
    }

    /// Query the collection.
    Future<List> find(Map query) {
        _checkCollection();
        return _pool.getConnection().then((ManagedConnection mc) async {
            DbCollection collection = new DbCollection(mc.conn, collectionName);
            List<Map> list = await collection.find(query).toList();
            _standardize(list);
            _pool.releaseConnection(mc);
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
        return _pool.getConnection().then((ManagedConnection mc) {
            Db database = mc.conn;
            DbCollection collection = database.collection(collectionName);
            return collection.remove(query).then((status) {
                _pool.releaseConnection(mc);
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
    String _username;
    String _password;
    String _authSource;

    MongoPool(String this.uri, int poolSize, [String this._username, String this._password, String this._authSource])
        : super(poolSize);

    Future<Db> openNewConnection() async {
        String uri = this.uri + (_authSource != null ? '?authSource=$_authSource' : '');
        Db db = new Db(uri);
        await db.open();
        if (_username != null && _password != null) {
            await db.authenticate(_username, _password);
        }
        return db;
    }

    void closeConnection(Db db) {
        db.close();
    }
}