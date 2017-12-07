import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mime_types/mime_types.dart' as mime;
import '../document.dart';
import '../store/resource.dart';

/// Top-level document command
class DocumentCommand extends Command {
    final String name = 'document';
    final String description = 'Manage Document records.';

    DocumentCommand() {
        addSubcommand(new CreateCommand());
        addSubcommand(new UpdateCommand());
        addSubcommand(new InfoCommand());
        addSubcommand(new DeleteCommand());
        addSubcommand(new PurgeCacheCommand());
    }
}

/// Command to create a document.
class CreateCommand extends Command {
    final String name = 'create';
    final String description = 'Create a Document.';

    CreateCommand() {
        argParser
            ..addOption('file', abbr: 'f', help: 'Path to local file to add to storage.')
            ..addOption('directory', abbr: 'd', help: 'Storage bucket subdirectory.');
    }

    run() async {
        String filePath = argResults['file'],
               directory = argResults['directory'];
        if (filePath == null) {
            throw new UsageException(
                '"file" must be set.',
                'create -f /path/to/file.txt'
            );
        }
        File file = new File(filePath);
        if (!file.existsSync()) {
            throw new Exception('Input file "$filePath" does not exist.');
        }
        Document doc = new Document()
            ..contentType = mime.contentType(file.path)
            ..content = await file.readAsBytes();
        if (directory != null) {
            doc.directory = directory;
        }
        await doc.save();
        print(doc.toJson().toString());
        exit(0);
    }
}

/// Command to update a document.
class UpdateCommand extends Command {
    final String name = 'update';
    final String description = 'Update a Document.';

    UpdateCommand() {
        argParser
            ..addOption('id', abbr: 'i', help: 'ID of Document to replace.')
            ..addOption('file', abbr: 'f', help: 'Path to local file to add to storage.');
    }

    run() async {
        String id = argResults['id'],
               filePath = argResults['file'];
        if (id == null) {
            throw new UsageException(
                '"id" must be set.',
                'update -i "123456" ...'
            );
        }
        if (filePath == null) {
            throw new UsageException(
                '"file" must be set.',
                'update -f /path/to/file.txt ...'
            );
        }
        File file = new File(filePath);
        if (!file.existsSync()) {
            throw new Exception('Input file "$filePath" does not exist.');
        }
        Document doc = new Document(id);
        if (await doc.load()) {
            await doc.deleteFromStore();
            doc..contentType = mime.contentType(file.path)
               ..content = await file.readAsBytes();
            await doc.save();
            print(doc.toJson().toString());
            exit(0);
        }
        else {
            print('Document "$id" does not exist.');
            exit(1);
        }
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
        String id = argResults['id'];
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
        String id = argResults['id'];
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

/// Command to delete a document
class PurgeCacheCommand extends Command {
    final String name = 'purge_cache';
    final String description = 'Purge the Document cache.';

    run() async {
        StoreResource localStore = new StoreResource('local');
        if (await localStore.purge()) {
            print('Local cache was successfully purged.');
            exit(0);
        }
        else {
            print('Could not purge the local cache.');
            exit(1);
        }
    }
}
