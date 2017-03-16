import 'package:dart_config/default_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_exception_handler/shelf_exception_handler.dart';
import 'package:shelf_rest/shelf_rest.dart';

import '../lib/config.dart';
import '../lib/router.dart' as app;

main(List<String> args) async {
    Map configMap = await loadConfig();
    new Config(configMap);  // initialize the config

    Handler handler = const Pipeline()
        .addMiddleware(exceptionHandler())
        .addMiddleware(logRequests())
        .addMiddleware(app.appMw)
        .addHandler(app.appRouter.handler);

    printRoutes(app.appRouter);

    io.serve(handler, 'localhost', 8080).then((server) {
        print('Serving at http://${server.address.host}:${server.port}');
    }).catchError((error) => print(error));
}
