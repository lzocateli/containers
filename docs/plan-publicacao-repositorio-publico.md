# Plano de publicacao segura e governanca GitHub

## Objetivo
Preparar o repositorio para visibilidade publica e incluir automacao via gh para protecao da main, aprovacao de PR por owner e controle de disparo de Actions.

## Steps
1. Fase 1 - Seguranca pre-publicacao (bloqueador)
1.1. Sanitizar segredos e credenciais versionadas em arquivos criticos.
1.2. Rotacionar imediatamente qualquer token/senha ja exposto no historico.
1.3. Validar nova varredura de segredos para garantir ausencia de material sensivel.

2. Fase 2 - Community Health para repositorio publico
2.1. Confirmar baseline ja existente (README, LICENSE, CODEOWNERS).
2.2. Adicionar documentacao de seguranca, contribuicao e conduta para governanca publica.

3. Fase 3 - Script gh reutilizavel de governanca
3.1. Criar script PowerShell de automacao em tools/scripts (reutilizavel para multiplos repositorios) com parametros de owner/repo/branch/actor autorizado.
3.2. No script, aplicar ruleset/branch protection para branch alvo com: bloqueio de merge sem PR, review obrigatorio, CODEOWNERS obrigatorio e bypass administrativo desabilitado. (depende de 2.1)
3.3. No script, validar pre-requisitos (gh autenticado, permissoes de administracao no repositorio, existencia do branch alvo e existencia de CODEOWNERS).
3.4. No script, incluir modo dry-run e saida de auditoria (ID da regra criada/atualizada e resumo das politicas aplicadas).

4. Fase 4 - Restricao de Actions para unico usuario
4.1. Implementar protecao de execucao no workflow por fail-fast com validacao de actor autorizado. (paralelo com 3.4)
4.2. Configurar/automatizar Environment protegido com reviewer obrigatorio no usuario autorizado para jobs sensiveis (ex.: publish). (depende de 4.1)
4.3. Documentar limitacao do GitHub: nao existe bloqueio nativo per-user para botao Run workflow; a estrategia e gate em workflow + environment.

5. Fase 5 - Validacao final de prontidao publica
5.1. Testar PR simulado para main sem aprovacao do owner (deve bloquear).
5.2. Testar PR com aprovacao do owner (deve permitir conforme checks).
5.3. Testar workflow_dispatch com usuario nao autorizado (deve falhar no gate).
5.4. Testar workflow_dispatch com usuario autorizado e aprovacao de environment (deve prosseguir).

## Relevant files
- dns/docker-dot-compose.yml - remover token inline e migrar para variavel/secret.
- certbot/.secrets/cloudflare.ini - remover do versionamento e manter apenas exemplo seguro.
- dns/pihole/docker-compose.yml - trocar senha default por placeholder seguro.
- dns/unbound/docker-compose.yaml - trocar senha default por placeholder seguro.
- .github/CODEOWNERS - garantir cobertura adequada para exigencia de CODEOWNERS.
- .github/workflows/publish-image.yml - incluir gate de actor e environment protegido.
- .github/workflows/validate-images.yml - incluir gate de actor para disparo manual.
- .github/AUTOMATION.md - atualizar instrucoes para setup automatizado via script.
- README.md - refletir governanca minima para repositorio publico.

## Verification
1. Validar sintaxe e ajuda do script: Get-Help completo e caminho --help com saida 0.
2. Executar dry-run do script para dois repositorios de teste e validar idempotencia da configuracao.
3. Consultar regras aplicadas por gh api/rulesets e confirmar parametros de protecao esperados.
4. Executar testes manuais de PR approval e workflow_dispatch com usuario autorizado e nao autorizado.
5. Reexecutar varredura de segredos no workspace e registrar evidencia final.

## Decisions
- Escopo do script: reutilizavel para multiplos repositorios.
- Aprovacao em PR para main: enforced por CODEOWNERS + ruleset sem bypass administrativo.
- Controle de Actions: abordagem combinada (fail-fast por actor + environment protegido com reviewer obrigatorio).
- Limitacao aceita: GitHub nao oferece bloqueio nativo per-user do botao de disparo; bloqueio ocorre na execucao.

## Further considerations
1. Definir se o script deve atualizar regra existente ou sempre recriar (recomendado: update idempotente).
2. Definir lista de workflows sensiveis que exigirao environment (minimo recomendado: publish-image).
