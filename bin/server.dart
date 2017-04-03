import 'package:dart_config/default_server.dart';
import 'package:logging/logging.dart';
import 'package:logging_handlers/server_logging_handlers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_exception_handler/shelf_exception_handler.dart';
import 'package:shelf_route/shelf_route.dart';

import '../lib/config.dart';
import '../lib/router.dart' as app;

main(List<String> args) async {
    Map configMap = await loadConfig();
    new Config(configMap);  // initialize the config
    var logHandler = new SyncFileLoggingHandler('var/request.log');

    Handler handler = const Pipeline()
        .addMiddleware(exceptionHandler())
        .addMiddleware(logRequests(logger: (String msg, bool isError) {
            LogRecord record = new LogRecord(Level.INFO, msg, 'test', isError);
            logHandler.call(record);
        }))
        .addMiddleware(logRequests())
        .addMiddleware(app.appMiddleware)
        .addHandler(app.appRouter.handler);

    printRoutes(app.appRouter);

    io.serve(handler, 'localhost', 8080).then((server) {
        print('Serving at http://${server.address.host}:${server.port}');
    }).catchError((error) => print(error));
}
