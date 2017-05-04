import 'dart:io';
import 'dart:convert' show UTF8;
import 'package:test/test.dart';
import '../lib/config.dart';
import '../lib/store/local.dart';
import 'helper.dart';

main() async {
    await initTestConfig();
    String ds = Platform.pathSeparator,
           basePath = Config.tempPath + ds + 'test_cache';
    var store = new LocalStore(basePath);
    List<int> bytes = UTF8.encode('test');

    tearDown(() async {
        await store.purge();
    });

    test('Writing to the store', () async {
        var result = await store.write('text_plain.txt', bytes);
        expect(result, isTrue);
        var file = new File(basePath + ds + 'text_plain.txt');
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('test'));
    });

    test('Reading from the store', () async {
        // setup
        var file = new File(basePath + ds + 'text_plain.txt');
        file.writeAsBytesSync(bytes);

        var bin = new BytesBuilder();
        await for (var bytes in store.read('text_plain.txt')) {
            bin.add(bytes);
        }
        expect(bin.toBytes(), equals(bytes));
    });

    test('Deleting from the store', () async {
        // setup
        var file = new File(basePath + ds + 'text_plain.txt');
        file.writeAsBytesSync(bytes);

        expect(await store.delete('text_plain.txt'), isTrue);
        expect(new File(basePath + ds + 'text_plain.txt').existsSync(), isFalse);
        expect(await store.delete('bogus.txt'), isFalse);
    });

    test('File exists in the store', () async {
        // setup
        var file = new File(basePath + ds + 'text_plain.txt');
        file.writeAsBytesSync(bytes);

        expect(await store.exists('text_plain.txt'), isTrue);
        expect(store.existsSync('text_plain.txt'), isTrue);
        expect(await store.exists('bogus.txt'), isFalse);
    });

    test('Purging the store', () async {
        // setup
        new File(basePath + ds + 'test1.txt').writeAsBytesSync(bytes);
        new File(basePath + ds + 'test2.txt').writeAsBytesSync(bytes);

        await store.purge();
        expect(store.existsSync('test1.txt'), isFalse);
        expect(store.existsSync('test2.txt'), isFalse);
    });
}