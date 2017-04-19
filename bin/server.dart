#!/usr/bin/env dart
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_exception_handler/shelf_exception_handler.dart';
import 'package:shelf_route/shelf_route.dart';

import '../lib/config.dart';
import '../lib/router.dart' as app;

main(List<String> args) async {
    await Config.ready();

    Handler handler = const Pipeline()
        .addMiddleware(exceptionHandler())
        .addMiddleware(logRequests())
        .addMiddleware(app.appMiddleware)
        .addHandler(app.appRouter.handler);

    printRoutes(app.appRouter);

    assert(Config.get('server/host') is String);
    assert(Config.get('server/port') is int);
    io.serve(handler, Config.get('server/host'), Config.get('server/port'))
        .then((server) {
            print('Serving at http://${server.address.host}:${server.port}');
        }).catchError((error, stackTrace) {
            print(error);
            print(stackTrace);
        });
}
