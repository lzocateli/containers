<!--
SPDX-FileCopyrightText: 2026 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# NGINX para aplicações Angular com configurações comuns

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fnginx--angular-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-1.28.0--bookworm--r2-2E7D32)
![Base](https://img.shields.io/badge/base-lzocateli%2Fnginx%3A1.28.0--bookworm-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Imagem derivada de `lzocateli/nginx:1.28.0-bookworm` para servir aplicações Angular e disponibilizar fragmentos reutilizáveis de NGINX. Consulte também a documentação da [imagem base NGINX](../nginx/README.md).

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/nginx-angular:1.28.0-bookworm-r2` |
| Imagem base | `lzocateli/nginx:1.28.0-bookworm` |
| Plataformas | `linux/amd64` |
| Usuário padrão | `root` (herdado da imagem base) |
| Entry point | `/docker-entrypoint.sh` |
| Comando padrão | `nginx -g 'daemon off;'` |
| Porta | `80/tcp` |
| Fragmentos distribuídos | `/etc/nginx/conf.d/*.conf` |
| Código-fonte | `https://github.com/lzocateli/containers/tree/main/nginx-angular` |
| Documentação | `https://github.com/lzocateli/containers/tree/main/nginx-angular` |

## Conteúdo e finalidade

### Incluído

- Imagem base `lzocateli/nginx:1.28.0-bookworm` (NGINX 1.28.0 com módulos dinâmicos `headers-more` e `geoip2`).
- Arquivos `*.conf` do diretório `Common` copiados para `/etc/nginx/conf.d` durante o build.
- Fragmentos consolidados em `proxy-headers-base.conf`, `proxy-headers-single-base.conf` e `proxy-aspnet.conf`, além de configurações globais, logs JSON, WebSocket e compressão.

### Não incluído

- Conteúdo estático compilado da aplicação Angular (deve ser montado em `/usr/share/nginx/html` ou copiado em imagem derivada).
- Certificados TLS/SSL e chaves privadas.
- `server` blocks específicos do ambiente.

## Exemplo de configuração NGINX para Angular

```nginx
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

Monte o conteúdo compilado do Angular em `/usr/share/nginx/html` como somente leitura ou crie uma imagem derivada desta que execute `COPY dist/ /usr/share/nginx/html/`.

## Início rápido

Baixe a imagem:

```bash
docker pull lzocateli/nginx-angular:1.28.0-bookworm-r2
```

Exemplo rápido com Docker:

```bash
docker run --name nginx-angular \
  --detach \
  --publish 127.0.0.1:8080:80 \
  --mount type=bind,src="$(pwd)/dist",dst=/usr/share/nginx/html,readonly \
  lzocateli/nginx-angular:1.28.0-bookworm-r2
```

## Docker Compose

```yaml
services:
  web:
    image: lzocateli/nginx-angular:1.28.0-bookworm-r2
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:80"
    volumes:
      - ./dist:/usr/share/nginx/html:ro
```

## Build local

Na raiz do repositório `containers`:

```bash
docker build --pull --platform linux/amd64 \
  --tag lzocateli/nginx-angular:1.28.0-bookworm-r2 \
  nginx-angular
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `1.28.0-bookworm-r2` | Imutável | NGINX 1.28.0 com configuração Common carregada por padrão | Aplicações Angular |

Não use `latest`. Publique nova tag imutável quando a base ou qualquer fragmento distribuído mudar.

## Validação

```bash
docker buildx build --check --file nginx-angular/Dockerfile nginx-angular
docker run --rm lzocateli/nginx-angular:1.28.0-bookworm-r2 nginx -t
```

Valide também a configuração final da aplicação, os includes usados e a resposta HTTP antes de publicar.

## Publicação

Use **Actions > Publicar imagem de container > Run workflow** e informe:

- `context_path`: `nginx-angular`
- `image_name`: `nginx-angular`
- `image_tag`: `1.28.0-bookworm-r2`
- `dockerfile`: `Dockerfile`
- `platforms`: `linux/amd64`

O workflow publica no Docker Hub e sincroniza este `README.md` como descrição da imagem.

## Segurança

- Não inclua certificados, chaves ou arquivos `.env` no contexto de build.
- Monte configurações de ambiente, certificados e conteúdo da aplicação como somente leitura (`ro`) quando possível.
- Não exponha a porta HTTP diretamente na internet sem TLS e controles de borda.

## Licenças e fontes

| Componente | Versão | Licença | Fonte |
| --- | --- | --- | --- |
| Conteúdo original deste repositório | Atual | MIT | `https://github.com/lzocateli/containers` |
| Imagem NGINX base | 1.28.0-bookworm | Conforme imagem base | `https://github.com/lzocateli/containers/tree/main/nginx` |
| NGINX | 1.28.0 | BSD-2-Clause | `https://nginx.org/en/LICENSE` |

O badge MIT descreve somente o conteúdo original deste repositório. Componentes de terceiros permanecem sujeitos às respectivas licenças. Consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md).

## Histórico de alterações

- `1.28.0-bookworm-r2`: carrega como configuração padrão os arquivos `*.conf` de `Common/` em `/etc/nginx/conf.d`.
- `1.28.0-bookworm-r1`: cria a imagem derivada de `lzocateli/nginx:1.28.0-bookworm`.
