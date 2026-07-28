---
name: Criar imagem de container
description: "Cria uma nova imagem padronizada com Dockerfile otimizado, README completo e validação local."
argument-hint: "Informe pasta, finalidade, imagem base, versão, plataformas e contrato de runtime"
agent: agent
---

Crie uma nova imagem no projeto `containers` seguindo a skill `container-image-maintenance`.

Antes de editar, confirme pasta, finalidade, imagem base e versão, plataformas, usuário, portas, volumes, variáveis, health check e tag pretendida. Crie o menor conjunto de arquivos necessário, use multi-stage build quando aplicável, derive `README.md` de `.github/templates/container-README.template.md` e crie obrigatoriamente `.gitignore` e `.dockerignore` a partir de `.github/templates/ignore/`.

Valide o Dockerfile, execute build e smoke test locais. Não faça push sem autorização explícita.
