import 'package:test/test.dart';
import '../lib/store/gcloud.dart';
import 'helper.dart';

main() async {
    await initTestConfig();

    test('Encryption key generation', () {
        var keyGen = new EncryptionKey();
        expect(keyGen.key.length, equals(44));  // generates new key
        expect(keyGen.keyHash.length, equals(44));

        String checkKey = '0PkKJMC0TR6Erq1KE19NLLeNhtwMyaw3vox1eIXmyUs=',
               checkKeyHash = 'MiFfaI8Sb7pSswutgd7d3erI/ZyGFrWRj9ZCWKw7Uyk=';
        Map checkMap = {'key': checkKey};

        keyGen.fromMap(checkMap);
        expect(keyGen.toMap(), equals(checkMap));
        expect(keyGen.key, equals(checkKey));
        expect(keyGen.keyHash, equals(checkKeyHash));

        keyGen = new EncryptionKey(checkKey);
        expect(keyGen.key, equals(checkKey));
        expect(keyGen.toString(), equals(checkKey));
        expect(keyGen.keyHash, equals(checkKeyHash));
    });
}