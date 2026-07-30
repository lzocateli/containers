<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# NGINX com headers-more e GeoIP2 dinâmicos

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fnginx-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-1.28.0--bookworm-2E7D32)
![Base](https://img.shields.io/badge/base-nginx%3A1.28.0--bookworm-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Imagem NGINX estável baseada em `nginx:1.28.0-bookworm`, com módulos dinâmicos `headers-more` e `geoip2` compilados em build multi-stage. O contrato da imagem prioriza configuração por bind mount em `/etc/nginx/conf.d`.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/nginx:1.28.0-bookworm` |
| Imagem base | `nginx:1.28.0-bookworm` |
| Plataformas | `linux/amd64` |
| Usuário padrão | `root` (herdado da imagem base) |
| Entry point | `/docker-entrypoint.sh` |
| Comando padrão | `nginx -g 'daemon off;'` |
| Diretório de trabalho | `/` |
| Módulos dinâmicos | `ngx_http_headers_more_filter_module.so`, `ngx_http_geoip2_module.so` |
| Arquivo principal | `/etc/nginx/nginx.conf` |
| Código-fonte | `https://github.com/lzocateli/containers/tree/main/nginx` |
| Documentação | `https://github.com/lzocateli/containers/tree/main/nginx` |

## Conteúdo e finalidade

### Incluído

- NGINX Open Source 1.28.0 sobre Debian Bookworm.
- Módulo `headers-more` carregado automaticamente em `/etc/nginx/modules-enabled/50-mod-http-headers-more-filter.conf`.
- Módulo `geoip2` carregado automaticamente em `/etc/nginx/modules-enabled/51-mod-http-geoip2.conf`.
- Conteúdo estático de erro customizado em `/usr/share/nginx/html/custom-error-page/`.
- Configuração base enxuta em `/etc/nginx/nginx.conf`, delegando `server` blocks para `/etc/nginx/conf.d/*.conf`.

### Não incluído

- Certificados TLS e chaves privadas.
- Base de dados GeoIP (`.mmdb`).
- `server` blocks de aplicação específicos do ambiente.
- Health check no Dockerfile (o `compose.yaml` inclui healthcheck leve por HTTP local).

## Início rápido

Baixe a imagem:

```bash
docker pull lzocateli/nginx:1.28.0-bookworm
```

Exemplo mínimo com configuração e dados GeoIP por bind mount:

```bash
mkdir -p ./conf.d ./geoip-data

docker run --name nginx \
  --detach \
  --publish 127.0.0.1:8080:80 \
  --mount type=bind,src="$(pwd)/conf.d",dst=/etc/nginx/conf.d,readonly \
  --mount type=bind,src="$(pwd)/geoip-data",dst=/usr/share/GeoIP,readonly \
  lzocateli/nginx:1.28.0-bookworm
```

Antes de subir, valide a configuração montada:

```bash
docker run --rm \
  --mount type=bind,src="$(pwd)/nginx.conf",dst=/etc/nginx/nginx.conf,readonly \
  --mount type=bind,src="$(pwd)/conf.d",dst=/etc/nginx/conf.d,readonly \
  --mount type=bind,src="$(pwd)/geoip-data",dst=/usr/share/GeoIP,readonly \
  lzocateli/nginx:1.28.0-bookworm nginx -t
```

## Execução com Podman

Modo serviço (exemplo com rede dedicada e TLS):

```bash
podman rm nginx -f 2>/dev/null || true

podman run -d \
  --name nginx \
  --network lzo \
  --network-alias nginx \
  -p 443:443 \
  -v /userapps/ssl:/etc/nginx/ssl:ro \
  -v /userapps/configs/geoip2/data:/usr/share/GeoIP:ro \
  -v /userapps/configs/nginx:/etc/nginx/conf.d:ro \
  -v /var/log/nginx:/var/log/nginx \
  lzocateli/nginx:1.28.0-bookworm
```

Validação de sintaxe com Podman:

```bash
podman run --rm \
  -v /userapps/configs/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v /userapps/configs/nginx:/etc/nginx/conf.d:ro \
  -v /userapps/configs/geoip2/data:/usr/share/GeoIP:ro \
  lzocateli/nginx:1.28.0-bookworm nginx -t
```

Em ambiente Windows/PowerShell, ajuste os caminhos para o formato absoluto local, como `c:/Users/...`.

## Docker Compose

O diretório já inclui um arquivo pronto: `compose.yaml`.

Passos recomendados:

```bash
cp .env.example .env
podman network exists lzo || podman network create lzo
podman compose up -d
```

Se estiver usando Docker Compose, substitua o último comando por `docker compose up -d`.

As configurações de paths, portas e rede ficam no arquivo `.env`.

## Configuração

### Variáveis de ambiente

A imagem não adiciona variáveis de ambiente de configuração próprias. A configuração é feita por arquivos montados em bind mounts.

Para execução via Compose, use as variáveis abaixo no arquivo `.env`:

| Variável | Obrigatória | Secreta | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| `NGINX_MAIN_CONFIG_FILE` | Sim | Não | Nenhum | Caminho absoluto do `nginx.conf` no host. |
| `NGINX_CONFD_DIR` | Sim | Não | Nenhum | Caminho absoluto dos `server` blocks (`*.conf`) no host. |
| `NGINX_GEOIP_DIR` | Sim (quando geoip é usado) | Não | Nenhum | Caminho absoluto com arquivos `.mmdb`. |
| `NGINX_SSL_DIR` | Sim (quando HTTPS é usado) | Sim | Nenhum | Caminho absoluto de certificados e chaves TLS. |
| `NGINX_LOG_DIR` | Sim | Não | Nenhum | Caminho absoluto para persistir logs do NGINX. |
| `NGINX_NETWORK_NAME` | Não | Não | `lzo` | Nome da rede externa usada pelo serviço. |
| `NGINX_HTTP_BIND` | Não | Não | `127.0.0.1:8080:80` | Bind de publicação HTTP. |
| `NGINX_HTTPS_BIND` | Não | Não | `443:443` | Bind de publicação HTTPS. |

### Portas

| Porta | Protocolo | Exposição recomendada | Finalidade |
| --- | --- | --- | --- |
| `80/tcp` | HTTP | `127.0.0.1` ou rede interna | Tráfego HTTP quando definido em `server` block. |
| `443/tcp` | HTTPS | Rede interna ou borda controlada | Tráfego TLS quando definido em `server` block e certificados válidos. |

O endpoint interno de healthcheck usa `127.0.0.1:8081/nginx-healthz` apenas dentro do contêiner e não precisa ser publicado no host.

### Persistência e mounts

| Caminho no contêiner | Modo | Conteúdo | Backup necessário |
| --- | --- | --- | --- |
| `/etc/nginx/nginx.conf` | `ro` | Configuração principal do NGINX | Sim |
| `/etc/nginx/conf.d` | `ro` | `server` blocks e includes de aplicação | Sim |
| `/usr/share/GeoIP` | `ro` | Arquivos de banco GeoIP2 (`.mmdb`) | Sim |
| `/etc/nginx/ssl` | `ro` | Certificados/chaves TLS | Sim |
| `/var/log/nginx` | `rw` | Logs de acesso e erro (opcional) | Não |
| `/usr/share/nginx/html` | `ro` ou `rw` | Conteúdo estático e página de erro customizada | Sim |

### Uso da página de erro customizada

O arquivo `custom-error.locations` é distribuído em `/etc/nginx/conf.d/custom-error.locations`, mas não é carregado automaticamente por `nginx.conf` porque a diretiva padrão usa `*.conf`.

Inclua o arquivo dentro de um `server` block, por exemplo:

```nginx
server {
    listen 80;
    server_name _;

    include /etc/nginx/conf.d/custom-error.locations;

    location / {
        proxy_pass http://app:8080;
    }
}
```

## Inicialização e ciclo de vida

O entrypoint oficial do NGINX é preservado. Na inicialização, os módulos dinâmicos são carregados via `/etc/nginx/modules-enabled/*.conf`, o arquivo base `/etc/nginx/nginx.conf` é lido e os `server` blocks montados em `/etc/nginx/conf.d` passam a compor o runtime.

O `compose.yaml` define um healthcheck leve com `curl` contra `http://127.0.0.1:8081/nginx-healthz`, que retorna `204` por um `server` interno dedicado no `nginx.conf`.

`SIGTERM` encerra o processo principal de forma graciosa conforme comportamento padrão do NGINX.

## Segurança

- Não armazene certificados, chaves ou segredos na imagem.
- Monte `/etc/nginx/ssl` e arquivos sensíveis como somente leitura.
- Prefira publicar portas apenas em `localhost` quando não houver necessidade de exposição externa.
- Restrinja permissões de leitura aos arquivos GeoIP e TLS no host.
- Valide configuração com `nginx -t` antes de atualizar o serviço.

## Build local

A partir da raiz do repositório:

```bash
docker build --pull --tag lzocateli/nginx:1.28.0-bookworm nginx
```

Validação de sintaxe do Dockerfile com BuildKit:

```bash
docker buildx build --check --file nginx/Dockerfile nginx
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `1.28.0-bookworm` | Imutável | NGINX 1.28.0 + módulos dinâmicos `headers-more` e `geoip2` | Produção |
| `1.28.0-bookworm-rN` | Imutável | Revisões do mesmo upstream com ajustes de imagem | Correções sem troca de major/minor |

Não há política de publicação para `latest`. Toda mudança de contrato (base, módulos, entrypoint, portas, mounts ou configuração esperada) deve receber nova tag imutável.

## Validação

Antes da publicação, confirme:

- `.gitignore` e `.dockerignore` presentes e atualizados;
- exclusão de `.env`, secrets e `.git` do contexto de build;
- `docker buildx build --check` sem erros;
- build da imagem para `linux/amd64`;
- `nginx -t` com os mounts reais de runtime;
- `docker inspect --format '{{.State.Health.Status}}' nginx` retornando `healthy`;
- smoke test com resposta HTTP/HTTPS do serviço alvo;
- inspeção de labels OCI, entrypoint e módulos carregados;
- scan de vulnerabilidades, SBOM e proveniência no workflow oficial.

## Publicação

Use **Actions > Publicar imagem de container > Run workflow** com:

- `context_path`: `nginx`;
- `image_name`: `nginx`;
- `image_tag`: `1.28.0-bookworm`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64`.

## Operação

- Faça backup dos arquivos de configuração montados no host (`nginx.conf`, `conf.d`, certificados e dados GeoIP) antes de qualquer atualização.
- Atualize sempre por nova tag imutável e valide com `nginx -t` antes do restart.
- Para rollback, volte para a tag anterior e restaure a mesma configuração validada no host.
- Use `docker logs -f nginx` ou `podman logs -f nginx` para troubleshooting operacional.

## Troubleshooting

| Sintoma | Causa provável | Verificação | Correção |
| --- | --- | --- | --- |
| `nginx: [emerg] "location" directive is not allowed here` | `custom-error.locations` foi incluído fora de um `server` block | `nginx -t` | Incluir `custom-error.locations` dentro de um `server { ... }`. |
| `open() "/usr/share/GeoIP/*.mmdb" failed` | Base GeoIP ausente ou caminho incorreto | Logs do contêiner e `nginx -t` | Montar banco `.mmdb` em `/usr/share/GeoIP` e ajustar a configuração. |
| Falha ao iniciar HTTPS | Certificado/chave inválidos ou sem permissão | Logs do contêiner | Corrigir arquivos em `/etc/nginx/ssl` e permissões no host. |
| Serviço sobe sem responder na porta esperada | `server` block não define `listen` correspondente | `nginx -T` | Ajustar `listen`/`server_name` no arquivo montado em `/etc/nginx/conf.d`. |

## Limitações conhecidas

- Plataforma publicada e validada: somente `linux/amd64`.
- A imagem não distribui banco GeoIP nem certificados TLS.
- Não há `HEALTHCHECK` definido no Dockerfile; configure no runtime quando necessário.

## Licenças e fontes

| Componente | Versão | Licença | Fonte |
| --- | --- | --- | --- |
| Conteúdo original deste repositório | Atual | MIT | `https://github.com/lzocateli/containers` |
| NGINX | 1.28.0 | BSD-2-Clause | `https://nginx.org/en/LICENSE` |
| Módulo headers-more | 0.38 | BSD-2-Clause | `https://github.com/openresty/headers-more-nginx-module` |
| Módulo ngx_http_geoip2_module | 3.4 | BSD-2-Clause | `https://github.com/leev/ngx_http_geoip2_module` |

O badge MIT descreve somente o conteúdo original deste repositório. Componentes de terceiros permanecem sujeitos às suas próprias licenças e avisos upstream. Consulte a política de licenciamento: https://github.com/lzocateli/containers/blob/main/LICENSING.md.

## Histórico de alterações

- `1.28.0-bookworm`: atualiza a base para NGINX 1.28.0 (Bookworm), adiciona build multi-stage e padroniza carregamento dos módulos dinâmicos `headers-more` e `geoip2`.

