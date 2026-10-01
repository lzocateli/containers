<!--
SPDX-FileCopyrightText: 2026 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# Nextcloud Community

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fnextcloud-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-35.0.1--r1-2E7D32)
![Base](https://img.shields.io/badge/base-nextcloud%3A35.0.1--apache-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-build%2Fsmoke%2FTrivy_passaram-success)

Wrapper sem customizacao da imagem oficial Nextcloud Community Apache. A imagem upstream e fixada por digest; o wrapper acrescenta labels OCI e uma verificacao HTTP local de saude. O objetivo e manter o contrato de runtime upstream sem embutir configuracao, dados ou credenciais.

## Referencia da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/nextcloud:35.0.1-r1` |
| Imagem base | `nextcloud:35.0.1-apache@sha256:276547e033df451770dbf9c0065929e5ea179a613b1884bd3fa807ba1c2703e7` |
| Release consultada | `35.0.1`, upstream `latest.txt`, 2026-09-28 |
| Plataformas declaradas | `linux/amd64` |
| Usuario padrao | `root`; o entrypoint upstream prepara os volumes e o Apache atende como `www-data` |
| Entry point e comando | Preservados da imagem oficial upstream |
| Porta | `80/tcp` |
| Persistencia upstream | `/var/www/html` (inclui `config`, `custom_apps` e `data`) |
| Codigo-fonte | `https://github.com/lzocateli/containers/tree/main/nextcloud` |
| Documentacao | `https://github.com/lzocateli/containers/tree/main/nextcloud` |

O wrapper foi publicado pelo workflow `publish-image.yml` em 2026-09-29. Digest do índice OCI: `sha256:d37bd86e18f9e60e700af4d40f6cc810dd4da411e66bdf0d18e10c8eef10c5d8`; manifesto `linux/amd64`: `sha256:356f612200cbf49565cf99e428eb2ec1c383af61ce64f40074169a6d29111dd6`. O workflow confirmou digest, plataforma e Trivy sem CRITICAL corrigível.

## Conteudo e finalidade

### Incluido

- Nextcloud Community 35.0.1, variante Apache oficial.
- Labels OCI e health check HTTP em `/status.php`.

### Nao incluido

- Banco de dados, Redis, proxy, certificados, secrets ou dados de usuario.
- Configuracao de producao ou exposicao de porta no host.

## Inicio rapido

O comando abaixo serve somente para teste local isolado. Em producao, nao publique a porta do Nextcloud diretamente; use o gateway mTLS descrito no projeto Ansible.

```bash
docker pull lzocateli/nextcloud:35.0.1-r1
docker run --rm --publish 127.0.0.1:8080:80 lzocateli/nextcloud:35.0.1-r1
```

## Docker Compose

Exemplo de contrato minimo, sem secrets reais. A stack de producao e gerenciada em `ansible/` e nao deve copiar este exemplo isolado.

```yaml
services:
  nextcloud:
    image: lzocateli/nextcloud:35.0.1-r1
    restart: unless-stopped
    volumes:
      - /mnt/pve_pool/nextcloud/html:/var/www/html
    expose:
      - "80"
```

## Configuracao

### Variaveis de ambiente

| Variavel | Obrigatoria | Secreta | Padrao | Descricao |
| --- | --- | --- | --- | --- |
| `POSTGRES_HOST`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` | Na instalacao | Senha sim | Nenhum | Configuracao inicial para PostgreSQL externo; a senha deve ser entregue por secret/runtime seguro. |
| `NEXTCLOUD_ADMIN_USER`, `NEXTCLOUD_ADMIN_PASSWORD` | No bootstrap automatizado | Senha sim | Nenhum | Conta administrativa inicial; remover do ambiente apos o bootstrap quando possivel. |
| `REDIS_HOST`, `REDIS_HOST_PASSWORD` | Para cache e file locking | Senha sim | Nenhum | Redis existente; reservar e validar um dbindex exclusivo antes de instalar. |
| `NEXTCLOUD_TRUSTED_DOMAINS` | Sim neste servico | Nao | Nenhum | Deve conter `nextcloud.lzoca`. |
| `TRUSTED_PROXIES` | Sim neste servico | Nao | Nenhum | Endereco do proxy `172.16.10.30`. |
| `OVERWRITEHOST`, `OVERWRITEPROTOCOL` | Sim neste servico | Nao | Nenhum | `nextcloud.lzoca` e `https` para o proxy TLS externo. |
| `PHP_UPLOAD_LIMIT`, `APACHE_BODY_LIMIT` | Recomendado | Nao | Upstream | Ajustar em conjunto ao limite configurado no proxy; alvo operacional inicial de 10 GiB. |

Os nomes e comportamentos das variaveis de bootstrap sao herdados da documentacao upstream. A automacao de producao deve injetar os valores via Ansible Vault, nao por `.env` versionado ou argumentos de build.

### Portas

| Porta | Protocolo | Exposicao recomendada | Finalidade |
| --- | --- | --- | --- |
| `80/tcp` | HTTP | Somente rede Docker privada | Apache interno; nunca publicada no host TrueNAS. |

### Persistencia e mounts

| Caminho no conteiner | Modo | Conteudo | Backup necessario |
| --- | --- | --- | --- |
| `/var/www/html` | `rw` | Aplicacao, configuracao, apps adicionados e arquivos dos usuarios | Sim |

A imagem oficial espera privilegios de root no entrypoint para preparar volumes; o processo web baixa privilegios para `www-data` (UID 33 na variante Debian). Confirmar UID/GID e ownership efetivos da tag antes de criar os diretorios em TrueNAS. Nao usar submounts adicionais sem verificar o `upgrade.exclude` upstream.

### Health check

O health check consulta `http://127.0.0.1/status.php` pelo PHP CLI. Ele confirma que o endpoint Apache responde HTTP 200, mas nao certifica disponibilidade do PostgreSQL, Redis, cron, proxy ou login. Durante o bootstrap a instalacao pode ainda nao estar pronta; o `start-period` de 10 minutos cobre a inicializacao inicial sem transformar o health check em teste funcional. O smoke test valida instalacao, PostgreSQL, Redis e persistencia separadamente.

## Inicializacao e ciclo de vida

- O `ENTRYPOINT` e o `CMD` oficiais sao preservados; a imagem nao substitui scripts de bootstrap e upgrade do upstream.
- O primeiro start pode demorar enquanto instala o Nextcloud no volume e conecta ao PostgreSQL.
- O servico cron deve usar a mesma imagem, configuracao e volume de `/var/www/html`, executando o comando upstream `/cron.sh`; o health check HTTP deve ser desativado nesse servico.
- Programe background jobs em modo cron pelo `occ` depois do bootstrap.
- Atualize uma versao principal por vez, com backup consistente e janela aprovada.

## Seguranca

- O backend deve ficar somente na rede Docker privada e ser acessivel pelo gateway Nginx mTLS.
- Nao publique a porta 80 no host nem exponha portas administrativas do TrueNAS.
- Use certificado cliente do proxy e valide a CA do backend no Nginx.
- Secrets entram em runtime pelo Ansible Vault. Nao os grave em labels, logs, `ARG`, `ENV` de build ou arquivos rastreados em claro.
- A imagem oficial roda entrypoint como root por requisito do contrato upstream; Apache atende como `www-data`.
- A imagem upstream e fixada pelo digest de `linux/amd64`; atualizacoes exigem nova tag imutavel e validacao.

## Build local

```bash
docker buildx build --pull --platform linux/amd64 \
  --tag lzocateli/nextcloud:35.0.1-r1 --load nextcloud
bash nextcloud/scripts/smoke-test.sh --image lzocateli/nextcloud:35.0.1-r1
```

O wrapper nao adiciona dependencias, pacotes ou arquivos ao build context. Consulte `containers/.github/skills/container-image-maintenance/SKILL.md` para gates de build, scan e publicacao.

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `35.0.1-r1` | Imutavel | Nextcloud Community 35.0.1 Apache | Publicada e validada; usar por digest |

Nao existe tag `latest` de producao. A tag nao deve ser reutilizada. O Ansible fixa o digest OCI confirmado; revalidar o registry antes de um novo release.

## Validacao

Validados localmente: BuildKit `--check` sem warnings; build `linux/amd64`; `scripts/smoke-test.sh` (bootstrap PostgreSQL, file locking Redis, health e persistencia); inspecao de usuario/entrypoint/CMD/labels/porta/volume/health check; Trivy `linux/amd64` sem CRITICAL corrigivel. O relatorio apontou 19 vulnerabilidades HIGH com correcao disponivel na imagem upstream; nenhuma foi ocultada ou ignorada. Evidencia local: `containers/artifacts/security-local/trivy-nextcloud-35.0.1-r1.json`. Ainda executar `git check-ignore`, gerar SBOM/proveniencia na release e confirmar novamente a base antes de publicar.

## Publicacao

Publicacoes futuras devem usar somente o workflow oficial, apos autorizacao explicita, com contexto `nextcloud`, imagem `nextcloud`, nova tag imutavel, Dockerfile `Dockerfile` e plataforma `linux/amd64`. A publicacao atual confirmou o digest indicado em Referencia da imagem; registre o digest de cada novo manifest no inventario Ansible depois de confirmar o resultado remoto. Nao reutilize a tag para conteudo diferente.

## Operacao

- **Backup:** maintenance mode, dump consistente do PostgreSQL, snapshot ZFS apos o dump e backup coerente de `/var/www/html`; testar restore conjunto antes de declarar recuperacao.
- **Upgrade:** backup verificavel, checar matriz de upgrade, avancar uma major por vez e manter digest anterior para rollback.
- **Rollback:** so restaurar app, banco e arquivos para o mesmo ponto consistente; nao reutilizar um banco ja migrado com binario antigo sem plano de recuperacao.
- **Remocao:** exigir autorizacao e tag explicitamente identificada; preservar backup ate validar a restauracao.

## Troubleshooting

| Sintoma | Causa provavel | Verificacao | Correcao |
| --- | --- | --- | --- |
| Health `unhealthy` no bootstrap | Apache ainda inicializando ou banco indisponivel | Logs do container e `occ status` | Verificar DB/rede e aguardar o start period; nao publicar a porta direta |
| Falha de permissao no volume | Ownership nao corresponde ao contrato upstream | UID/GID do `www-data` e logs do entrypoint | Corrigir ownership pelo procedimento aprovado depois de medir a imagem |
| Loop de redirecionamento ou URL HTTP | Proxy/trusted domains/overwrite divergentes | `occ config:list system` sem `--private` | Ajustar dominio, trusted proxy e protocolo na automacao |
| Redis indisponivel | Autenticacao, dbindex ou capacidade incorretos | Logs e `occ` sem imprimir credenciais | Validar senha e dbindex; nao reiniciar Redis compartilhado fora da janela |

## Limitacoes conhecidas

- O release e o digest upstream foram consultados em 2026-09-28; confirmar novamente antes de publicar.
- Trivy encontrou 19 vulnerabilidades HIGH corrigiveis herdadas da imagem upstream; zero CRITICAL corrigiveis. Reavaliar a release upstream e o scan antes de publicar.
- A disponibilidade real de `pve_pool`, espaco livre, regras de rede, PostgreSQL, Redis, DNS, certificados e recursos do TrueNAS nao foi aferida.
- SBOM/proveniencia da release e interoperabilidade remota permanecem pendentes; build, smoke, Trivy e manifest publicado foram aprovados.
- O uso de Redis e PostgreSQL externos exige preflight e credenciais reais provisionadas localmente em Vault.

## Licencas e fontes

| Componente | Versao | Licenca | Fonte |
| --- | --- | --- | --- |
| Conteudo original deste repositorio | Atual | MIT | `https://github.com/lzocateli/containers` |
| Nextcloud Community Docker image | 35.0.1 | AGPL-3.0 (confirmar avisos distribuidos) | `https://github.com/nextcloud/docker` |
| PHP/Apache base upstream | Conforme imagem 35.0.1 | Licencas dos componentes | `https://hub.docker.com/_/nextcloud` |

O badge MIT descreve somente o conteudo original deste repositorio. A imagem inclui componentes de terceiros que permanecem sujeitos aos termos e avisos de suas fontes. Consulte a [politica de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md), preserve as atribuicoes upstream e verifique tambem os avisos distribuidos dentro da imagem.

## Historico de alteracoes

- 35.0.1-r1: imagem wrapper publicada para `linux/amd64`, com base oficial por digest e health check local.
