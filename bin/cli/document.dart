import 'dart:io';
import 'package:args/command_runner.dart';
import '../../lib/document.dart';

/// Top-level document command
class DocumentCommand extends Command {
    final String name = 'document';
    final String description = 'View and delete Document records.';

    DocumentCommand() {
        addSubcommand(new InfoCommand());
        addSubcommand(new DeleteCommand());
    }
}

/// Command to pull JSON document details.
class InfoCommand extends Command {
    final String name = 'info';
    final String description = 'View Document details.';

    InfoCommand() {
        argParser.addOption('id', abbr: 'i', help: 'ID of Document to query.');
    }

    run() async {
        var id = argResults['id'];
        if (id == null) {
            throw new UsageException(
                '"id" must be set.',
                'info -i "123456"'
            );
        }
        Document doc = new Document(id);
        if (await doc.load()) {
            print(doc.toJson().toString());
            exit(0);
        }
        else {
            print('Document "$id" does not exist.');
            exit(1);
        }
    }
}

/// Command to delete a document
class DeleteCommand extends Command {
    final String name = 'delete';
    final String description = 'Delete a Document.';

    DeleteCommand() {
        argParser.addOption('id', abbr: 'i', help: 'ID of Document to delete.');
    }

    run() async {
        var id = argResults['id'];
        if (id == null) {
            throw new UsageException(
                '"id" must be set.',
                'delete -i "123456"'
            );
        }
        Document doc = new Document(id);
        if (await doc.delete()) {
            print('Document "$id" was successfully deleted.');
            exit(0);
        }
        else {
            print('Document "$id" does not exist.');
            exit(1);
        }
    }
}