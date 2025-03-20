from croniter import croniter
from datetime import datetime

import subprocess

def get_cron_expressions():
    try:
        # Executa o comando `crontab -l` para listar as entradas no crontab
        output = subprocess.check_output(['crontab', '-l'], text=True)
        
        # Processa as linhas do crontab, ignorando comentarios e linhas vazias
        cron_expressions = [
            line.strip() for line in output.splitlines()
            if line.strip() and not line.strip().startswith('#')
        ]
        
        return cron_expressions
    except subprocess.CalledProcessError:
        print("Nenhum crontab foi configurado para este usuario.")
        return []

cron_expressions = get_cron_expressions()

for expression in cron_expressions:
    print(f"Expressao CRON encontrada: {expression}")

    base_time = datetime.now()

    iter = croniter(expression, base_time)
    next_run = iter.get_next(datetime)

    print("Proxima execucao:", next_run)
