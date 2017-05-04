import 'dart:convert';
import 'dart:io' show HttpStatus;

import 'package:shelf/shelf.dart';
import 'package:shelf_exception_handler/shelf_exception_handler.dart';
import 'package:test/test.dart';
import '../lib/store/resource.dart';
import '../lib/router.dart' as app;
import '../lib/user.dart';
import 'helper.dart';

main() async {
    await initTestConfig();
    Handler handler = const Pipeline()
        .addMiddleware(exceptionHandler())
        .addMiddleware(app.appMiddleware)
        .addHandler(app.appRouter.handler);

    const String username = 'tester';
    const String password = 'secret';
    new User()
        ..username = username
        ..password = password
        ..save();

    Request createRequest(String method, String path, {String body: '', Map headers: null}) {
        if (headers == null) {
            headers = {};
        }
        if (!headers.containsKey('Authorization')) {
            headers['Authorization'] =
                'Basic ' + BASE64.encode(UTF8.encode(username + ':' + password));
        }
        return new Request(
            method,
            Uri.parse('http://localhost:9999${path}'),
            body: UTF8.encode(body),
            headers: headers
        );
    }

    tearDown(() async {
        await storageFactory('local').purge();
    });

    group('Testing authentication and OPTIONS', () {
        test('OPTIONS / 200', () async {
            Request request = createRequest('OPTIONS', '/');
            Response response = await handler(request);
            expect(response.statusCode, equals(HttpStatus.OK));
        });

        test('OPTIONS / 400', () async {
            Request request = createRequest('OPTIONS', '/', headers: {'Authorization': 'badauth'});
            Response response = await handler(request);
            expect(response.statusCode, equals(HttpStatus.BAD_REQUEST));
        });

        test('OPTIONS / 401', () async {
            String auth = 'Basic ' + BASE64.encode(UTF8.encode('test:nevermatch'));
            Request request = createRequest('OPTIONS', '/', headers: {'Authorization': auth});
            Response response = await handler(request);
            expect(response.statusCode, equals(HttpStatus.UNAUTHORIZED));
        });
    });

    group('Testing 404 routes', () {
        test('GET /bad/route', () async {
            Request request = createRequest('GET', '/bad/route');
            Response response = await handler(request);
            expect(response.statusCode, equals(HttpStatus.NOT_FOUND));
        });

        test('POST /bad/route', () async {
            Request request = createRequest('POST', '/bad/route');
            Response response = await handler(request);
            expect(response.statusCode, equals(HttpStatus.NOT_FOUND));
        });

        test('DELETE /bad/route', () async {
            Request request = createRequest('DELETE', '/bad/route');
            Response response = await handler(request);
            expect(response.statusCode, equals(HttpStatus.NOT_FOUND));
        });

        test('GET /bogusId', () async {
            Request request = createRequest('GET', '/bogusId');
            Response response = await handler(request);
            expect(response.statusCode, equals(HttpStatus.NOT_FOUND));
        });

        test('DELETE /bogusId', () async {
            Request request = createRequest('DELETE', '/bogusId');
            Response response = await handler(request);
            expect(response.statusCode, equals(HttpStatus.NOT_FOUND));
        });
    });

    group('Testing 405 routes', () {
        test('PUT /bad/route', () async {
            Request request = createRequest('PUT', '/bad/route');
            Response response = await handler(request);
            expect(response.statusCode, equals(HttpStatus.METHOD_NOT_ALLOWED));
        });

        test('HEAD /bad/route', () async {
            Request request = createRequest('HEAD', '/bad/route');
            Response response = await handler(request);
            expect(response.statusCode, equals(HttpStatus.METHOD_NOT_ALLOWED));
        });
    });

    group('Testing POST/GET/DELETE cycle', () {
        var docId;
        test('POST new document', () async {
            Request request = createRequest(
                'POST',
                '/',
                body: 'text content',
                headers: {'content-type': 'text/plain'}
            );
            Response response = await handler(request);
            expect(response.statusCode, equals(HttpStatus.OK));
            Map body = JSON.decode(await response.readAsString());
            expect(body.containsKey('id'), isTrue);
            expect(body['id'], isNotNull);
            expect(body.containsKey('content_type'), isTrue);
            expect(body['content_type'], equals('text/plain'));
            docId = body['id'];
        });

        test('GET POST\'ed document', () async {
            Request request = createRequest('GET', '/' + docId);
            Response response = await handler(request);
            expect(response.statusCode, equals(HttpStatus.OK));
            String body = await response.readAsString();
            expect(body, equals('test file contents'));
        });

        test('DELETE POST\'ed document', () async {
            Request request = createRequest('DELETE', '/' + docId);
            Response response = await handler(request);
            expect(response.statusCode, equals(HttpStatus.OK));
        });
    });

    group('Testing POST with directory', () {
        var docId;
        test('POST new document', () async {
            Request request = createRequest(
                'POST',
                '/?directory=subdir',
                body: 'text content',
                headers: {'content-type': 'text/plain'}
            );
            Response response = await handler(request);
            expect(response.statusCode, equals(HttpStatus.OK));
            Map body = JSON.decode(await response.readAsString());
            expect(body.containsKey('id'), isTrue);
            expect(body['id'], isNotNull);
            expect(body.containsKey('content_type'), isTrue);
            expect(body['content_type'], equals('text/plain'));
            expect(body.containsKey('directory'), isTrue);
            expect(body['directory'], equals('subdir'));
            docId = body['id'];
        });

        test('GET POST\'ed document', () async {
            Request request = createRequest('GET', '/' + docId);
            Response response = await handler(request);
            expect(response.statusCode, equals(HttpStatus.OK));
            String body = await response.readAsString();
            expect(body, equals('test file contents'));
        });
    });
}