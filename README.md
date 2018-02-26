# Mongo Connector 2.5-es_2.4.1

This document describes how to use `mongo-connector:2.5-es_2.4.1` image

## Other dependencies

The requirements are saved in the `requirements.txt` next to the Dockerfile, and the dependencies are static for now
Maybe in the future I'll move these installations to the Dockerfile, and make them configurable through build vars

For now they are:

```bash
mongo-connector==2.5
elasticsearch==2.4.1
elastic2-doc-manager[elastic2]==0.3.0
```

Follow latest releases using `pip/pip3 search <_keyword_>` or through the [pip package index](https://pypi.python.org/pypi/pip)

## Environment variables

| Env | Required | Default | Description |
|-----|----------|---------|-------------|
| MONGO_CONNECTOR_CONFIG_FILE_PATH | Yes | /mongo-connector.config.json | Configuration file path - Update this if you are going to save the file in another layer on top of the image, and the path is different than the default one! |
| MONGO_CONNECTOR_OPLOG_FILE_SYMLINK_PATH | No | /symlink-oplog.timestamp | Symlink file to mongo connector oplog timestamp file (used for health check) - This will be used internally to point to the dynamic oplog file path, and the container will check the symlink for health check (You don't have to change this!) |
| MONGO_REPLICA_SET_NAME | Yes | rs0 | Replica set name, used in the health check command in the container, by grepping it from the oplog file! - change this is the default replica set name is different than yours |
| MONGO_CONNECTOR_CONFIG | No | - | This is the other way of providing configuration to the image, is by sending it to a serialized json string in this var [If your config contains spaces, convert them to \040 in the string, and they'll be converted back to spaces in the startup] |

## Startup step

The run.sh script runs the following logic:

- Check if there is a file in $MONGO_CONNECTOR_CONFIG_FILE_PATH
  - If not Check if the MONGO_CONNECTOR_CONFIG is passed
    - If not exit with an error
    - If yes, then write the value to a the configured file path after converting \040 to spaces
- If the symlink file exists
  - Remove it
- Read the oplog file path from the config file
- Create a symlink to that oplog file path
- Start mongo-connector with the config pointing to the config file

## Configuration

Required fields in the configuration (Either by providing the file or the env var):

```json
{
  "mainAddress": "<_mongo_url_>",
  "oplogFile": "/oplog.timestamp",
  "docManagers": [
    ...
  ]
}
```

Required environment vars to send to the container (I'll assign default values, but that might break your app!)

- MONGO_CONNECTOR_CONFIG_FILE_PATH: If you are going to depend on the file, and you'll create another layer in the image with the file in a path, make sure that you provide the path in this var (if it is not the default value!)
  ```bash
    # This is how I serialize my config using jq & space conversion to \040
    MONGO_CONNECTOR_CONFIG=$(cat "<my_config_file_path>" | jq . -c)
    MONGO_CONNECTOR_CONFIG=${MONGO_CONNECTOR_CONFIG//\ /\\\\040}
    # Then send this var to the container
  ```

- MONGO_REPLICA_SET_NAME: I'll check this replica set name in the oplog.timestamp file (Symlink), if your replica set name is different than the default value, then set it to show the correct health check status

- ** _The image expects the oplogFile field to be set! as it uses it for the health check .. check the next section!_

## Health check

This is done by trying to read the replica set name from the symlink file pointing to the oplog file

It was done this way, as the oplog file path is dynamic, so I wrote the health check command pointing to a static symlink file, and I update the symlink in the startup to point to the oplog file path after I read it from the configuration.

I could just check if it contains any text, but I preferred to be sure, and try to read the replica set name instead!
