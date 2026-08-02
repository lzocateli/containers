# Plano de publicacao segura e governanca GitHub

## Status geral: concluido (2026-08-02)
Repositorio `lzocateli/containers` publicado e governanca aplicada via `tools/scripts/setup-github-governance.ps1`.
Validacao manual de PR e workflow_dispatch pendente (Fase 5, requer acao humana).

## Objetivo
Preparar o repositorio para visibilidade publica e incluir automacao via gh para protecao da main, aprovacao de PR por owner e controle de disparo de Actions.

## Steps

### Fase 1 - Seguranca pre-publicacao (bloqueador) [concluida]
- [x] 1.1. Sanitizar segredos e credenciais versionadas em arquivos criticos.
  - dns/docker-dot-compose.yml: token migrado para `${CLOUDFLARED_TUNNEL_TOKEN:?defina CLOUDFLARED_TUNNEL_TOKEN}` (commit 37302c5).
  - dns/pihole/docker-compose.yml e dns/unbound/docker-compose.yaml: senha migrada para `${PIHOLE_WEBPASSWORD:?defina PIHOLE_WEBPASSWORD}` (commit 37302c5).
  - certbot/.secrets/cloudflare.ini: historico verificado via `git log`; unico commit (99f4dcc) contem apenas placeholder `xxxxxxx`. Sem token real exposto.
- [x] 1.2. Rotacionar imediatamente qualquer token/senha ja exposto no historico.
  - Nao necessario: historico nao contem material sensivel real.
- [x] 1.3. Validar nova varredura de segredos para garantir ausencia de material sensivel.
  - Verificacao manual por `git log` e inspecao de conteudo de todos os arquivos criticos.
  - Nota: varredura automatizada com gitleaks/truffleHog nao executada nesta sessao; recomendada antes do proximo release.

### Fase 2 - Community Health para repositorio publico [concluida]
- [x] 2.1. Confirmar baseline ja existente (README, LICENSE, CODEOWNERS).
  - README.md, LICENSE e CODEOWNERS existiam; CODEOWNERS atualizado (commit 0c3b948).
- [x] 2.2. Adicionar documentacao de seguranca, contribuicao e conduta para governanca publica.
  - CODE_OF_CONDUCT.md, CONTRIBUTING.md e SECURITY.md adicionados (commit 0c3b948).

### Fase 3 - Script gh reutilizavel de governanca [concluida]
- [x] 3.1. Criar script PowerShell de automacao em tools/scripts com parametros de owner/repo/branch/actor autorizado.
  - `tools/scripts/setup-github-governance.ps1` adicionado (commit 81a221e, corrigido em 8319fe4).
  - Parametros: `-RepoOwner`, `-RepoName`, `-BranchName`, `-AuthorizedActor`, `-EnvironmentName`, `-RequireLinearHistory`, `-DryRun`.
- [x] 3.2. Aplicar branch protection com: bloqueio de merge sem PR, review obrigatorio, CODEOWNERS obrigatorio e bypass administrativo desabilitado.
  - Aplicado em `lzocateli/containers` main em 2026-08-02.
  - `require_code_owner_reviews: true`, `dismiss_stale_reviews: true`, `required_approving_review_count: 1`, `require_last_push_approval: true`, `enforce_admins: true`, `required_linear_history: true`, `allow_force_pushes: false`, `allow_deletions: false`, `required_conversation_resolution: true`.
  - Restricoes `bypass_pull_request_allowances` e `dismissal_restrictions` nao incluidas: exclusivas de repositorios de organizacao (HTTP 422 em conta pessoal).
- [x] 3.3. Validar pre-requisitos (gh autenticado, permissoes de administracao, existencia do branch alvo e CODEOWNERS).
  - Script valida todos os pre-requisitos antes de aplicar.
- [x] 3.4. Incluir modo dry-run e saida de auditoria.
  - Dry-run validado com saida completa antes da aplicacao real.

### Fase 4 - Restricao de Actions para unico usuario [concluida]
- [x] 4.1. Implementar protecao fail-fast com validacao de actor autorizado nos workflows.
  - `publish-image.yml` e `validate-images.yml` com gate de ator via variavel `AUTHORIZED_WORKFLOW_DISPATCH_ACTOR` (commit 13993ea).
- [x] 4.2. Configurar Environment protegido com reviewer obrigatorio para jobs sensiveis.
  - Environment `container-release` criado com `required_reviewers` e reviewer `lzocateli` (id 16601706).
  - Variavel `AUTHORIZED_WORKFLOW_DISPATCH_ACTOR=lzocateli` criada em Actions variables.
  - `publish-image.yml` job de push usa `environment: container-release`.
- [x] 4.3. Documentar limitacao do GitHub.
  - Documentado em `.github/AUTOMATION.md`: GitHub nao oferece bloqueio nativo per-user do botao `workflow_dispatch`; bloqueio aplicado na execucao (gate de actor + environment).

### Fase 5 - Validacao final de prontidao publica [pendente - requer acao manual]
- [ ] 5.1. Testar PR simulado para main sem aprovacao do owner (deve bloquear).
- [ ] 5.2. Testar PR com aprovacao do owner (deve permitir conforme checks).
- [ ] 5.3. Testar workflow_dispatch com usuario nao autorizado (deve falhar no gate).
- [ ] 5.4. Testar workflow_dispatch com usuario autorizado e aprovacao de environment (deve prosseguir).

## Relevant files
- [x] dns/docker-dot-compose.yml - token migrado para variavel de ambiente obrigatoria.
- [~] certbot/.secrets/cloudflare.ini - historico verificado; contem apenas placeholder. Arquivo ainda versionado como exemplo intencional.
- [x] dns/pihole/docker-compose.yml - senha migrada para variavel de ambiente obrigatoria.
- [x] dns/unbound/docker-compose.yaml - senha migrada para variavel de ambiente obrigatoria.
- [x] .github/CODEOWNERS - cobertura adequada para workflows, ferramentas e Dockerfiles.
- [x] .github/workflows/publish-image.yml - gate de actor e environment container-release adicionados.
- [x] .github/workflows/validate-images.yml - gate de actor para disparo manual adicionado.
- [x] .github/AUTOMATION.md - instrucoes de setup via script e limitacao documentada.
- [x] README.md - atualizado para repositorio publico.
- [x] CODE_OF_CONDUCT.md - adicionado.
- [x] CONTRIBUTING.md - adicionado.
- [x] SECURITY.md - adicionado.
- [x] tools/scripts/setup-github-governance.ps1 - script de governanca criado e aplicado.

## Verification
- [x] 1. Validar sintaxe e ajuda do script: `--help` executado com saida 0.
- [x] 2. Dry-run do script executado com sucesso em lzocateli/containers.
- [x] 3. Regras verificadas por `gh api repos/.../branches/main/protection`:
  - `require_code_owner_reviews: true`, `enforce_admins.enabled: true`, `required_linear_history.enabled: true`, `allow_force_pushes.enabled: false`.
- [ ] 4. Testes manuais de PR approval e workflow_dispatch pendentes (Fase 5).
- [~] 5. Varredura manual de segredos realizada via inspecao de git history. Varredura automatizada recomendada.

## Decisions
- Escopo do script: reutilizavel para multiplos repositorios.
- Aprovacao em PR para main: enforced por CODEOWNERS + branch protection sem bypass administrativo.
- Controle de Actions: abordagem combinada (fail-fast por actor + environment protegido com reviewer obrigatorio).
- Limitacao aceita: GitHub nao oferece bloqueio nativo per-user do botao de disparo; bloqueio ocorre na execucao.
- Restricoes de organizacao: `bypass_pull_request_allowances` e `dismissal_restrictions` omitidos (suportados apenas em repos de organizacao).
- Bootstrap: para o push inicial apos ativacao de branch protection, `enforce_admins` foi temporariamente desabilitado via `gh api --method DELETE .../enforce_admins` e reabilitado logo em seguida via `gh api --method POST`.

## Further considerations
1. [resolvido] Definir se o script deve atualizar regra existente ou sempre recriar: update idempotente implementado (PUT sobreescreve a protecao).
2. [resolvido] Definir lista de workflows sensiveis que exigirao environment: apenas `publish-image.yml` usa `container-release`.
