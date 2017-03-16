import 'dart:convert';
import 'dart:io' show HttpStatus;

import 'package:dart_config/default_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_exception_handler/shelf_exception_handler.dart';
import 'package:test/test.dart';

import '../lib/config.dart';
import '../lib/router.dart' as app;

main() async {
    Map configMap = await loadConfig('test/config_test.yaml');
    new Config(configMap); // initialize the config
    if (!Config.get('db_name').contains('test')) {
        throw 'Test DB must contain "test".';
    }

    Handler handler = const Pipeline()
        .addMiddleware(exceptionHandler())
        .addMiddleware(app.appMw)
        .addHandler(app.appRouter.handler);

    Request createRequest(String method, String path, {String body: ''}) {
        return new Request(method,
            Uri.parse('http://localhost:9999${path}'),
            body: UTF8.encode(body) //new Stream.fromFuture(new Future.value(UTF8.encode(body)))
        );
    }

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
            Request request = createRequest('POST', '/', body: '{"path": "a/doc.pdf"}');
            Response response = await handler(request);
            expect(response.statusCode, equals(HttpStatus.OK));
            Map body = JSON.decode(await response.readAsString());
            expect(body.containsKey('id'), isTrue);
            expect(body['path'], equals('a/doc.pdf'));
            docId = body['id'];
        });

        test('GET POST\'ed document', () async {
            Request request = createRequest('GET', '/' + docId);
            Response response = await handler(request);
            expect(response.statusCode, equals(HttpStatus.OK));
            Map body = JSON.decode(await response.readAsString());
            expect(body['id'], equals(docId));
            expect(body['path'], equals('a/doc.pdf'));
        });

        test('DELETE POST\'ed document', () async {
            Request request = createRequest('DELETE', '/' + docId);
            Response response = await handler(request);
            expect(response.statusCode, equals(HttpStatus.OK));
        });

    });
}