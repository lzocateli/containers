#!/bin/sh

echo "Gerando log em: ${LOG_FILE_NAME}"
/userapps/utils/backup.sh 2>&1 | tee /var/log/${LOG_FILE_NAME}

echo "Iniciado servico de CRON"
crond -f -d 8
python3 /userapps/utils/proxima_execucao.py
