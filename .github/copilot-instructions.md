# GitHub Copilot Instructions

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

## Validação mínima

- Valide sintaxe e boas práticas do Dockerfile com BuildKit.
- Confirme que `.gitignore` e `.dockerignore` existem e bloqueiam, no mínimo, `.env`; o `.dockerignore` também deve bloquear `.git`.
- Construa a plataforma de destino sem usar credenciais no contexto.
- Execute um smoke test compatível com a imagem.
- Inspecione labels, usuário, entrypoint, portas e health check.
- Verifique vulnerabilidades, SBOM e proveniência no fluxo de publicação.
- Confirme que `README.md` corresponde à tag e ao contrato efetivamente construídos.

## Publicação

- O workflow oficial é `.github/workflows/publish-image.yml`.
- Ele recebe pasta, nome, tag, Dockerfile e plataformas via `workflow_dispatch`.
- Os secrets obrigatórios são `DOCKERHUB_USERNAME` e `DOCKERHUB_TOKEN`.
- A descrição do Docker Hub é sincronizada a partir do `README.md` da pasta selecionada.
