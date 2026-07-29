---
description: "Use ao criar ou alterar workflows de build, validação, tag, deploy, push ou sincronização de README de imagens."
applyTo: [".github/workflows/**/*.yml", ".github/workflows/**/*.yaml"]
---

# GitHub Actions para imagens

- Fixe runners por versão LTS explícita e estável, como `ubuntu-24.04`; não use aliases `*-latest` nem imagens em preview. Atualize a versão somente após validar os workflows na nova LTS.
- Conceda apenas as permissões necessárias e use `contents: read` por padrão.
- Use secrets `DOCKERHUB_USERNAME` e `DOCKERHUB_TOKEN`; nunca use senha da conta.
- Passe entradas de usuário por `env` antes de usá-las em shell e valide caminhos, nomes e tags.
- Bloqueie caminhos absolutos, `..`, caracteres de shell e Dockerfiles fora do contexto selecionado.
- Fixe todas as actions por SHA completo e registre a versão aprovada em comentário. Atualizações ocorrem por pull request do Dependabot.
- Use Buildx, cache GHA, SBOM e proveniência no build de release.
- Use `tools/container-images.json` como fonte de verdade para contexto, Dockerfile, nome e plataformas; não derive comandos de conteúdo não validado do pull request.
- Em pull requests, construa e escaneie somente imagens alteradas. Não forneça secrets de publicação a jobs de pull request.
- Antes do login e do push, construa cada plataforma e execute Trivy. Vulnerabilidades `CRITICAL` com correção disponível bloqueiam a publicação; demais achados permanecem em artifacts.
- Envie SARIF ao Code Scanning somente quando o evento tiver permissão; em forks, use artifact como fallback.
- Não publique `latest` implicitamente. Uma tag móvel exige decisão explícita e uma tag imutável correspondente.
- Use `concurrency` para impedir duas publicações da mesma imagem e tag.
- Sincronize o Docker Hub somente após push bem-sucedido e a partir do `README.md` validado.
- Confirme por digest que o manifest remoto contém todas as plataformas solicitadas antes de sincronizar o README.
- Não imprima tokens, JWTs, conteúdo de secrets ou headers de autorização.
