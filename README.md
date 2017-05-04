# Document Store

A service for serving and storing documents from the Google Cloud.

## Installation + Configuration

Copy `config.yaml.sample` as `config.yaml` and edit accordingly, and run `pub get`.

## Server

Run `dart bin/server.dart` or to run in the background, `nohup dart bin/server.dart >> /var/log/dart.log 2>&1`

Since documents are frequently accessed repeatedly, a local, cached version is stored. The cache can be cleared with a simple cron: `bin/cli.dart document purge_cache`

Provide a Basic Auth header when connecting to the API.

### Fetch a document

#### Request
```
GET http://localhost:8080/{document-ID} HTTP/1.1
Authorization: Basic [AUTH_TOKEN]
```

#### Response
`{Binary data representing document}`

### Delete a document

#### Request
```
DELETE http://localhost:8080/{document-ID} HTTP/1.1
Authorization: Basic [AUTH_TOKEN]
```

#### Response
`Document deleted.`

### Create a document

#### Request
```
POST http://localhost:8080/ HTTP/1.1
Content-Type: image/jpeg
Content-Length: [NUMBER_OF_BYTES_IN_FILE]
Authorization: Basic [AUTH_TOKEN]

[JPEG_DATA]
```

Optionally pass `directory` as a query parameter to specify a folder in the storage bucket.

#### Response
```$json
{
    "id":"58ebcc02bd51c69a23514e49",
    "content_type":"text/plain",
    "encryption_key":"abc123"
}
```

## CLI

Usage: `dart bin/cli.dart <command> <subcommand> [arguments]`

Available commands:
* `document`   - Manage Document records.
* `help`       - Display help information for ds-cli.
* `user`       - Modify User records.

### Managing Documents

Available subcommands:
* `delete`      - Delete a Document.
* `info`        - View Document details.
* `purge_cache` - Purge the local file cache.

#### Delete

Usage: `ds-cli document delete [arguments]`

```
-i, --id          ID of Document to edit.
```

#### Info

Usage: `ds-cli document info [arguments]`

```
-i, --id          ID of Document to query.
```

#### Cache Purge

Usage: `ds-cli document purge_cache`

### Managing Users

Available subcommands:
* `delete`     - Delete a User.
* `edit `      - Edit User details.
* `info `      - View User details.
* `register`   - Register a new User

#### Delete

Usage: `ds-cli user delete [arguments]`

```
-i, --id          ID of User to edit.
-u, --username    Username to delete.
```

#### Edit

Usage: `ds-cli user edit [arguments]`

```
-i, --id              ID of User to edit.
-u, --username        Username of User to edit.
-n, --new_username    New username for User.
-e, --enable          Enable the User.
-d, --disable         Disable the User.  
```

#### Info

Usage: `ds-cli user info [arguments]`

```
-i, --id          ID of User to edit.
-u, --username    Username to delete.
```

#### Register

Usage: `ds-cli user register [arguments]`

```
-u, --username    Username for the new User.
-p, --password    Password for the new User.
```

## Running tests

`pub run test test`