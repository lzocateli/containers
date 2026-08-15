<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# GeoIP2 Update Agent

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fgeoipupdate-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-8.0.0-2E7D32)
![Base](https://img.shields.io/badge/base-ghcr.io%2Fmaxmind%2Fgeoipupdate%3Av8.0.0--amd64-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Container agendado que atualiza automaticamente bases de dados GeoIP2 da MaxMind. Executa em modo daemon com frequência configurável, ideal para servir dados geográficos em aplicações que usam módulos como `ngx_http_geoip2_module` do NGINX.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/geoipupdate:8.0.0` |
| Imagem base | `ghcr.io/maxmind/geoipupdate:v8.0.0-amd64` |
| Plataformas | `linux/amd64` |
| Usuário padrão | `geoipupdate:geoipupdate` (uid:gid 1000:1000) |
| Entry point | Herdado da imagem base (`geoipupdate`) |
| Comando padrão | Executa geoipupdate em modo daemon |
| Diretório de trabalho | `/` |
| Volume de dados | `/usr/share/GeoIP` |
| Código-fonte | `https://github.com/lzocateli/containers/tree/main/geoipupdate` |
| Documentação | `https://github.com/lzocateli/containers/tree/main/geoipupdate` |

## Conteúdo e finalidade

### Incluído

- MaxMind geoipupdate v8.0.0.
- Suporte a múltiplas bases de dados GeoIP2 (GeoLite2 gratuitas ou premium).
- Agendamento automático via variável `GEOIPUPDATE_FREQUENCY`.
- Logging detalhado via `GEOIPUPDATE_VERBOSE`.

### Não incluído

- Conta e chave de licença MaxMind (consumidor deve fornecer).
- Bases de dados pré-carregadas (baixadas no primeiro start).
- TLS/certificados (o container não expõe porta HTTP).

## Início rápido

Baixe a imagem:

```bash
docker pull lzocateli/geoipupdate:8.0.0
```

Exemplo mínimo com arquivo `.env`:

```bash
cat > geoip2.env << 'EOF'
GEOIPUPDATE_ACCOUNT_ID=999999
GEOIPUPDATE_LICENSE_KEY=your_license_key_here
GEOIPUPDATE_EDITION_IDS=GeoLite2-City GeoLite2-Country GeoLite2-ASN
GEOIPUPDATE_FREQUENCY=48
GEOIPUPDATE_VERBOSE=1
EOF

docker run --name geoipupdate \
  --detach \
  --env-file geoip2.env \
  --mount type=bind,src="$(pwd)/geoip-data",dst=/usr/share/GeoIP \
  lzocateli/geoipupdate:8.0.0
```

Verificar logs:

```bash
docker logs geoipupdate
```

## Docker Compose

```yaml
services:
  geoipupdate:
    image: lzocateli/geoipupdate:8.0.0
    container_name: geoipupdate
    restart: unless-stopped
    env_file: geoip2.env
    volumes:
      - ./geoip-data:/usr/share/GeoIP
    healthcheck:
      test: [ "CMD", "test", "-f", "/usr/share/GeoIP/GeoLite2-City.mmdb" ]
      interval: 3600s
      timeout: 10s
      retries: 3
      start_period: 60s
```

## Configuração

### Variáveis de ambiente

Todas as variáveis são herdadas da imagem MaxMind oficial. As principais:

| Variável | Obrigatória | Secreta | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| `GEOIPUPDATE_ACCOUNT_ID` | Sim | Não | Nenhum | ID da conta MaxMind. |
| `GEOIPUPDATE_LICENSE_KEY` | Sim | **Sim** | Nenhum | Chave de licença MaxMind (segredo). |
| `GEOIPUPDATE_EDITION_IDS` | Não | Não | GeoLite2-City | IDs das bases separadas por espaço. Opções comuns: `GeoLite2-City`, `GeoLite2-Country`, `GeoLite2-ASN`, `GeoIP2-City` (premium). |
| `GEOIPUPDATE_FREQUENCY` | Não | Não | 0 | Frequência de atualização em horas (0 = uma vez na inicialização; ex: 48 = a cada 48h). |
| `GEOIPUPDATE_VERBOSE` | Não | Não | 0 | Ativar logging verboso (1 = ativado). |
| `HTTP_PROXY` | Não | Não | Nenhum | Proxy HTTP se necessário (ex: `http://proxy.example.com:80`). |
| `NO_PROXY` | Não | Não | Nenhum | Hosts que contornam proxy (ex: `localhost,127.0.0.1`). |

### Portas

A imagem **não expõe portas HTTP/TCP**. Comunica apenas com servers da MaxMind via HTTPS para download.

### Persistência e mounts

| Caminho no contêiner | Modo | Conteúdo | Backup necessário |
| --- | --- | --- | --- |
| `/usr/share/GeoIP` | `rw` | Bases de dados `.mmdb` (GeoIP2, GeoLite2) | **Sim** |

As bases são baixadas no primeiro start e reutilizadas em atualizações subsequentes. Persistência é **essencial** para evitar redownloads desnecessários.

Propriedade esperada:
- Usuário: `geoipupdate:geoipupdate` (uid:gid 1000:1000)
- Permissões: `rwx` (diretório), `rw-` (arquivos `.mmdb`)

Bind mount recomendado no host:

```bash
mkdir -p /userapps/configs/geoip2/data
chmod 755 /userapps/configs/geoip2/data
```

### Secrets

A licença MaxMind **NUNCA** deve ser armazenada em variáveis de ambiente gravadas em logs. Use:

- **Docker Secrets** (Swarm): passadas via `--secret` e montadas em `/run/secrets/`.
- **Docker Compose** (Dev): arquivo `.env` com permissões `600`, não versionado.
- **Kubernetes**: `Secret` object lido como `envFrom`.
- **Variáveis de ambiente** do host (CI/CD): carregadas via `env_file` ou direto da ferramenta de deploy.

Exemplo seguro com `.env.example`:

```bash
# .env.example (versionado, sem segredo)
GEOIPUPDATE_ACCOUNT_ID=MUDE_PARA_SEU_ID
GEOIPUPDATE_LICENSE_KEY=MUDE_PARA_SUA_CHAVE
GEOIPUPDATE_EDITION_IDS=GeoLite2-City GeoLite2-Country
GEOIPUPDATE_FREQUENCY=48
GEOIPUPDATE_VERBOSE=1
```

```bash
# .env (ignore file, local apenas, com segredos)
GEOIPUPDATE_ACCOUNT_ID=999999
GEOIPUPDATE_LICENSE_KEY=abc123def456...
```

## Inicialização e ciclo de vida

1. **Primeiro start**: Downloads todas as bases especificadas em `GEOIPUPDATE_EDITION_IDS`.
2. **Agendamento**: Se `GEOIPUPDATE_FREQUENCY > 0`, aguarda N horas e repete.
3. **Modo única vez**: Se `GEOIPUPDATE_FREQUENCY = 0`, executa e encerra após primeiro download.
4. **Logging**: Cada atualização registra resultado, versão das bases e timestamp.

Recomenda-se usar `GEOIPUPDATE_FREQUENCY=24` ou `48` para manter bases atualizadas em produção.

## Segurança

- **Usuário não root**: Executa como `geoipupdate:geoipupdate` (uid:gid 1000:1000).
- **Sem rede de entrada**: Não expõe portas; apenas conecta a servers MaxMind.
- **Secrets**: Licença deve ser injetada via environment, Docker Secrets ou Kubernetes Secret, nunca hardcoded no Dockerfile.
- **Imagem base**: Mantida a partir do registry MaxMind oficial (`ghcr.io/maxmind/geoipupdate`); audite verificações de vulnerabilidade regularmente.

Recomendação: Configure o host ou orquestrador para rotar secrets periodicamente (ex: a cada 90 dias).

## Build local

```bash
docker build \
  --pull \
  --tag lzocateli/geoipupdate:8.0.0 \
  geoipupdate
```

Para múltiplas plataformas:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag lzocateli/geoipupdate:8.0.0 \
  geoipupdate
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `8.0.0` | Imutável | MaxMind geoipupdate v8.0.0 | Produção estável |
| `latest` | Móvel | Versão mais recente | Dev/testes apenas |

**Política de atualização**: A cada nova versão estável do geoipupdate, cria-se uma tag imutável. A tag `latest` segue o upstream.

## Validação

Antes da publicação:

```bash
# Inspecionar Dockerfile
docker buildx build --dry-run geoipupdate

# Build local sem cache
docker build --no-cache -t test-geoip geoipupdate

# Smoke test: verificar se bases foram baixadas
docker run --rm \
  --env-file geoip2.env \
  --mount type=bind,src="$(pwd)/test-data",dst=/usr/share/GeoIP \
  test-geoip

ls test-data/  # Deve conter *.mmdb

# Inspecionar imagem
docker inspect test-geoip

# Scan de vulnerabilidades
trivy image test-geoip
```

## Publicação

Use **GitHub Actions > Publicar imagem de container > Run workflow** e informe:

- `context_path`: `geoipupdate`
- `image_name`: `geoipupdate`
- `image_tag`: `8.0.0`
- `dockerfile`: `Dockerfile`
- `platforms`: `linux/amd64,linux/arm64` (ou apenas `linux/amd64` se ARM não testada)

O workflow:
1. Valida Dockerfile com BuildKit.
2. Faz scan de vulnerabilidades (Trivy).
3. Gera SBOM.
4. Faz push ao Docker Hub como `lzocateli/geoipupdate:8.0.0`.
5. Sincroniza este README como descrição Docker Hub.

## Operação

### Backup

```bash
# Backup de bases (recomendado antes de deletar container)
tar -czf geoip-backup-$(date +%Y%m%d).tar.gz -C /userapps/configs/geoip2 data/
```

### Restore

```bash
# Restore de backup
tar -xzf geoip-backup-20250814.tar.gz -C /userapps/configs/geoip2
docker restart geoipupdate
```

### Atualizar para nova versão

```bash
# Parar e remover container antigo
docker stop geoipupdate && docker rm geoipupdate

# Pull nova versão (ex: 8.1.0)
docker pull lzocateli/geoipupdate:8.1.0

# Restart com mesma config e volume
docker run -d \
  --name geoipupdate \
  --env-file geoip2.env \
  --mount type=bind,src=/userapps/configs/geoip2/data,dst=/usr/share/GeoIP \
  lzocateli/geoipupdate:8.1.0
```

### Logs e monitoramento

```bash
# Logs em tempo real
docker logs -f geoipupdate

# Últimas N linhas
docker logs --tail 50 geoipupdate

# Com timestamp
docker logs -t geoipupdate
```

### Limites de recursos

Recomendação para Kubernetes:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

## Troubleshooting

| Sintoma | Causa provável | Verificação | Correção |
| --- | --- | --- | --- |
| "Invalid license key" | Credenciais MaxMind inválidas ou expiradas | `docker logs geoipupdate` | Verificar `GEOIPUPDATE_ACCOUNT_ID` e `GEOIPUPDATE_LICENSE_KEY` |
| Bases não baixadas | Permissões no volume | `ls -la /userapps/configs/geoip2/data/` | Rodar `chmod 755 /userapps/configs/geoip2/data` no host |
| Conexão recusada (proxy) | Proxy obrigatório no ambiente | `docker logs geoipupdate` | Configurar `HTTP_PROXY` e `NO_PROXY` |
| Container sai imediatamente (FREQUENCY=0) | Comportamento esperado com freq 0 | Sem ação | Usar `--restart=on-failure` ou `FREQUENCY > 0` |
| Falha de atualização periódica | Perda de conectividade ou mudança de credenciais | `docker logs -f geoipupdate` monitorado durante janela agendada | Validar conectividade com MaxMind; revisar credenciais |

## Limitações conhecidas

- **Apenas Linux amd64**: Imagem de origem MaxMind não oferece arm64 no momento da versão 8.0.0; aguardando atualização upstream.
- **Atualização manual**: Para forçar atualização imediata fora da agenda, reiniciar container com frequência maior ou usar sinal `SIGHUP` se suportado.
- **GeoLite2 gratuitas**: Requerem cadastro em `maxmind.com`; edições premium exigem licença paga.

## Licenças e fontes

| Componente | Versão | Licença | Fonte |
| --- | --- | --- | --- |
| Conteúdo original deste repositório | Atual | MIT | `https://github.com/lzocateli/containers` |
| geoipupdate (imagem base MaxMind) | v8.0.0 | Propriedade MaxMind | `https://github.com/maxmind/geoipupdate` |
| Bases de dados GeoIP2/GeoLite2 | Atualizado | Propriedade MaxMind | `https://www.maxmind.com/` |

O badge MIT descreve somente o conteúdo original deste repositório. A imagem inclui componentes de terceiros sob licenças MaxMind que permanecem sujeitos aos termos e avisos de suas fontes. Consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md), preserve as atribuições upstream e respeite os termos de uso das bases de dados MaxMind.

## Histórico de alterações

- **8.0.0** (2024): Atualização para geoipupdate v8.0.0; alinhamento com diretrizes de container do projeto; adição de labels OCI; documentação completa.
