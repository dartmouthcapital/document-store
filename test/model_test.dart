import 'package:test/test.dart';
import '../lib/db/model.dart';
import 'helper.dart';

main() async {
    await initTestConfig();

    test('Constructors, getters and setters', () {
        var person = new TestPerson('abcdef');
        expect(person.id, equals('abcdef'));

        Map data = {
            'id': 'bogus',
            'name': 'Jane Tester',
            'age': 33
        };
        person.fromMap(data);
        expect(person.id, isNot('bogus'));
        data['id'] = 'abcdef';
        expect(person.toMap(), equals(data));
    });

    test('Save, load and delete cycle', () async {
        // save
        var person = new TestPerson()
            ..name = 'Joe Tester'
            ..age = 44;
        var saveResult = await person.save();
        expect(saveResult, isTrue);
        expect(person.created, isNotNull);
        expect(person.created.day, new DateTime.now().day);
        var newId = person.id;

        // load
        person = new TestPerson(newId);
        var loadResult = await person.load();
        expect(loadResult, isTrue);
        expect(person.name, equals('Joe Tester'));
        expect(person.age, equals(44));

        // update
        person.age = 55;
        await person.save();
        person = new TestPerson(newId);
        await person.load();
        expect(person.age, equals(55));
        expect(person.created, isNotNull);

        // delete
        expect(await person.delete(), isTrue);
        expect(await person.load(), isFalse);
    });
}

class TestPerson extends Model {
    String _id;
    String name;
    int age;

    TestPerson([this._id]);

    /// Prepare the model for saving in the DB.
    Map toMap() {
        Map data = {
            'id': _id,
            'name': name,
            'age': age
        };
        if (created != null) {
            data['created'] = created.toUtc().toIso8601String();
        }
        return data;
    }

    /// Populate the model with data from the DB.
    void fromMap(Map map) {
        if (map.containsKey('name')) {
            name = map['name'];
        }
        if (map.containsKey('age')) {
            age = map['age'];
        }
    }

    String get collection => 'test_person';
    String get id => _id;
    set id (String newId) => _id = newId;
}