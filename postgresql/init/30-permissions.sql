\getenv runtime_user POSTGRES_RUNTIME_USER
\getenv application_schema POSTGRES_APP_SCHEMA

\if :{?runtime_user}
SELECT format(
    'GRANT USAGE, CREATE ON SCHEMA %I TO %I',
    :'application_schema',
    :'runtime_user'
)\gexec

SELECT format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO %I',
    :'runtime_user',
    :'application_schema',
    :'runtime_user'
)\gexec

SELECT format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO %I',
    :'runtime_user',
    :'application_schema',
    :'runtime_user'
)\gexec
\else
\echo 'POSTGRES_RUNTIME_USER não configurado; permissões de runtime não serão aplicadas.'
\endif