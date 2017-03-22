import 'package:test/test.dart';
import '../lib/mime_type.dart' as mime;

main() {
    test('Valid extension is returned', () {
        Map checks = {
            'application/pdf': 'pdf',
            'image/jpeg': 'jpeg',
            'image/png': 'png',
            'image/gif': 'gif',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'docx',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': 'xlsx',
            'text/plain': 'txt'
        };
        for (String contentType in checks.keys) {
            expect(mime.extension(contentType), equals(checks[contentType]));
        }
    });

    test('No extension is returned', () {
        expect(mime.extension('Not a content type'), isNull);
    });
}