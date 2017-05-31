import 'dart:async';
import 'config.dart';
import 'store/resource.dart';

/// Bootstrap the app
Future bootstrap() async {
    await Config.ready();
    await new StoreResource().ready();
}
