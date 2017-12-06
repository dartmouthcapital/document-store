import 'dart:async';
import 'dart:io';
import 'package:http_exception/http_exception.dart';
import 'package:option/option.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_auth/shelf_auth.dart';
import 'package:shelf_route/shelf_route.dart';
import 'document.dart';
import 'user.dart';

Router appRouter = router()
    ..get('/healthcheck', (Request request) async {
        try {
            User user = new User();
            await user.loadByUsername('test');
            return new Response.ok('Ok');
        } catch (e) {
            return new Response.internalServerError();
        }
    })
    ..get('/{id}', (Request request) async {
        String id = getPathParameter(request, 'id');
        Document doc = new Document(id);
        if (await doc.load()) {
            List<int> content = [];
            await for (var bytes in doc.streamContent()) {
                content.addAll(bytes);
            }
            return new Response.ok(content, headers: {'content-type': doc.contentType});
            // the below doesn't work because the server can't handle errors
            // mid-stream, ex. the doc exists in the DB but not GCloud
            //return new Response.ok(doc.streamContent(), headers: {'content-type': doc.contentType});
        }
        throw new NotFoundException();
    }, middleware: _authMw)
    ..post('/{?directory}', (Request request) async {
        var bin = new BytesBuilder(),
            contentType = request.mimeType,
            directory = getPathParameter(request, 'directory');
        if (contentType == null || contentType.isEmpty) {
            throw new BadRequestException(null, 'Content-type header must be set.');
        }
        await for (var bytes in request.read()) {
            bin.add(bytes);
        }
        Document doc = new Document()
            ..contentType = contentType
            ..directory = directory
            ..content = bin.toBytes();

        if (await doc.save()) {
            return new Response.ok(doc.toJson(), headers: {'content-type': 'application/json'});
        }
        throw new HttpException(); // ignore: conflicting_dart_import
    }, middleware: _authMw)
    ..put('/{id}', (Request request) async {
        String id = getPathParameter(request, 'id');
        Document doc = new Document(id);
        if (await doc.load()) {
            await doc.deleteFromStore();
            var bin = new BytesBuilder(),
                contentType = request.mimeType;
            if (contentType == null || contentType.isEmpty) {
                throw new BadRequestException(null, 'Content-type header must be set.');
            }
            await for (var bytes in request.read()) {
                bin.add(bytes);
            }
            doc..contentType = contentType
               ..content = bin.toBytes();

            if (await doc.save()) {
                return new Response.ok(doc.toJson(), headers: {'content-type': 'application/json'});
            }
            throw new HttpException(); // ignore: conflicting_dart_import
        }
        throw new NotFoundException();
    }, middleware: _authMw)
    ..delete('/{id}', (Request request) async {
        String id = getPathParameter(request, 'id');
        Document doc = new Document(id);
        if (await doc.delete()) {
            return new Response.ok('Document deleted.');
        }
        throw new NotFoundException();
    }, middleware: _authMw)
    ..add('/', ['OPTIONS'], (Request request) {
        return new Response.ok('Ok', headers: CORSHeader);
    });

Middleware _authMw = authenticate(
    [new BasicAuthenticator(_appAuth)],
    allowAnonymousAccess: false,
    allowHttp: true
);

Future<Option<Principal>> _appAuth(String username, String password) async {
    User user = new User();
    if (await user.authenticate(username, password)) {
        return new Some(new Principal(username));
    }
    else {
        return const None();
    }
}

Middleware appMiddleware = createMiddleware(
    requestHandler: _reqHandler,
    responseHandler: _respHandler
);

Response _reqHandler(Request request) {
    List allowed = ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'];
    if (!allowed.contains(request.method)) {
        throw new MethodNotAllowed();
    }
    return null;
}

Response _respHandler(Response response) {
    return response.change(headers: CORSHeader);
}

Map CORSHeader = {
    //'content-type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Origin, X-Requested-With, Content-Type, Accept',
    'Access-Control-Allow-Methods': 'POST, PUT, GET, DELETE, OPTIONS'
};
