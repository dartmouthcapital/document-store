#!/usr/bin/env dart
import 'dart:io';
import 'package:args/command_runner.dart';
import '../lib/config.dart';
import 'cli/document.dart';
import 'cli/user.dart';

main(List<String> args) async {
    await Config.ready();

    var runner = new CommandRunner('ds-cli', 'Document Store CLI')
        ..addCommand(new DocumentCommand())
        ..addCommand(new UserCommand());

    runner
        .run(args)
        .catchError((error) {
            print(error.message);
            exit(64);
        });
}
