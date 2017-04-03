import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:dart_config/default_server.dart';
import '../lib/config.dart';
import 'cli/user.dart';

main(List<String> args) async {
    Map configMap = await loadConfig();
    new Config(configMap);  // initialize the config

    var runner = new CommandRunner('ds-cli', 'Document Store CLI')
        ..addCommand(new UserCommand());

    runner
        .run(args)
        .catchError((error) {
            print(error.message);
            exit(64);
        });
}
