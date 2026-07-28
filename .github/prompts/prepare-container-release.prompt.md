---
name: Preparar release de imagem
description: "Prepara uma imagem existente para build, tag e publicação pelo workflow manual do GitHub Actions."
argument-hint: "Informe pasta, nome da imagem, tag, Dockerfile e plataformas"
agent: agent
---

Prepare a imagem para release conforme a skill `container-image-maintenance`.

Valide Dockerfile, README, `.gitignore` e `.dockerignore`; confirme que `.env`, secrets, persistência, backups e `.git` não vazam para o repositório ou contexto Docker. Execute build e smoke test, confirme a tag imutável, labels OCI, plataformas, SBOM e proveniência esperada. Ao final, informe os valores exatos para os inputs de `.github/workflows/publish-image.yml`.

Não execute push local nem altere secrets.
