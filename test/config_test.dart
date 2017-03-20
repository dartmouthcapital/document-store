// Config class test suite
import 'package:dart_config/default_server.dart';
import 'package:test/test.dart';
import '../lib/config.dart';

main() async {
    Map baseConfig = await loadConfig('test/config.yaml');
    Map testConfig = await loadConfig('test/configs/config_test.yaml');
    Map allConfig = new Map()
        ..addAll(baseConfig)
        ..addAll(testConfig);
    new Config(allConfig);  // initialize the config

    test('get', () {
        expect(Config.get('test_key'), equals('test_value'));
        expect(Config.get('test_map/test_key1'), equals('test_value1'));
        expect(Config.get('test_map/test_key2/test_sub_key'), equals('test_sub_value'));
        expect(Config.get('bogus_key'), equals(null));
        expect(Config.get('bogus_map/bogus_key'), equals(null));
    });

    test('set', () {
        Config.set('new_key', 'new_value');
        expect(Config.get('new_key'), equals('new_value'));
        Config.set('test_key', 'override_value');
        expect(Config.get('test_key'), equals('override_value'));
        Config.set('new_map/new_key', 'new_value');
        expect(Config.get('new_map/new_key'), equals('new_value'));
    });
}
