#!/bin/sh

/userapps/utils/backup.sh 2>&1 | tee /var/log/${LOG_FILE_NAME}

echo "Iniciando servico de CRON"
crond -f -d 8
