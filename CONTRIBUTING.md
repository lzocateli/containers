# Guia de Contribuição

## Pré-requisitos

- Docker / BuildKit
- PowerShell 7+
- `uv` para ferramentas Python em `tools/`
- `gh` CLI autenticado para automações GitHub

## Fluxo de contribuição

1. Para mudanças grandes, abra primeiro uma Issue ou Discussion para alinhar a proposta.
2. Faça fork do repositório e abra uma branch curta e descritiva.
3. Faça mudanças pequenas, focadas e sem alterar imagens não relacionadas.
4. Garanta que cada pasta de imagem mantenha `Dockerfile`, `README.md`, `.gitignore` e `.dockerignore`.
5. Atualize `tools/container-images.json` quando criar ou publicar nova imagem.
6. Execute validações locais antes do PR.

## Hook de secrets

O Gitleaks executa exclusivamente em container Docker com a imagem fixa
`lzocateli/gitleaks:8.30.1`; não instale o executável no host. Após clonar,
configure o hook uma vez na raiz:

```powershell
./tools/scripts/install-gitleaks-hook.ps1
```

O comando apenas configura `core.hooksPath=.githooks`. O pre-commit bloqueia
commits quando Docker não está disponível ou quando encontra secrets staged.

## Validações mínimas

- Validar catálogo:

```bash
uv run --project tools python tools/scripts/container-catalog/main.py validate
```

- Scan local de vulnerabilidades:

```powershell
tools/scripts/scan-container-vulnerabilities.ps1 -ContextPath <pasta-da-imagem>
```

- Ajuda do script de governança:

```powershell
tools/scripts/setup-github-governance.ps1 --help
```

## Pull Request

- Pull requests de forks e contribuidores externos são bem-vindos.
- Descreva objetivo, risco e impacto de contrato da imagem.
- Informe evidências de validação (build, scan, smoke test).
- Não inclua segredos, dumps, backups nem dados sensíveis.
- O CI de PR não recebe secrets de publicação; somente o mantenedor pode publicar imagens.
- O merge depende dos checks obrigatórios e da resolução das conversas de revisão.

## Padrão de commit

Use Conventional Commits.

Exemplos:

- `feat(<imagem>): adicionar suporte a arm64`
- `fix(workflows): bloquear workflow_dispatch por ator`
- `docs: atualizar política de segurança`

## Segurança e disclosure

Leia `SECURITY.md` para reporte responsável de vulnerabilidades.
