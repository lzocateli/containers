#!/usr/bin/env bash
###############################################################################
# docker-entrypoint.sh
#
# Descrição:
#   Script principal de entrada (ENTRYPOINT) do container SQL Server.
#   Responsável por iniciar o processo do SQL Server (sqlservr) e invocar
#   o script docker-entrypoint-initdb.sh em background para criação de
#   database, usuário e execução de scripts customizados.
#
# Dependências:
#   - SQL Server 2022 (imagem base: mcr.microsoft.com/mssql/server:2022-latest)
#   - docker-entrypoint-initdb.sh (copiado para /usr/local/bin/)
#
# Variáveis de Ambiente:
#   ACCEPT_EULA          - Aceite do EULA da Microsoft (obrigatório: Y)
#   SA_PASSWORD           - Senha do superusuário SA (obrigatório)
#   MSSQL_DATABASE        - Nome do database a ser criado (opcional)
#   MSSQL_DATABASE_COLLATE - Collation do database
#                           (padrão: SQL_Latin1_General_CP1_CI_AI)
#   MSSQL_USER            - Nome do usuário da aplicação (opcional)
#   MSSQL_PASSWORD        - Senha do usuário da aplicação (opcional)
#
# Uso:
#   Este script é executado automaticamente como ENTRYPOINT do container.
#   Não deve ser invocado manualmente. Configure as variáveis de ambiente
#   no docker-compose.yml ou no 'docker run -e'.
#
#   Exemplo:
#     docker run -e ACCEPT_EULA=Y -e SA_PASSWORD=MinhaSenh@123 \
#       lzocateli/mssql-server:2022
#
###############################################################################
echo "$0: Starting SQL Server"
docker-entrypoint-initdb.sh & /opt/mssql/bin/sqlservr
