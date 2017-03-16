import 'dart:async';
import 'package:http_exception/http_exception.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_rest/shelf_rest.dart';
import 'document.dart';

Router appRouter = router()
    ..addAll(new DocumentResource(), path: '');

// Document store routes
class DocumentResource {
    @Get('{id}')
    Future<Document> find(String id) async {
        var doc = new Document(id);
        return doc.load().then((result) => result ?
            doc : throw new NotFoundException());
    }

    @Post('')
    Future<Document> create(@RequestBody() Document doc) async {
        return doc.save().then((result) => result ?
            doc : throw new HttpException());
    }

    @Delete('{id}')
    Future<String> delete(String id) async {
        var doc = new Document(id);
        return doc.delete().then((result) => result ?
            'Document deleted.' : throw new NotFoundException());
    }
}

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
