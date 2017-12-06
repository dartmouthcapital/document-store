import 'dart:async';
import 'package:connection_pool/connection_pool.dart';
// mongo_dart also has a ConnectionPool class as of 0.3.1
import 'package:mongo_dart/mongo_dart.dart' show ConnectionException, Db, DbCollection, ObjectId;
import '../resource.dart';

/// MongoDB resource model
class MongoResource implements DbResource {
    static MongoPool _pool;
    String _dbName;
    String _dbHost;
    int _dbPoolSize = 4;
    Map _dbAuth;
    String collectionName;

    MongoResource(String databaseName, String databaseHost, int databasePoolSize, {Map auth, String collection}) {
        if (databaseName == null || databaseHost == null) {
            throw new DbResourceException('Both database name and URL must be specified.');
        }
        _dbName = databaseName;
        _dbHost = databaseHost;
        _dbPoolSize = databasePoolSize;
        _dbAuth = auth;
        if (_pool == null) {
            _connect();
        }
        collectionName = collection;
    }

    /// Initialize the connection pool
    _connect() {
        _pool = new MongoPool(
            _dbHost + _dbName,
            _dbPoolSize ?? 4,
            _dbAuth != null ? _dbAuth['username'] : null,
            _dbAuth != null ? _dbAuth['password'] : null,
            _dbAuth != null ? _dbAuth['source'] : null
        );
    }

    /// Insert a new object into the collection.
    Future<String> insert(Map data) async {
        try {
            return _insert(data);
        } on ConnectionException catch (e) {
            _connect();
            return _insert(data);
        }
    }

    Future<String> _insert(Map data) {
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
    Future<bool> update(Map data) async {
        try {
            return _update(data);
        } on ConnectionException catch (e) {
            _connect();
            return _update(data);
        }
    }

    Future<bool> _update(Map data) {
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
    Future<List> find(Map query) async {
        try {
            return _find(query);
        } on ConnectionException catch (e) {
            _connect();
            return _find(query);
        }
    }

    Future<List> _find(Map query) {
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
    Future<bool> delete(Map query) async {
        try {
            return _delete(query);
        } on ConnectionException catch (e) {
            _connect();
            return _delete(query);
        }
    }

    Future<bool> _delete(Map query) {
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