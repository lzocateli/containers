#!/bin/sh

echo "Gerando log em: ${LOG_FILE_NAME}"
##/userapps/utils/backup.sh 2>&1 | tee /var/log/${LOG_FILE_NAME}

echo "Validando cronjobs..."
if crontab -l > /dev/null 2>&1; then
    echo "Arquivo cron válido."
else
    echo "Erro na configuração do cronjobs!" >&2
    exit 1
fi

echo "Executando validação manual do script..."
if sh /userapps/utils/backup.sh; then
    echo "Script backup.sh executado com sucesso."
else
    echo "Erro ao executar backup.sh!" >&2
    exit 1
fi


if [ ! -f /etc/crontabs/root ]; then
    echo "Erro: Arquivo cronjobs não encontrado!" >&2
    exit 1
else
    echo "Iniciando CRON..."
fi

crond -f &

if [ $? -ne 0 ]; then
    echo "Erro ao iniciar o serviço cron!" >&2
    exit 1
fi
echo "Cron inicializado com sucesso."

python3 /userapps/utils/proxima_execucao.py
