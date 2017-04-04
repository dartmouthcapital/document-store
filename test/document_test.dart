import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';
import '../lib/document.dart';
import '../lib/db/resource.dart';
import '../lib/store/resource.dart';
import 'helper.dart';

main() async {
    await initTestConfig();

    test('Constructors, getters and setters.', () {
        var doc = new Document('abcdef');
        expect(doc.id, equals('abcdef'));
        doc.id = 'fedcba';
        expect(doc.id, equals('fedcba'));

        Map json = {
            'id': 'abcdef',
            'content_type': 'text/plain'
        };
        doc = new Document.fromJson(json);
        expect(doc.toMap(), equals(json));
        expect(doc.toJson(), equals(JSON.encode(json)));
        expect(doc.name, equals('abcdef.txt'));

        expect(doc.resource() is DbResource, isTrue);
        expect(doc.store() is StoreResource, isTrue);

        doc.contentType = 'bogus';
        try {
            doc.name;
            fail('Exception not thrown');
        } catch (e) {
            expect(e, new isInstanceOf<Exception>());
        }
    });

    test('Save, load and delete cycle.', () async {
        // save
        var doc = new Document()
            ..content = [1]
            ..contentType = 'text/plain';
        var saveResult = await doc.save();
        expect(saveResult, isTrue);
        var newId = doc.id;

        // load
        doc = new Document(newId);
        var loadResult = await doc.load();
        expect(loadResult, isTrue);
        expect(doc.contentType, equals('text/plain'));

        // delete
        var deleteResult = await doc.delete();
        expect(deleteResult, isTrue);
    });

    test('Loading non-existing documents.', () async {
        var doc = new Document('abcdef');
        var result = await doc.load();
        expect(result, isFalse);
    });

    test('Saving non-existing documents and updates.', () async {
        var doc = new Document('abcdef')
            ..content = [1]
            ..contentType = 'text/plain';
        await doc.save();
        var result = await doc.load();
        expect(result, isFalse);

        doc = new Document()
            ..content = [1]
            ..contentType = 'text/plain';
        await doc.save();
        doc.contentType = 'application/json';
        await doc.save();
        doc = new Document(doc.id);
        await doc.load();
        expect(doc.contentType, equals('application/json'));

        doc = new Document();
        expect(doc.save(), throwsA(equals('Document content has not been set.')));
    });

    test('Deleting non-existing documents and invalid deletes.', () async {
        var doc = new Document('abcdef');
        var result = await doc.delete();
        expect(result, isFalse);

        doc = new Document();
        expect(doc.delete(), throwsA(equals('Cannot delete file without an ID.')));
    });

    test('Images are correctly resized.', () async {
        //Config.set('storage/resize_max_width', 500);

        // small image, don't resize
        var imageData = new File('test/documents/test_x300.jpg').readAsBytesSync();
        Document doc = new Document()
            ..content = imageData
            ..contentType = 'image/jpeg';

        await doc.save();
        Image image = decodeImage(doc.content);
        expect(image, isNotNull);
        expect(image.width, equals(300));

        // large image, resize
        imageData = new File('test/documents/test_x768.jpg').readAsBytesSync();
        doc = new Document()
            ..content = imageData
            ..contentType = 'image/jpeg';

        await doc.save();
        image = decodeImage(doc.content);
        expect(image, isNotNull);
        expect(image.width, equals(500));
    });
}