library mime_type;

import 'dart:convert';
import 'dart:io';

/// Get the default extension for a MIME type.
///
/// See https://github.com/jshttp/mime-db and https://github.com/jshttp/mime-types
///
/// TODO: Turn this into a proper library

String _db = new File('lib/mime_type/db.json').readAsStringSync();
Map _contentTypes = JSON.decode(_db),
    _extensions;

void _processDb() {
    if (_extensions == null) {
        _extensions = {};
        _contentTypes.forEach((type, typeInfo) {
            if (typeInfo.containsKey('extensions')) {
                for (String ext in typeInfo['extensions']) {
                    _extensions[ext] = type;
                }
            }
        });
    }
}

/// Get the default extension for a given content type.
String extension(String contentType) {
    if (_contentTypes.containsKey(contentType)) {
        Map typeInfo = _contentTypes[contentType];
        if (typeInfo.containsKey('extensions') && typeInfo['extensions'].length > 0) {
            return typeInfo['extensions'].first;
        }
    }
    return null;
}

/// Get the content type for a given extension or file path.
String contentType(String extension) {
    _processDb();
    if (extension.lastIndexOf('.') >= 0) {  // assume a file name or path
        extension = extension.substring(extension.lastIndexOf('.') + 1);
    }
    if (_extensions.containsKey(extension)) {
        return _extensions[extension];
    }
    return null;
}
