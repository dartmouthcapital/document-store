import 'package:test/test.dart';
import '../lib/store/resource.dart';
import '../lib/store/gcloud.dart';
import '../lib/store/local.dart';
import '../lib/store/test.dart';
import 'helper.dart';

main() async {
    await initTestConfig();

    test('Storage factory', () {
        expect(storageFactory() is GCloudStore, isTrue);
        expect(storageFactory('gcloud') is GCloudStore, isTrue);
        expect(storageFactory('test') is TestGCloudStore, isTrue);
        expect(storageFactory('local') is LocalStore, isTrue);
    });
}