<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# Certbot DNS Cloudflare

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fcertbot--dns--cloudflare-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-5.7.0-2E7D32)
![Base](https://img.shields.io/badge/base-certbot%2Fdns--cloudflare%3Av5.7.0-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-BuildKit-success)

Certbot com o plugin `certbot-dns-cloudflare` para emissão e renovação automatizada de certificados TLS Let's Encrypt via desafio DNS-01. Permite gerar certificados wildcard e para domínios sem expor a porta 80, ideal para serviços internos com DNS gerenciado na Cloudflare.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/certbot-dns-cloudflare:5.7.0` |
| Imagem base | `certbot/dns-cloudflare:v5.7.0` |
| Plataformas | `linux/amd64` |
| Usuário padrão | `root` (exigido pelo certbot para gravação dos certificados) |
| Entry point | `certbot` (herdado da imagem base) |
| Diretório de trabalho | `/` |
| Código-fonte | `https://github.com/lzocateli/containers/tree/main/certbot` |
| Documentação | `https://github.com/lzocateli/containers/tree/main/certbot` |

## Conteúdo e finalidade

### Incluído

- Certbot 5.7.0 com CLI completa;
- Plugin `certbot-dns-cloudflare` para desafio DNS-01;
- Labels OCI adicionadas pelo wrapper `lzocateli/certbot-dns-cloudflare`.

### Não incluído

- Credenciais de API da Cloudflare (devem ser montadas em runtime);
- Servidor web ou listener de rede;
- Agendador de renovação automática (cron ou systemd devem ser configurados externamente);
- Configuração de domínio ou e-mail;
- Certificados gerados (armazenados em bind mount externo).

## Início rápido

```bash
docker pull lzocateli/certbot-dns-cloudflare:5.7.0
docker run --rm lzocateli/certbot-dns-cloudflare:5.7.0 --version
```

## Emissão de certificado

Crie o arquivo de credenciais da Cloudflare (não versione este arquivo):

```ini
# /caminho/local/.secrets/certbot/cloudflare.ini
dns_cloudflare_api_token = SEU_TOKEN_AQUI
```

Execute a emissão com desafio DNS-01:

```bash
docker run --rm \
  --name certbot \
  -v /userapps/certs:/etc/letsencrypt:z \
  -v /userapps/certs/_logs:/var/log/letsencrypt:z \
  -v /caminho/local/.secrets/certbot/cloudflare.ini:/root/.secrets/certbot/cloudflare.ini:ro,z \
  lzocateli/certbot-dns-cloudflare:5.7.0 \
    certonly \
    --noninteractive \
    --dns-cloudflare \
    --dns-cloudflare-credentials /root/.secrets/certbot/cloudflare.ini \
    --force-renewal \
    --max-log-backups 5 \
    -d exemplo.com.br \
    -d "*.exemplo.com.br" \
    --email seu_email@exemplo.com \
    --agree-tos
```

Após a execução, copie o certificado para o seu web server:

```bash
cp /userapps/certs/live/exemplo.com.br/fullchain.pem /userapps/ssl/exemplo.com.br.pem
cp /userapps/certs/live/exemplo.com.br/privkey.pem   /userapps/ssl/exemplo.com.br.key
```

## Docker Compose

Exemplo de execução pontual integrada a um stack Compose:

```yaml
services:
  certbot:
    image: lzocateli/certbot-dns-cloudflare:5.7.0
    volumes:
      - /userapps/certs:/etc/letsencrypt:z
      - /userapps/certs/_logs:/var/log/letsencrypt:z
      - /caminho/local/.secrets/certbot/cloudflare.ini:/root/.secrets/certbot/cloudflare.ini:ro,z
    command: >
      certonly
      --noninteractive
      --dns-cloudflare
      --dns-cloudflare-credentials /root/.secrets/certbot/cloudflare.ini
      --force-renewal
      --max-log-backups 5
      -d exemplo.com.br
      --email seu_email@exemplo.com
      --agree-tos
```

## Configuração

### Variáveis de ambiente

Esta imagem não define variáveis de ambiente adicionais. Todas as configurações são passadas como argumentos CLI ao `certbot`.

### Mounts obrigatórios

| Caminho no contêiner | Modo | Conteúdo | Backup necessário |
| --- | --- | --- | --- |
| `/etc/letsencrypt` | `rw` | Certificados, chaves e metadados de renovação | **Sim** |
| `/var/log/letsencrypt` | `rw` | Logs de emissão e renovação | Não |
| `/root/.secrets/certbot/cloudflare.ini` | `ro` | Token de API da Cloudflare | Não (gerenciado externamente) |

### Secrets

O arquivo `cloudflare.ini` deve conter somente:

```ini
dns_cloudflare_api_token = SEU_TOKEN_AQUI
```

Permissões recomendadas no host: `chmod 600 cloudflare.ini`. Nunca versione este arquivo; use `.gitignore` para bloqueá-lo.

O token de API da Cloudflare precisa das seguintes permissões:

- Zone → DNS → Edit
- Zone → Zone → Read

![Permissões de token Cloudflare](.attachements/Tokens%20de%20API%20de%20usuário%20Cloudflare.png)

## Inicialização e ciclo de vida

O contêiner executa `certbot` como processo único, grava os certificados no mount `/etc/letsencrypt` e encerra. Não é um serviço de longa duração.

Para renovação automática, configure um cron job ou systemd timer no host que execute o contêiner periodicamente (ex.: duas vezes por semana). Certbot renova apenas certificados que expiram em menos de 30 dias quando usado com `renew`.

Exemplo de cron para renovação:

```cron
0 3 * * 1,4 docker run --rm -v /userapps/certs:/etc/letsencrypt:z -v /userapps/certs/_logs:/var/log/letsencrypt:z -v /caminho/.secrets/certbot/cloudflare.ini:/root/.secrets/certbot/cloudflare.ini:ro,z lzocateli/certbot-dns-cloudflare:5.7.0 renew --quiet
```

## Segurança

- O processo executa como `root` — necessário para gravação dos certificados nas pastas gerenciadas pelo certbot;
- O arquivo `cloudflare.ini` deve ser montado como somente leitura (`:ro`);
- Nunca incorpore o token de API na imagem, em variáveis de ambiente ou em argumentos de linha de comando visíveis em `docker inspect`;
- Use permissões `600` no arquivo de credenciais no host;
- Não exponha o bind mount `/etc/letsencrypt` com permissão de escrita para outros contêineres além do certbot e do web server que lê os certificados;
- Atualize a tag da imagem para receber correções de segurança do certbot e do plugin Cloudflare.

## Certificados de teste (staging)

Para validar o fluxo sem consumir os limites de rate da Let's Encrypt, acrescente os argumentos abaixo. Os certificados gerados serão **inválidos para produção**:

```
--test-cert \
--server https://acme-staging-v02.api.letsencrypt.org/directory
```

## Build local

```bash
docker build --pull --tag lzocateli/certbot-dns-cloudflare:5.7.0 certbot
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `5.7.0` | Imutável | Certbot 5.7.0 + plugin dns-cloudflare | Produção |

Não há política para `latest`. Atualize a tag na composição e valide a renovação antes do rollout.

## Validação

Antes da publicação, confirme:

- `.gitignore` e `.dockerignore` presentes e bloqueando `.secrets/` e `*.ini`;
- build sem erros com BuildKit;
- smoke test: `docker run --rm lzocateli/certbot-dns-cloudflare:5.7.0 --version`;
- inspeção dos labels OCI: `docker inspect lzocateli/certbot-dns-cloudflare:5.7.0 --format '{{json .Config.Labels}}'`;
- emissão de certificado de staging (`--test-cert`) com domínio de teste antes da publicação.

```bash
docker buildx build --check --file certbot/Dockerfile certbot
docker build --pull --tag lzocateli/certbot-dns-cloudflare:5.7.0 certbot
docker run --rm lzocateli/certbot-dns-cloudflare:5.7.0 --version
docker inspect lzocateli/certbot-dns-cloudflare:5.7.0 --format '{{json .Config.Labels}}'
```

## Publicação

Use **Actions > Publicar imagem de container > Run workflow** com:

- `context_path`: `certbot`;
- `image_name`: `certbot-dns-cloudflare`;
- `image_tag`: `5.7.0`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64`.

O workflow publica no Docker Hub com SBOM e proveniência e pode sincronizar este README. A publicação não ocorre durante o build local.

## Operação

Mantenha backup do diretório `/etc/letsencrypt` do host — ele contém as chaves privadas e metadados de renovação. Para atualizar a imagem, reconstrua com a nova tag, valide com staging e ajuste o cron/systemd timer.

## Troubleshooting

| Sintoma | Causa provável | Verificação | Correção |
| --- | --- | --- | --- |
| `Error: certbot.errors.PluginError` | Token de API inválido ou sem permissão DNS | Verifique permissões do token na Cloudflare | Crie token com Zone → DNS → Edit e Zone → Zone → Read |
| `Permission denied` ao ler `.ini` | Permissão incorreta no arquivo de credenciais | `ls -la /caminho/.secrets/certbot/cloudflare.ini` | `chmod 600 cloudflare.ini` |
| Certificado não renovado | Expira em mais de 30 dias | `certbot certificates` | Use `--force-renewal` para forçar |
| `Too Many Requests` (rate limit) | Muitas emissões no mesmo domínio | Verifique o histórico em https://crt.sh | Use `--test-cert` para testes; aguarde o reset do limite |
| DNS propagation timeout | Cloudflare demorou para propagar a entrada TXT | Adicione `--dns-cloudflare-propagation-seconds 60` | Aumente o timeout de propagação |

## Limitações conhecidas

- Suporta apenas o plugin `dns-cloudflare`; outros provedores DNS exigem imagens diferentes.
- Plataforma `linux/amd64` apenas.

## Licenças e fontes

| Componente | Versão | Licença | Fonte |
| --- | --- | --- | --- |
| Conteúdo original deste repositório | Atual | MIT | `https://github.com/lzocateli/containers` |
| certbot | 5.7.0 | Apache-2.0 | `https://github.com/certbot/certbot` |
| certbot-dns-cloudflare | incluído | Apache-2.0 | `https://github.com/certbot/certbot` |

O badge MIT descreve somente o conteúdo original deste repositório. A imagem inclui componentes de terceiros que permanecem sujeitos aos termos e avisos de suas fontes. Consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md), preserve as atribuições upstream e verifique também os avisos distribuídos dentro da imagem.

## Histórico de alterações

| Tag | Alteração |
| --- | --- |
| `5.7.0` | Atualização da base para `certbot/dns-cloudflare:v5.7.0`; adição de labels OCI, `.gitignore` e `.dockerignore` |
