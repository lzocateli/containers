# Automação e GitHub Copilot

Esta pasta centraliza padrões de criação, alteração, documentação, validação e publicação das imagens do projeto `containers`.

## Estrutura

| Caminho | Finalidade |
| --- | --- |
| `copilot-instructions.md` | Regras gerais do repositório. |
| `instructions/` | Regras aplicadas a Dockerfiles, READMEs e workflows. |
| `skills/container-image-maintenance/` | Playbook completo de manutenção e release. |
| `agents/container-image-reviewer.agent.md` | Revisor somente leitura especializado. |
| `prompts/` | Atalhos para criar, revisar e preparar releases. |
| `templates/container-README.template.md` | Estrutura canônica de documentação por imagem. |
| `templates/ignore/` | Modelos obrigatórios de `.gitignore` e `.dockerignore` por imagem. |
| `tools/container-images.json` | Fonte de verdade versionada para contextos, nomes, Dockerfiles, plataformas e nível de validação. |
| `dependabot.yml` | Atualização semanal de Actions e imagens base. |
| `workflows/validate-images.yml` | Checks seletivos de pull request, Trivy e Dependency Review. |
| `workflows/publish-image.yml` | Build multi-plataforma, push e sincronização do Docker Hub. |

A ferramenta `tools/scripts/container-catalog/main.py` valida o catálogo de forma fail-closed e descobre imagens alteradas. Execute-a pelo projeto Python único do repositório:

```bash
uv run --project tools python tools/scripts/container-catalog/main.py --help
```

## Configuração inicial no GitHub

1. Publique este repositório no GitHub como `lzocateli/containers`.
2. Abra **Settings > Secrets and variables > Actions**.
3. Crie o secret `DOCKERHUB_USERNAME` com o usuário `lzocateli`.
4. Crie o secret `DOCKERHUB_TOKEN` com um Access Token do Docker Hub que tenha permissão de escrita.
5. Em **Settings > Actions > General**, mantenha a permissão padrão do workflow como somente leitura.
6. Em **Settings > Code security**, habilite Dependency Graph, Dependabot alerts, Dependabot security updates, Secret Scanning e Push Protection quando disponíveis no plano.
7. Crie um ruleset para `main` exigindo revisão do CODEOWNERS e os checks **Catálogo e descoberta**, **Secrets e configurações**, **Revisar dependências** e **Imagem** quando houver imagem alterada.

O repositório não habilita auto-merge do Dependabot. Toda atualização de base ou Action passa pelos mesmos checks e por revisão humana, especialmente quando altera versão principal ou contrato público.

## Validar pull requests

O workflow `validate-images.yml` usa o diff do pull request e o catálogo para selecionar somente as imagens alteradas. O catálogo é validado contra todos os `Dockerfile*`; caminhos não catalogados, duplicados ou inseguros falham antes do build.

Para cada imagem selecionada, o workflow valida ignores, `README.md` e Dockerfile com BuildKit. Entradas com `validation: build` são construídas na plataforma `scanPlatform` e analisadas pelo Trivy. Entradas `validation: check` executam somente validação estática e devem registrar a justificativa no catálogo.

O gate bloqueia secrets no repositório e vulnerabilidades `CRITICAL` com correção disponível nas imagens construídas. Misconfigurações legadas, vulnerabilidades `HIGH` e críticas sem correção continuam visíveis nos relatórios. Pull requests internos enviam o SARIF das imagens ao Code Scanning; todos os PRs preservam os relatórios do repositório como artifacts.

## Publicar uma imagem

1. Garanta que a pasta contenha `Dockerfile`, `README.md`, `.gitignore` e `.dockerignore` completos.
2. Abra **Actions > Publicar imagem de container > Run workflow**.
3. Informe a pasta relativa, o nome da imagem sem `lzocateli/`, a tag imutável, o Dockerfile e as plataformas.
4. Mantenha a atualização do README habilitada para publicar a descrição completa no Docker Hub.
5. O workflow confere os inputs no catálogo, constrói e escaneia cada plataforma antes de autenticar no Docker Hub.
6. Após os gates, o build multi-plataforma publica SBOM e proveniência, valida o digest e os manifests remotos e só então sincroniza o README.
7. Consulte os artifacts `security-*` para o relatório Trivy e o SBOM CycloneDX de cada plataforma.

O workflow aceita `linux/amd64`, `linux/arm64` e `linux/arm/v7`, rejeita `latest`, `main`, `master`, `edge` e `nightly` e limita a descrição do Docker Hub a 25.000 bytes. Uma futura política de tags móveis exige alteração explícita do catálogo e uma tag imutável correspondente.

## Criar documentação de imagem

Copie conceitualmente a estrutura de `templates/container-README.template.md`, substitua todos os placeholders e remova apenas seções comprovadamente não aplicáveis. Todos os READMEs novos devem usar o nome exato `README.md` e conter badges `img.shields.io/badge`.

## Proteger repositório e contexto de build

Toda pasta de imagem deve possuir `.gitignore` e `.dockerignore`, derivados de `templates/ignore/`. O `.gitignore` impede que dados locais, secrets e artefatos sejam versionados; o `.dockerignore` reduz o contexto e impede que esses arquivos sejam enviados ao daemon ou persistidos acidentalmente em camadas.

Os templates são uma base mínima. Adicione padrões específicos da tecnologia sem remover as proteções de `.env`, secrets, credenciais, dados persistentes, backups e metadados Git. Use arquivos de exemplo sem segredo, como `.env.example`, somente no Git; eles não precisam fazer parte do contexto Docker salvo requisito explícito do build.

## Custos e limites

Os workflows usam runners padrão do GitHub Actions e Docker Hub. Pull requests constroem apenas imagens alteradas, mas releases executam um build de segurança por plataforma antes do build final. Artifacts de PR ficam 30 dias; evidências de release ficam 90 dias. Repositórios públicos normalmente têm execução gratuita nos runners padrão; repositórios privados seguem a franquia do plano GitHub. Armazenamento, retenção, rate limits e políticas do Docker Hub dependem do plano da conta.