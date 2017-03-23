import 'dart:async';
import 'package:dart_config/default_server.dart';
import '../lib/config.dart';

Future initTestConfig () async {
    Map configMap = await loadConfig('test/config.yaml');
    new Config(configMap);  // initialize the config
    if (!Config.get('db_name').contains('test')) {
        throw 'Test DB must contain "test".';
    }
}
