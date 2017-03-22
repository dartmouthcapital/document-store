import 'dart:async';
import 'package:googleapis_auth/auth_io.dart';
import 'package:gcloud/storage.dart';
import 'package:http_exception/http_exception.dart';
import 'resource.dart';
import '../config.dart';

/// Google Cloud storage class
///
/// See https://github.com/dart-lang/gcloud
class GCloudStore extends AbstractStore {
    static Storage _storage;
    static Bucket _bucket;

    /// Add a new object to the store
    Future<bool> write(name, List<int> bytes) async {
        if (name == null) {
            throw new BadRequestException({}, 'Name is required.');
        }
        try {
            await _bucket.writeBytes(name, bytes);
            return true;
        } catch (e) {
            throw _handleException(e);
        }
    }

    /// Fetch an object from the store
    Stream<List<int>> read(name) {
        try {
            return _bucket.read(name);
        } catch (e) {
            throw _handleException(e);
        }
    }

    /// Delete an object from the store
    Future<bool> delete(name) async {
        try {
            await _bucket.delete(name);
            return true;
        } catch (e) {
            throw _handleException(e);
        }
    }

    /// Authorize the app with Google
    Future<bool> ready() async {
        if (_storage == null) {
            var jsonCredentials = Config.get('gcloud/service_account');
            var credentials = new ServiceAccountCredentials.fromJson(jsonCredentials);

            // Get an HTTP authenticated client using the service account credentials.
            var scopes = []
                ..addAll(Storage.SCOPES);
            var client = await clientViaServiceAccount(credentials, scopes);

            // Instantiate objects to access Cloud Storage API.
            String project = Config.get('gcloud/project');
            String bucketName = Config.get('gcloud/bucket');
            if (project == null || bucketName == null) {
                throw new BadRequestException({}, 'GCloud project and bucket name must be specified in the config.');
            }
            try {
                _storage = new Storage(client, project);
                if (await _storage.bucketExists(bucketName)) {
                    _bucket = _storage.bucket(bucketName);
                    return true;
                }
                else {
                    throw new NotFoundException({}, 'GCloud bucket "{$bucketName}" does not exist.');
                }
            } catch (e) {
                throw _handleException(e);
            }
        }
        return new Future.value(true);
    }

    _handleException(e) {
        if (e is HttpException) {
            return e;
        }
        switch (e.status) {
            case 400:
                return new BadRequestException();
            case 403:
                return new ForbiddenException();
            case 404:
                return new NotFoundException();
            case 405:
                return new MethodNotAllowed();
            default:
                return e;
        }
    }
}