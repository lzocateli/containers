# GitHub Copilot Instructions

## Ambiente local e aliases containerizados

- O console padrão do workspace no Windows é PowerShell 7 (`pwsh`), nunca Windows PowerShell 5.1 (`powershell.exe`).
- O profile padrão importa `D:\OneDrive - zocateli\ProfileZocateli\profile.shared.ps1`. Não use `-NoProfile` quando a operação depender dos aliases interativos.
- Antes de concluir que uma ferramenta não está instalada ou tentar instalá-la, execute `Get-Command <nome>` no PowerShell 7.
- Os aliases abaixo executam a ferramenta em `lzocateli/devops:ubuntu-22.04` pelo Docker, em vez de chamar um binário local:

| Alias | Ferramenta no container |
| --- | --- |
| `gh` | GitHub CLI |
| `copilot` | GitHub Copilot via `gh copilot` |
| `ghswitch` | troca da conta ativa do GitHub CLI |
| `terraform` | Terraform |
| `jq` | jq |
| `az` | Azure CLI |
| `ng` | Angular CLI |
| `node` | Node.js |
| `npm` | npm |
| `sqlcmd` | sqlcmd |

- Esses aliases são conveniências do terminal interativo. Scripts, tarefas automatizadas e CI não devem depender do profile pessoal; nesses casos, declare explicitamente o executável ou container utilizado.

## Escopo do repositório

- O nome público deste projeto é `containers`.
- Cada diretório de imagem é uma unidade independente de build, documentação e release.
- As imagens publicadas pertencem ao namespace Docker Hub `lzocateli`.
- Preserve compatibilidade das tags publicadas e trate alteração de entrypoint, usuário, porta, volume ou variável como mudança de contrato.

## Forma de trabalho

- Comece pelo diretório dono da imagem e leia seu `Dockerfile`, `README.md`, scripts, arquivos Compose e ignore files.
- Faça mudanças pequenas e não altere imagens não relacionadas.
- Não inclua credenciais, tokens, certificados privados ou conteúdo de `.env` em imagens, logs ou documentação.
- Toda pasta de imagem deve possuir `.gitignore` e `.dockerignore`, criados a partir dos templates em `.github/templates/` e adaptados ao contexto da imagem.
- Nunca remova proteções para `.env`, secrets, credenciais, dados persistentes, backups, caches ou metadados Git sem justificar e validar que o conteúdo não entrará no repositório nem no build context.
- Use o template `.github/templates/container-README.template.md` ao criar ou reestruturar documentação de imagem.
- Use a skill `container-image-maintenance` para criação, alteração, validação ou release de imagens.
- Não publique tags mutáveis como única referência. Toda release deve possuir uma tag imutável e descritiva.
- Não execute push ou deploy sem solicitação explícita e autenticação já configurada.

## Scripts e automação

- Ao criar ou refatorar scripts, siga `.github/instructions/script-authoring.instructions.md` e `.github/SCRIPTING.md`.
- Scripts PowerShell e Bash de automação do repositório pertencem a `tools/scripts/`.
- Ferramentas Python de automação pertencem a `tools/scripts/<nome>/`, são executadas com `uv` e compartilham o único `tools/pyproject.toml` do repositório.
- Scripts que fazem parte do contrato, build ou runtime de uma imagem permanecem na pasta específica dessa imagem.
- Todo script criado ou refatorado deve oferecer `--help` com finalidade, dependências, uso, exemplos e referência para documentação mais ampla quando ela existir.

## Validação mínima

- Registre toda imagem publicável em `tools/container-images.json`; o catálogo deve cobrir exatamente todos os `Dockerfile*` reais.
- Valide sintaxe e boas práticas do Dockerfile com BuildKit.
- Garanta que todo Dockerfile publicável inclua labels OCI `org.opencontainers.image.title`, `org.opencontainers.image.description`, `org.opencontainers.image.source`, `org.opencontainers.image.documentation` e `org.opencontainers.image.url`; inclua `org.opencontainers.image.version` quando a versão estiver disponível no contexto do build.
- Confirme que `.gitignore` e `.dockerignore` existem e bloqueiam, no mínimo, `.env`; o `.dockerignore` também deve bloquear `.git`.
- Construa a plataforma de destino sem usar credenciais no contexto.
- Execute um smoke test compatível com a imagem.
- Inspecione labels, usuário, entrypoint, portas e health check.
- Verifique vulnerabilidades, SBOM e proveniência no fluxo de publicação.
- Bloqueie a publicação quando o Trivy encontrar vulnerabilidade `CRITICAL` com correção disponível; mantenha os demais achados nos artifacts.
- Confirme que `README.md` corresponde à tag e ao contrato efetivamente construídos.

## Publicação

- O workflow oficial é `.github/workflows/publish-image.yml`.
- Ele recebe pasta, nome, tag, Dockerfile e plataformas via `workflow_dispatch`.
- Os inputs devem corresponder exatamente a uma entrada do catálogo e todas as plataformas são escaneadas antes do login e do push.
- Os secrets obrigatórios são `DOCKERHUB_USERNAME` e `DOCKERHUB_TOKEN`.
- A descrição do Docker Hub é sincronizada a partir do `README.md` da pasta selecionada.
