library mime_type;

import 'dart:convert';
import 'dart:io';

/// Get the default extension for a MIME type.
///
/// See https://github.com/jshttp/mime-db and https://github.com/jshttp/mime-types
///
/// TODO: Turn this into a proper library

String _db = new File('lib/mime_type/db.json').readAsStringSync();
Map _mimeTypes = JSON.decode(_db);

String extension (String contentType) {
    if (_mimeTypes.containsKey(contentType)) {
        Map typeInfo = _mimeTypes[contentType];
        if (typeInfo.containsKey('extensions') && typeInfo['extensions'].length > 0) {
            return typeInfo['extensions'].first;
        }
    }
    return null;
}
