#!/usr/bin/env dart
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' show serveRequests;
import 'package:shelf_exception_handler/shelf_exception_handler.dart';
import 'package:shelf_route/shelf_route.dart';

import '../lib/app.dart' as app;
import '../lib/config.dart';
import '../lib/router.dart' as appRouter;

main(List<String> args) async {
    await app.bootstrap();

    Handler handler = const Pipeline()
        .addMiddleware(exceptionHandler())
        .addMiddleware(logRequests())
        .addMiddleware(appRouter.appMiddleware)
        .addHandler(appRouter.appRouter.handler);

    printRoutes(appRouter.appRouter);

    try {
        HttpServer server;
        int port = Config.get('server/port');
        String scheme = 'http',
               host = Config.get('server/host'),
               certificate = Config.get('server/ssl_certificate'),
               key = Config.get('server/ssl_key');
        if (certificate != null && key != null) {
            scheme += 's';
            SecurityContext serverContext = new SecurityContext()
                ..useCertificateChain(certificate)
                ..usePrivateKey(key);
            server = await HttpServer.bindSecure(host, port, serverContext);
        }
        else {
            server = await HttpServer.bind(host, port);
        }
        serveRequests(server, handler);
        print('Serving at ${scheme}://${server.address.host}:${server.port}');
    } catch (error, stackTrace) {
        print(error);
        print(stackTrace);
    }
}
