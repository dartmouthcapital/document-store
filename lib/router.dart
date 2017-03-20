import 'dart:async';
import 'dart:convert';
//import 'dart:io';
import 'package:http_exception/http_exception.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_route/shelf_route.dart';
import 'document.dart';

Router appRouter = router()
    ..get('/{id}', (Request request) {
        String id = getPathParameter(request, 'id');
        Document doc = new Document(id);
        return doc.load().then((result) => result ?
            new Response.ok(doc.toJson()) : throw new NotFoundException());
    })
    ..post('/', (Request request) {
//        var bin = new BytesBuilder();
//        request.read()
//            .listen((bytes) => bin.add(bytes), onDone: () {
//                File file = new File('/Users/todd/Desktop/test.jpg');
//                file.writeAsBytesSync(bin.toBytes());
//            });
        //bin.add(await request.read());
        var //body = await request.,
            contentType = request.mimeType;

        Document doc = new Document()
            ..contentType = contentType
            ;//..content = body;
        return doc.save().then((result) => result ?
            new Response.ok(doc.toJson()) : throw new HttpException());
    })
    ..delete('/{id}', (Request request) {
        String id = getPathParameter(request, 'id');
        Document doc = new Document(id);
        return doc.delete().then((result) => result ?
            new Response.ok(JSON.encode('Document deleted.')) : throw new NotFoundException());
    });

Middleware appMw = createMiddleware(
    requestHandler: reqHandler,
    responseHandler: respHandler
);

Response reqHandler(Request request) {
    if (request.method == 'OPTIONS') {
        return new Response.ok(null, headers: CORSHeader);
    }
    List allowed = ['GET', 'POST', 'DELETE'];
    if (!allowed.contains(request.method)) {
        throw new MethodNotAllowed();
    }
    return null;
}

Response respHandler(Response response) {
    return response.change(headers: CORSHeader);
}

Map CORSHeader = {
    'content-type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Origin, X-Requested-With, Content-Type, Accept',
    'Access-Control-Allow-Methods': 'POST, GET, DELETE, OPTIONS'
};
