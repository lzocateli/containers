\getenv application_schema POSTGRES_APP_SCHEMA

\if :{?application_schema}
SELECT format('CREATE SCHEMA IF NOT EXISTS %I', :'application_schema')\gexec
\else
\echo 'POSTGRES_APP_SCHEMA não configurado; nenhum schema de aplicação será criado.'
\endif