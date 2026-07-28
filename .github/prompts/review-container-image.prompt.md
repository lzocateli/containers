---
name: Revisar imagem de container
description: "Revisa uma pasta de imagem quanto a segurança, otimização, compatibilidade, documentação e prontidão de release."
argument-hint: "Informe a pasta da imagem e a tag pretendida"
agent: Container Image Reviewer
---

Revise a pasta informada conforme `.github/instructions/container-build.instructions.md`, `.github/instructions/container-readme.instructions.md` e a skill `container-image-maintenance`.

Priorize bugs, riscos, contratos quebrados, secrets, execução como root, persistência, multi-stage build, tag, plataformas, labels OCI, health check, README e validações ausentes.
