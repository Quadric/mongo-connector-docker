#!/bin/bash

set -eo pipefail;

# This file will check if the config file exists, by default: /mongo-connector.config.json
# If not, it'll check the MONGO_CONNECTOR_CONFIG env var, if it contains a valid json
#   it'll write it to the config file path

# Config file path (by default /mongo-connector.config.json)
MONGO_CONNECTOR_CONFIG_FILE_PATH=${MONGO_CONNECTOR_CONFIG_FILE_PATH:-/mongo-connector.config.json}
# oplog.timestamp symlink file path (by default /symlink-oplog.timestamp)
MONGO_CONNECTOR_OPLOG_FILE_SYMLINK_PATH=${MONGO_CONNECTOR_OPLOG_FILE_SYMLINK_PATH:-/symlink-oplog.timestamp}

# If config file doesn't exist .. try to create the file from the config env var
if [ ! -f "$MONGO_CONNECTOR_CONFIG_FILE_PATH" ] ; then
  echo "Info: Couldn't find config file: $MONGO_CONNECTOR_CONFIG_FILE_PATH";

  # Configuration to be sent as an environment variable in $MONGO_CONNECTOR_CONFIG

  # If $MONGO_CONNECTOR_CONFIG is missing
  if [ -z "$MONGO_CONNECTOR_CONFIG" ] ; then
    # Exit with an error
    echo "ERROR: Env var MONGO_CONNECTOR_CONFIG is not defined .. existing!";
    exit 1;
  fi

  # Create mongo connector file from the $MONGO_CONNECTOR_CONFIG env var (I replace spaces to \040, and replace them back here!)
  echo "Creating $MONGO_CONNECTOR_CONFIG_FILE_PATH from env var MONGO_CONNECTOR_CONFIG .."
  echo "$MONGO_CONNECTOR_CONFIG" | sed -e 's/\\\\040/ /g' | python3 -m json.tool > "$MONGO_CONNECTOR_CONFIG_FILE_PATH"
fi

# Get the oplog file path from the config after being sure that the file is in place now
MONGO_CONNECTOR_CONFIG_OPLOG_FILE_PATH=${MONGO_CONNECTOR_CONFIG_OPLOG_FILE_PATH:-"$(jq --raw-output .oplogFile "$MONGO_CONNECTOR_CONFIG_FILE_PATH")"}

# Check that the oplog.timestamp file (from config -not the symlink one-) exists
if [ ! -f "$MONGO_CONNECTOR_CONFIG_OPLOG_FILE_PATH" ] ; then
  echo "Oplog file: ($MONGO_CONNECTOR_CONFIG_OPLOG_FILE_PATH) defined in config doesn't exist .. creating an empty one!";
  touch "$MONGO_CONNECTOR_CONFIG_OPLOG_FILE_PATH"
fi

# TODO check that the value of MONGO_CONNECTOR_CONFIG_OPLOG_FILE_PATH, doens't equal MONGO_CONNECTOR_OPLOG_FILE_SYMLINK_PATH so it won't break when we try to create a symlink to it

# If the symlink file exists, then remove it!
if [ -f "$MONGO_CONNECTOR_OPLOG_FILE_SYMLINK_PATH" ] ; then
  echo "Symlink file: $MONGO_CONNECTOR_OPLOG_FILE_SYMLINK_PATH already exists! .. removing it!";
  rm "$MONGO_CONNECTOR_OPLOG_FILE_SYMLINK_PATH";
else
  echo "Symlink file: $MONGO_CONNECTOR_OPLOG_FILE_SYMLINK_PATH doesn't exist!";
fi


# Create a symlink to the target oplog file 
echo "Creating Symlink file: $MONGO_CONNECTOR_OPLOG_FILE_SYMLINK_PATH to Oplog file: $MONGO_CONNECTOR_CONFIG_OPLOG_FILE_PATH";
# Read oplogFile property from config file and create a symlink to /symlink-oplog.timestamp
ln -s "$MONGO_CONNECTOR_CONFIG_OPLOG_FILE_PATH" "$MONGO_CONNECTOR_OPLOG_FILE_SYMLINK_PATH"

echo "Running mongo-connector..";

mongo-connector -c "$MONGO_CONNECTOR_CONFIG_FILE_PATH"