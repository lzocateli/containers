#!/usr/bin/env bash
###############################################################################
# docker-entrypoint.sh
#
# Descrição:
#   Script principal de entrada (ENTRYPOINT) do container Oracle XE.
#   Responsável por iniciar o Oracle Database XE e invocar o script
#   docker-entrypoint-initdb.sh em background para criação de tablespace,
#   usuário e execução de scripts customizados.
#
# Dependências:
#   - Oracle XE 21c (imagem base: gvenzl/oracle-xe:21-slim)
#   - docker-entrypoint-initdb.sh (copiado para /usr/local/bin/)
#
# Variáveis de Ambiente:
#   ORACLE_PASSWORD       - Senha do superusuário SYS/SYSTEM (obrigatório)
#   ORACLE_DATABASE       - Nome do PDB (pluggable database) a utilizar
#                           (padrão: XEPDB1, já criado pela imagem base)
#   ORACLE_TABLESPACE     - Nome do tablespace a ser criado (opcional)
#   ORACLE_USER           - Nome do usuário/schema da aplicação (opcional)
#   ORACLE_USER_PASSWORD  - Senha do usuário da aplicação (opcional)
#
# Uso:
#   Este script é executado automaticamente como ENTRYPOINT do container.
#   Não deve ser invocado manualmente. Configure as variáveis de ambiente
#   no docker-compose.yml ou no 'docker run -e'.
#
#   Exemplo:
#     docker run -e ORACLE_PASSWORD=MinhaSenh@123 lzocateli/oracle:21-slim
#
###############################################################################
set -e

echo "$0: Starting Oracle Database XE"

# Invoke initdb script in background, then start Oracle via the base image entrypoint
docker-entrypoint-initdb.sh &

# Delegate to the original gvenzl/oracle-xe entrypoint
exec /container-entrypoint.sh
