import 'dart:convert';
import 'dart:io';
import 'package:http_exception/http_exception.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_route/shelf_route.dart';
import 'document.dart';

Router appRouter = router()
    ..get('/{id}', (Request request) async {
        String id = getPathParameter(request, 'id');
        Document doc = new Document(id);
        if (await doc.load()) {
            List<int> content = [];
            await for (var bytes in doc.streamContent()) {
                content.addAll(bytes);
            }
            return new Response.ok(content, headers: {'content-type': doc.contentType});
        }
        throw new NotFoundException();
    })
    ..post('/', (Request request) async {
        var bin = new BytesBuilder(),
            contentType = request.mimeType;
        await for (var bytes in request.read()) {
            bin.add(bytes);
        }
        Document doc = new Document()
            ..contentType = contentType
            ..content = bin.toBytes();

        if (await doc.save()) {
            return new Response.ok(doc.toJson(), headers: {'content-type': 'application/json'});
        }
        throw new HttpException();
    })
    ..delete('/{id}', (Request request) async {
        String id = getPathParameter(request, 'id');
        Document doc = new Document(id);
        if (await doc.delete()) {
            return new Response.ok('Document deleted.');
        }
        throw new NotFoundException();
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
    //'content-type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Origin, X-Requested-With, Content-Type, Accept',
    'Access-Control-Allow-Methods': 'POST, GET, DELETE, OPTIONS'
};
