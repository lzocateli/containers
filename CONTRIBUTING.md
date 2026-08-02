# Guia de Contribuição

## Pré-requisitos
- Docker / BuildKit
- PowerShell 7+
- `uv` para ferramentas Python em `tools/`
- `gh` CLI autenticado para automações GitHub

## Fluxo de contribuição
1. Abra uma branch curta e descritiva.
2. Faça mudanças pequenas, focadas e sem alterar imagens não relacionadas.
3. Garanta que cada pasta de imagem mantenha `Dockerfile`, `README.md`, `.gitignore` e `.dockerignore`.
4. Atualize `tools/container-images.json` quando criar ou publicar nova imagem.
5. Execute validações locais antes do PR.

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
- Pull requests são aceitos somente de colaboradores do repositório.
- Usuários externos devem abrir uma Issue para sugerir mudanças, relatar problemas ou propor novas imagens.
- Descreva objetivo, risco e impacto de contrato da imagem.
- Informe evidências de validação (build, scan, smoke test).
- Não inclua segredos, dumps, backups nem dados sensíveis.

## Padrão de commit
Use Conventional Commits.
Exemplos:
- `feat(<imagem>): adicionar suporte a arm64`
- `fix(workflows): bloquear workflow_dispatch por ator`
- `docs: atualizar política de segurança`

## Segurança e disclosure
Leia `SECURITY.md` para reporte responsável de vulnerabilidades.
