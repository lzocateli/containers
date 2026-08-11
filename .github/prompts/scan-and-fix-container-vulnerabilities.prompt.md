---
name: Escanear e corrigir vulnerabilidades de imagem
description: "Executa scan local Trivy e corrige vulnerabilidades de uma imagem antes da publicacao."
argument-hint: "Informe o id da imagem no catalogo e, opcionalmente, a tag alvo"
agent: Container Vulnerability Remediator
---

Execute a skill container-vulnerability-remediation para a imagem informada.

Requisitos:
- Rodar scan local via tools/scripts/scan-container-vulnerabilities-by-id.ps1.
- Usar exclusivamente `containers/artifacts/security-local` para evidencias e `containers/artifacts/security-local/trivy-cache` para cache do Trivy.
- Se a base da imagem tambem for interna e mantida no projeto, escanear e corrigir no ponto mais adequado (base ou filha).
- Corrigir vulnerabilidades CRITICAL corrigiveis no Dockerfile.
- Preservar contrato da imagem e atualizar README quando houver mudanca.
- Reexecutar scan para validar correcao.
- Retornar resumo com achados, correcoes e comandos executados.
