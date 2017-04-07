import 'dart:async';
import 'package:dart_config/default_server.dart';
import '../lib/config.dart';

Future initTestConfig () async {
    await Config.ready('test/config.yaml');
    if (!Config.get('db/mongodb/db_name').contains('test')) {
        throw 'Test DB must contain "test".';
    }
}
