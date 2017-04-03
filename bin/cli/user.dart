import 'dart:io';
import 'package:args/command_runner.dart';
import '../../lib/user.dart';

/// Top-level user command
class UserCommand extends Command {
    final String name = 'user';
    final String description = 'Modify User records.';

    UserCommand() {
        addSubcommand(new InfoCommand());
        addSubcommand(new EditCommand());
        addSubcommand(new RegisterCommand());
        addSubcommand(new DeleteCommand());
    }
}

/// Command to pull JSON user details.
class InfoCommand extends Command {
    final String name = 'info';
    final String description = 'View User details.';

    InfoCommand() {
        argParser
            ..addOption('id', abbr: 'i', help: 'ID of User to query.')
            ..addOption('username', abbr: 'u', help: 'Username of User to query.');
    }

    run() async {
        var id = argResults['id'],
            username = argResults['username'];
        if (id == null && username == null) {
            throw new UsageException(
                '"id" or "username" must be set.',
                'info [-i "123456" -u "testUser"]'
            );
        }
        var identifier = id != null ? id : username;
        User user = new User();
        if (await user.load(identifier, id != null ? 'id' : 'username')) {
            print(user.toJson().toString());
            exit(0);
        }
        else {
            print('User "$identifier" does not exist.');
            exit(1);
        }
    }
}

/// Command to edit user details.
class EditCommand extends Command {
    final String name = 'edit';
    final String description = 'Edit User details.';

    EditCommand() {
        argParser
            ..addOption('id', abbr: 'i', help: 'ID of User to edit.')
            ..addOption('username', abbr: 'u', help: 'Username of User to edit.')
            ..addOption('new_username', abbr: 'n', help: 'New username for User.')
            ..addFlag('enable', abbr: 'e', help: 'Enable the User.')
            ..addFlag('disable', abbr: 'd', help: 'Disable the User.');
    }

    run() async {
        var id = argResults['id'],
            username = argResults['username'];
        if (id == null && username == null) {
            throw new UsageException(
                '"id" or "username" must be set.',
                'edit [-i "123456" -u "testUser"]'
            );
        }
        var identifier = id != null ? id : username;
        User user = new User();
        if (await user.load(identifier, id != null ? 'id' : 'username')) {
            var newUsername = argResults['new_username'];
            if (newUsername != null) {
                user.username = newUsername;
            }
            if (argResults['enable']) {
                user.isActive = true;
            }
            else if (argResults['disable']) {
                user.isActive = false;
            }
            await user.save();
            print(user.toJson().toString());
            exit(0);
        }
        else {
            print('User "$identifier" does not exist.');
            exit(1);
        }
    }
}

/// Command to register a new user
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
                'register -u "newUser" -p "secret"'
            );
        }
        User user = new User();
        if (await user.loadByUsername(username)) {
            print('Specified username already exists.');
            exit(2);
        }
        else {
            await user.register(username, password);
            print('User "$username" was successfully created.');
            exit(0);
        }
    }
}

/// Command to delete a user
class DeleteCommand extends Command {
    final String name = 'delete';
    final String description = 'Delete a User.';

    DeleteCommand() {
        argParser.addOption('username', abbr: 'u', help: 'Username to delete.');
    }

    run() async {
        var id = argResults['id'],
            username = argResults['username'];
        if (id == null && username == null) {
            throw new UsageException(
                '"id" or "username" must be set.',
                'info [-i "123456" -u "testUser"]'
            );
        }
        var identifier = id != null ? id : username;
        User user = new User();
        if (await user.delete(identifier, id != null ? 'id' : 'username')) {
            print('User "$username" was successfully deleted.');
            exit(0);
        }
        else {
            print('User "$username" does not exist.');
            exit(1);
        }
    }
}