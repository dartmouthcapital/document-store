import 'dart:async';
import 'dart:io';
import 'package:dart_config/default_server.dart';

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
    static Future ready([String configFile = 'config.yaml']) async {
        Map configMap = await loadConfig(configFile);
        new Config(configMap);  // initialize the config
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
        if (map.containsKey(last)) {
            return map[last];
        }
        return null;
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