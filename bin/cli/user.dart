import 'dart:io';
import 'package:args/command_runner.dart';
import '../../lib/user.dart';

class UserCommand extends Command {
    final String name = 'user';
    final String description = 'Modify User records.';

    UserCommand() {
        addSubcommand(new RegisterCommand());
    }
}

class RegisterCommand extends Command {
    final String name = 'register';
    final String description = 'Register a new User.';

    RegisterCommand() {
        // [argParser] is automatically created by the parent class.
        argParser
            ..addOption('username', abbr: 'u', help: 'Username for the new User.')
            ..addOption('password', abbr: 'p', help: 'Password for the new User.');
    }

    run() async {
        var username = argResults['username'],
            password = argResults['password'];

        if (username == null || password == null) {
            throw new UsageException(
                'Both "username" and "password" must be set.',
                '-u "newUser" -p "secret"'
            );
        }
        User user = new User();
        if (await user.loadByUsername(username)) {
            throw new Exception('Specified username already exists.');
        }
        await user.register(username, password);
        print('User "$username" successfully created.');
        exit(0);
    }
}