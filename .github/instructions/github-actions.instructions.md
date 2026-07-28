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
- Fixe actions por versão principal aprovada; em ambientes de alta garantia, fixe pelo SHA do commit.
- Use Buildx, cache GHA, SBOM e proveniência no build de release.
- Execute validação antes do login e do push.
- Não publique `latest` implicitamente. Uma tag móvel exige decisão explícita e uma tag imutável correspondente.
- Use `concurrency` para impedir duas publicações da mesma imagem e tag.
- Sincronize o Docker Hub somente após push bem-sucedido e a partir do `README.md` validado.
- Não imprima tokens, JWTs, conteúdo de secrets ou headers de autorização.
