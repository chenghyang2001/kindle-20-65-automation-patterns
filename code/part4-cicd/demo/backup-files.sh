#!/bin/bash

SRC_DIR=$1
DEST_DIR=$2

DATE=$(date +%Y-%m-%d)
BACKUP_DIR=$DEST_DIR/backup-$DATE

cp -r $SRC_DIR $BACKUP_DIR

FILES=$(find $SRC_DIR -name "*.log" -o -name "*.conf")

COUNT=0
for FILE in $FILES; do
    cp $FILE $BACKUP_DIR/
    COUNT=$((COUNT + 1))
done

echo "已備份 $COUNT 個檔案到 $BACKUP_DIR"
