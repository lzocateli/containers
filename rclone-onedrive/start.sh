#!/bin/sh

echo "Running backup on start..."
/userapps/utils/backup.sh 2>&1 | tee /var/log/${LOG_FILE_NAME}
echo "Backup on start done"

echo "Starting cron backups"
crond -f -d 8
