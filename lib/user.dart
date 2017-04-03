import 'dart:async';
import 'package:dbcrypt/dbcrypt.dart';
import 'db/model.dart';

/// API access user
class User extends Model {
    String _id;
    String username;
    String password;
    String passwordHash;

    User([this._id]);

    /// Prepare the model for saving in the DB.
    Map toMap() {
        Map data = {
            'id': _id,
            'username': username
        };
        if (password != null) {
            passwordHash = new DBCrypt().hashpw(password, new DBCrypt().gensalt());
        }
        if (passwordHash != null) {
            data['password_hash'] = passwordHash;
        }
        return data;
    }

    /// Populate the model with data from the DB.
    void fromMap(Map map) {
        if (map.containsKey('username')) {
            username = map['username'];
        }
        if (map.containsKey('password_hash')) {
            passwordHash = map['password_hash'];
        }
    }

    String get collection => 'users';
    String get id => _id;
    set id (String newId) => _id = newId;

    /// Create a new user by username and password, and return its ID.
    Future<String> register (String username, String password) async {
        User user = new User()
            ..username = username
            ..password = password;
        if (await user.save()) {
            return user.id;
        }
        throw new Exception('Unable to register user.');
    }

    Future<bool> loadByUsername (String username) {
        return load(username, 'username');
    }

    Future<bool> deleteByUsername (String username) {
        return delete(username, 'username');
    }

    /// Load and authenticate the user by username and password.
    Future<bool> authenticate (String username, String password) async {
        if (await loadByUsername(username)) {
            return new DBCrypt().checkpw(password, passwordHash);
        }
        return new Future.value(false);
    }
}