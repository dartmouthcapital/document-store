import 'package:test/test.dart';
import '../lib/store/resource.dart';
import '../lib/store/gcloud.dart';
import '../lib/store/local.dart';
import '../lib/store/test.dart';
import 'helper.dart';

main() async {
    await initTestConfig();

    test('Storage factory', () {
        expect(new StoreResource() is GCloudStore, isTrue);
        expect(new StoreResource('gcloud') is GCloudStore, isTrue);
        expect(new StoreResource('test') is TestGCloudStore, isTrue);
        expect(new StoreResource('local') is LocalStore, isTrue);
    });
}