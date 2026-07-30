---
description: "Use ao criar, alterar, otimizar ou revisar Dockerfiles. Cobre multi-stage builds, cache, segurança, labels OCI, health check e imagens reproduzíveis."
applyTo: "**/Dockerfile*"
---

# Dockerfile

- Fixe a imagem base por versão específica; para releases críticas, registre também o digest.
- Use multi-stage build quando houver compilação, download, geração de artefatos ou ferramentas que não sejam necessárias em runtime.
- Nomeie estágios com `AS build`, `AS test` e `AS runtime`; copie para o estágio final apenas os artefatos necessários.
- Ordene comandos para preservar cache: metadados e manifests antes do código que muda com frequência.
- Combine instalação e limpeza do gerenciador de pacotes no mesmo `RUN`; use `--no-install-recommends` quando disponível.
- Use mounts de cache e secrets do BuildKit quando apropriado. Nunca transporte segredo por `ARG`, `ENV`, `COPY` ou camada intermediária.
- Toda pasta de imagem deve possuir `.dockerignore` e `.gitignore`, adaptados dos templates em `.github/templates/ignore/`.
- Use `.dockerignore` restritivo. Não envie `.git`, `.env`, secrets, credenciais, dados persistentes, backups, caches ou artefatos locais ao contexto.
- Use `.gitignore` para impedir versionamento de secrets, configurações locais, persistência, backups, logs e artefatos gerados.
- Antes do build, inspecione o contexto e confirme que nenhum arquivo ignorado necessário foi reintroduzido por regra de negação com `!`.
- Execute como usuário não root no estágio final, salvo requisito documentado da imagem base.
- Use `COPY --chown` em vez de `RUN chown` quando suportado.
- Prefira `ENTRYPOINT` e `CMD` em formato JSON. Garanta propagação de sinais e encerramento limpo do PID 1.
- Declare somente portas e volumes que fazem parte do contrato público.
- Adicione `HEALTHCHECK` apenas quando houver uma verificação útil e barata; não use processos temporários de bootstrap como sinal de saúde.
- Inclua obrigatoriamente em todo Dockerfile publicável os labels OCI `title`, `description`, `source`, `documentation` e `url`.
- Inclua também o label OCI `version` sempre que a versão da imagem estiver disponível no contexto do Dockerfile.
- Use `licenses` somente com uma expressão SPDX validada para o artefato distribuído; não use `MIT` apenas porque o conteúdo original do repositório é MIT.
- Não instale compiladores, shells administrativos ou clientes desnecessários na imagem final.
- Minimize camadas sem condensar comandos que tenham ciclos de cache distintos.
- Preserve suporte às plataformas declaradas; não fixe sufixo de arquitetura na imagem base sem justificar no README.
- Toda alteração de base, usuário, entrypoint, porta, volume ou variável deve atualizar `README.md` e a tag quando afetar compatibilidade.

Estrutura preferencial:

```dockerfile
# syntax=docker/dockerfile:1
FROM base:version AS build
WORKDIR /src
COPY manifest lockfile ./
RUN --mount=type=cache,target=/cache comando-de-restore
COPY . .
RUN comando-de-build

FROM runtime:version AS runtime
LABEL org.opencontainers.image.source="https://github.com/lzocateli/containers"
WORKDIR /app
COPY --from=build --chown=10001:10001 /src/out ./
USER 10001:10001
ENTRYPOINT ["/app/processo"]
```
