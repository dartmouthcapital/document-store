// Singleton config class
class Config {
    static Config _singleton;
    Map config;

    factory Config([Map config = null]) {
        if (_singleton == null) {
            if (config == null) {
                throw 'Configuration must be specified when instantiating first instance.';
            }
            _singleton = new Config._internal(new Map.from(config));
        }
        return _singleton;
    }

    Config._internal(this.config);

    // Get a field from the config.
    static get(String key) {
        var parts = key.split('/'),
            last = parts.removeLast(),
            instance = new Config(),
            map = instance.config;

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

    // Set a field in the config.
    static set(String key, value) {
        var parts = key.split('/'),
            last = parts.removeLast(),
            instance = new Config(),
            map = instance.config;

        for (var part in parts) {
            if (!map.containsKey(part)) {
                map[part] = {};
            }
            map = map[part];
        }
        map[last] = value;
    }
}