#!/usr/bin/env dart
import 'package:logging/logging.dart';
import 'package:logging_handlers/server_logging_handlers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_exception_handler/shelf_exception_handler.dart';
import 'package:shelf_route/shelf_route.dart';

import '../lib/config.dart';
import '../lib/router.dart' as app;

main(List<String> args) async {
    await Config.ready();
    var logHandler = new SyncFileLoggingHandler('var/server.log');

    Handler handler = const Pipeline()
        .addMiddleware(exceptionHandler())
        .addMiddleware(logRequests(logger: (String msg, bool isError) {
            LogRecord record = new LogRecord(Level.INFO, msg, 'request', isError);
            logHandler.call(record);
        }))
        .addMiddleware(logRequests())
        .addMiddleware(app.appMiddleware)
        .addHandler(app.appRouter.handler);

    printRoutes(app.appRouter, printer: (printStr) {
        print(printStr);
        LogRecord record = new LogRecord(Level.INFO, printStr, 'server');
        logHandler.call(record);
    });

    assert(Config.get('server/host') is String);
    assert(Config.get('server/port') is int);
    io.serve(handler, Config.get('server/host'), Config.get('server/port'))
        .then((server) {
            String msg = 'Serving at http://${server.address.host}:${server.port}';
            print(msg);
            LogRecord record = new LogRecord(Level.INFO, msg, 'server');
            logHandler.call(record);
        }).catchError((error, stackTrace) {
            print(error);
            LogRecord record = new LogRecord(
                Level.SEVERE,
                error.message,
                'server',
                true,
                stackTrace
            );
            logHandler.call(record);
        });
}
