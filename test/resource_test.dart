import 'package:test/test.dart';
import '../lib/db/resource.dart';
import 'helper.dart';

main() async {
    await initTestConfig();
    var resource = resourceFactory({'collection': 'test'}),
        id;

    test('Item was inserted.', () async {
        Map newItem = {
            'foo': 'bar',
            'hello': 'world'
        };
        id = await resource.insert(newItem);
        expect(id, isNotEmpty);
    });

    test('Item exists.', () async {
        Map item = await resource.findById(id);
        expect(item.length, greaterThan(0));
        expect(item.containsKey('foo'), isTrue);
        expect(item['foo'], equals('bar'));
    });

    test('Item was updated.', () async {
        Map updatedItem = {
            '_id': id,
            'hola': 'mundo'
        };
        var result = await resource.update(updatedItem);
        expect(result, isTrue);
        Map item = await resource.findById(id);
        expect(item.containsKey('hola'), isTrue);
        expect(item.containsKey('hello'), isFalse);
    });

    test('Item deleted.', () async {
        var result = await resource.deleteById(id);
        expect(result, isTrue);
        var item = await resource.findById(id);
        expect(item.length, equals(0));
    });
}