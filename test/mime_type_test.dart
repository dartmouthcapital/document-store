import 'package:test/test.dart';
import '../lib/mime_type.dart' as mime;

main() {
    Map checks = {
        'pdf': 'application/pdf',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'gif': 'image/gif',
        'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'txt': 'text/plain'
    };
    test('Valid extension is returned', () {
        checks.forEach((extension, contentType) {
            expect(mime.extension(contentType), equals(extension));
        });
    });

    test('No extension is returned', () {
        expect(mime.extension('Not a content type'), isNull);
    });

    test('Valid content type is returned', () {
        checks['jpg'] = 'image/jpeg';
        checks.forEach((extension, contentType) {
            expect(mime.contentType(extension), equals(contentType));
        });
    });

    test('Valid content type is returned for path', () {
        Map paths = {
            'image.jpg': 'image/jpeg',
            '/path/to/image.png': 'image/png',
            'file.name.pdf': 'application/pdf',
            'doc.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        };
        paths.forEach((file, contentType) {
            expect(mime.contentType(file), equals(contentType));
        });
    });

    test('No content type is returned', () {
        expect(mime.extension('Not an extension'), isNull);
    });
}