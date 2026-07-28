\getenv runtime_user POSTGRES_RUNTIME_USER
\getenv application_schema POSTGRES_APP_SCHEMA
\getenv database_name POSTGRES_DB

\if :{?runtime_user}
SELECT format(
    'ALTER ROLE %I IN DATABASE %I SET search_path TO %I, public',
    :'runtime_user',
    :'database_name',
    :'application_schema'
)\gexec
\else
\echo 'POSTGRES_RUNTIME_USER não configurado; search_path da aplicação não será definido.'
\endif