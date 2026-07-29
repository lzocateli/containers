---
name: container-image-maintenance
description: "Use para criar, alterar, otimizar, documentar, validar, versionar ou publicar imagens Docker/Podman no projeto containers. Cobre Dockerfile multi-stage, README, build, tag, deploy, push, SBOM, proveniência e Docker Hub."
---

# Container Image Maintenance

## Contexto obrigatório

1. Identifique a pasta da imagem e leia `Dockerfile`, `README.md`, `.gitignore`, `.dockerignore`, Compose e scripts próximos.
2. Consulte as instruções em `.github/instructions/` aplicáveis aos arquivos alterados.
3. Use `.github/templates/container-README.template.md` para documentação nova.
4. Confira ou adicione a entrada correspondente em `tools/container-images.json`.
5. Preserve o namespace `lzocateli` e o nome público do repositório `containers`.

## Criar uma imagem

1. Defina finalidade, consumidor, imagem base, plataformas, usuário, portas e persistência.
2. Confirme licença e manutenção da imagem base e das dependências distribuídas.
3. Crie uma pasta isolada com `Dockerfile`, `README.md`, `.gitignore` e `.dockerignore`; os dois ignore files são obrigatórios.
4. Derive os ignore files de `.github/templates/ignore/` e adapte sem remover a proteção de `.env`, secrets, dados, backups e `.git` no contexto Docker.
5. Use multi-stage build quando ferramentas de compilação não forem necessárias em runtime.
6. Adicione labels OCI e um health check somente quando houver uma prova útil de saúde.
7. Documente tags, configuração, segurança, validação e operação.
8. Registre contexto, Dockerfile, nome, plataformas e nível de validação no catálogo.

## Alterar uma imagem

1. Compare o contrato atual com a mudança pretendida.
2. Trate alterações de base, usuário, entrypoint, porta, volume, variável ou arquivo persistido como risco de compatibilidade.
3. Não sobrescreva tags publicadas quando o conteúdo ou contrato mudar; publique nova tag.
4. Atualize o README no mesmo ciclo.

## Otimizar o Dockerfile

- Separe build e runtime.
- Reduza o contexto com `.dockerignore`.
- Bloqueie arquivos locais e persistentes com `.gitignore` antes de gerar dados ou executar a imagem.
- Preserve cache copiando manifests antes do código.
- Remova caches de pacote na mesma camada da instalação.
- Evite arquivos, ferramentas e privilégios desnecessários na imagem final.
- Use BuildKit para cache e secrets sem persistência em camadas.

## Validar

1. Confirme a existência de `.gitignore` e `.dockerignore` na pasta da imagem.
2. Verifique se `.env`, secrets, dados persistentes e backups não são rastreados pelo Git nem enviados ao contexto Docker; bloqueie `.git` no `.dockerignore`.
3. Execute `docker buildx build --check --file <Dockerfile> <contexto>`.
4. Construa com `--pull` para a plataforma alvo.
5. Execute smoke test e health check.
6. Inspecione `Config.User`, `Entrypoint`, `Cmd`, labels, portas e volumes.
7. Teste persistência e encerramento quando fizerem parte do contrato.
8. Faça scan Trivy e bloqueie vulnerabilidades `CRITICAL` corrigíveis.
9. Gere e preserve relatórios, SBOM e proveniência na release.

## Versionar e publicar

1. Escolha tag imutável que represente versão upstream e variante.
2. Não publique `latest` sem uma política explícita no README.
3. Use `.github/workflows/publish-image.yml` para build e push no Docker Hub.
4. Informe `context_path`, `image_name`, `image_tag`, Dockerfile e plataformas.
5. Confirme que os inputs correspondem ao catálogo e que o gate pré-push passou em todas as plataformas.
6. Confirme o digest e os manifests publicados.
7. Sincronize o README apenas após a verificação remota.

## Secrets do repositório

- `DOCKERHUB_USERNAME`: usuário Docker Hub com acesso ao namespace `lzocateli`.
- `DOCKERHUB_TOKEN`: Access Token com permissão de leitura, escrita e exclusão somente se exclusão for realmente necessária.

Nunca solicite ou registre o valor dos secrets no chat, código ou logs.

## Resultado esperado

Informe arquivos alterados, tag produzida, plataformas, validações executadas, digest publicado e limitações não verificadas.
