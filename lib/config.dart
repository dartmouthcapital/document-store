import 'dart:async';
import 'dart:io';
import 'package:dart_config/default_server.dart';
import 'package:dart_ext/collection_ext.dart' show merge;

/// Singleton config class
class Config {
    static Config _singleton;
    Map _config;

    factory Config([Map config = null]) {
        if (_singleton == null) {
            if (config == null) {
                throw 'Configuration must be specified when instantiating first instance.';
            }
            _singleton = new Config._internal(new Map.from(config));
        }
        return _singleton;
    }

    Config._internal(this._config);

    /// Initialize the config.
    static Future ready([Map overrides = null]) async {
        Map defaultConfig = await loadConfig('config_default.yaml');
        File localFile = new File('config.yaml');
        Map localConfig = localFile.existsSync() ? await loadConfig('config.yaml') : {};
        Map merged = merge(defaultConfig, localConfig);
        new Config(merge(merged, overrides));  // initialize the config
    }

    /// Get a field from the config.
    /// Environment variables will be searched first.
    static get(String key) {
        String env = key.replaceAll('/', '_').toUpperCase();
        if (Platform.environment.containsKey(env)) {
            return Platform.environment[env];
        }

        var parts = key.split('/'),
            last = parts.removeLast(),
            instance = new Config(),
            map = instance._config;

        for (var part in parts) {
            if (map.containsKey(part)) {
                map = map[part];
            }
            else {
                return null;
            }
        }
        if (map != null && map.containsKey(last)) {
            return map[last];
        }
        return null;
    }

    /// Get a field from the config, but first try to pull its value from a file, assuming the file
    /// path is also in the config, appended with "_file".
    static getFile(String key) {
        String filePath = Config.get(key + '_file');
        return filePath != null
            ? new File(filePath).readAsStringSync()
            : Config.get(key);
    }

    /// Set a field in the config.
    static set(String key, value) {
        var parts = key.split('/'),
            last = parts.removeLast(),
            instance = new Config(),
            map = instance._config;

        for (var part in parts) {
            if (!map.containsKey(part)) {
                map[part] = {};
            }
            map = map[part];
        }
        map[last] = value;
    }

    /// Important directories for the app
    static String get appPath => Directory.current.absolute.path;
    static String get tempPath => appPath + Platform.pathSeparator + 'var';
}