import 'dart:async';
import 'dart:io' show exit;
import 'config.dart';
import 'store/resource.dart';

/// Bootstrap the app
Future bootstrap() async {
    try {
        await Config.ready();
        await new StoreResource().ready();
    } catch (error) {
        print('App initilization failed (${error.toString()})');
        exit(255);
    }
}
