import 'dart:async';
import 'dart:io';
import 'config.dart';
import 'store/resource.dart';

/// Bootstrap the app
Future bootstrap() async {
    File cwd = new File(Platform.script.toFilePath());
    Directory.current = new Directory(cwd.parent.path).parent;
    try {
        await Config.ready();
        await new StoreResource().ready();
    } catch (error) {
        print('App initilization failed (${error.toString()})');
        exit(255);
    }
}
