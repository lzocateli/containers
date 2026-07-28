---
description: "Use ao criar ou alterar .gitignore e .dockerignore de imagens. Impede vazamento de secrets, dados persistentes, backups e arquivos desnecessários no Git ou contexto Docker."
applyTo: ["**/.gitignore", "**/.dockerignore"]
---

# Ignore files de imagens

- Toda pasta de imagem deve possuir seu próprio `.gitignore` e `.dockerignore`.
- Comece pelos modelos em `.github/templates/ignore/` e adicione padrões específicos da tecnologia.
- O `.gitignore` deve bloquear `.env`, secrets, credenciais, chaves privadas, dados persistentes, backups, logs, caches e artefatos gerados.
- O `.dockerignore` deve bloquear tudo que não participa do build, incluindo `.git`, `.github`, `.env`, secrets, credenciais, persistência, backups, logs, documentação operacional e arquivos de editor.
- Não use uma regra de negação `!` que reintroduza secrets ou dados no Git ou no contexto Docker.
- Não ignore arquivos necessários para reproduzir o build, como manifests e lockfiles.
- Não ignore `.env.example` no Git quando ele documentar apenas nomes e valores seguros; mantenha qualquer `.env` fora do contexto Docker.
- Revise caminhos gerados pelo runtime após um smoke test e adicione-os ao `.gitignore` antes de encerrar a tarefa.
- Verifique arquivos já rastreados: adicionar um padrão não remove conteúdo previamente commitado.

Validações mínimas:

```bash
git check-ignore -v PASTA/.env
docker buildx build --check --file PASTA/Dockerfile PASTA
```
