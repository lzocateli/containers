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
| `workflows/publish-image.yml` | Build multi-plataforma, push e sincronização do Docker Hub. |

## Configuração inicial no GitHub

1. Publique este repositório no GitHub como `lzocateli/containers`.
2. Abra **Settings > Secrets and variables > Actions**.
3. Crie o secret `DOCKERHUB_USERNAME` com o usuário `lzocateli`.
4. Crie o secret `DOCKERHUB_TOKEN` com um Access Token do Docker Hub que tenha permissão de escrita.
5. Em **Settings > Actions > General**, mantenha a permissão padrão do workflow como somente leitura.

## Publicar uma imagem

1. Garanta que a pasta contenha `Dockerfile`, `README.md`, `.gitignore` e `.dockerignore` completos.
2. Abra **Actions > Publicar imagem de container > Run workflow**.
3. Informe a pasta relativa, o nome da imagem sem `lzocateli/`, a tag imutável, o Dockerfile e as plataformas.
4. Mantenha a atualização do README habilitada para publicar a descrição completa no Docker Hub.
5. Após o workflow, confirme o digest e faça um pull da referência remota.

O workflow aceita `linux/amd64`, `linux/arm64` e `linux/arm/v7`, não publica `latest` automaticamente e limita a descrição do Docker Hub a 25.000 bytes. Tags móveis devem ser adicionadas apenas após definição explícita da política no README da imagem.

## Criar documentação de imagem

Copie conceitualmente a estrutura de `templates/container-README.template.md`, substitua todos os placeholders e remova apenas seções comprovadamente não aplicáveis. Todos os READMEs novos devem usar o nome exato `README.md` e conter badges `img.shields.io/badge`.

## Proteger repositório e contexto de build

Toda pasta de imagem deve possuir `.gitignore` e `.dockerignore`, derivados de `templates/ignore/`. O `.gitignore` impede que dados locais, secrets e artefatos sejam versionados; o `.dockerignore` reduz o contexto e impede que esses arquivos sejam enviados ao daemon ou persistidos acidentalmente em camadas.

Os templates são uma base mínima. Adicione padrões específicos da tecnologia sem remover as proteções de `.env`, secrets, credenciais, dados persistentes, backups e metadados Git. Use arquivos de exemplo sem segredo, como `.env.example`, somente no Git; eles não precisam fazer parte do contexto Docker salvo requisito explícito do build.

## Custos e limites

O workflow usa runners padrão do GitHub Actions e Docker Hub. Repositórios públicos normalmente têm execução gratuita nos runners padrão; repositórios privados seguem a franquia do plano GitHub. Armazenamento, retenção, rate limits e políticas do Docker Hub dependem do plano da conta. Consulte os preços atuais antes de ampliar plataformas ou frequência de builds.