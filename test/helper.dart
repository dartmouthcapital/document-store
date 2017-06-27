import 'dart:async';
import 'dart:io';
import 'package:dart_config/default_server.dart';
import 'package:dart_ext/collection_ext.dart' show merge;
import '../lib/config.dart';

Future initTestConfig([String additionalFile = null]) async {
    File testFile = new File('test/config.yaml');
    Map testConfig = testFile.existsSync() ? await loadConfig('test/config.yaml') : {};
    if (additionalFile != null) {
        Map additionalConfig = await loadConfig(additionalFile);
        testConfig = merge(testConfig, additionalConfig);
    }
    await Config.ready(testConfig);
    if (!Config.get('db/mongodb/db_name').contains('test')) {
        throw 'Test DB must contain "test".';
    }
    Config.set('storage/adapter', 'test');
    Config.set('storage/resize_max_width', 500);
}
