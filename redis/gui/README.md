<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# P3X Redis UI

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fredis--gui-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-2026.4.3014--r1-2E7D32)
![Base](https://img.shields.io/badge/base-patrikx3%2Fp3x--redis--ui%3A2026.4.3014-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Interface web P3X Redis UI para administrar Valkey e outros servidores compatíveis com o protocolo Redis. A imagem derivada fixa a versão upstream e executa o processo sem root.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/redis-gui:2026.4.3014-r1` |
| Imagem base | `patrikx3/p3x-redis-ui:2026.4.3014`, fixada por digest no Dockerfile |
| Plataformas | `linux/amd64` |
| Usuário padrão | `10001:0` |
| Entry point | `docker-entrypoint.sh` |
| Comando | `p3x-redis` |
| Diretório persistente | `/settings` |
| Código-fonte | `https://github.com/lzocateli/containers/tree/main/redis/gui` |
| Documentação | `https://github.com/lzocateli/containers/tree/main/redis/gui` |

## Conteúdo e finalidade

### Incluído

- P3X Redis UI 2026.4.3014.
- Diretório `/settings` preparado para UID `10001`.
- Health check HTTP em `/health`.

### Não incluído

- Servidor Valkey/Redis.
- Proxy reverso, TLS, autenticação HTTP ou conexão pré-configurada.

## Início rápido

```bash
mkdir -p settings/redis-gui
sudo chown 10001:0 settings/redis-gui
docker run --name redis-gui \
  --detach \
  --publish 127.0.0.1:7843:7843 \
  --mount type=bind,src="$(pwd)/settings/redis-gui",dst=/settings \
  lzocateli/redis-gui:2026.4.3014-r1
```

Acesse `http://127.0.0.1:7843`. Com Podman, prepare a propriedade com `podman unshare chown 10001:0 settings/redis-gui` e use `--volume "$(pwd)/settings/redis-gui:/settings:Z"` em hosts com SELinux.

## Docker Compose

O Compose integrado está em `redis/compose.yaml` e inicia a GUI junto ao Valkey:

```bash
mkdir -p data/valkey settings/redis-gui
sudo chown 999:999 data/valkey
sudo chown 10001:0 settings/redis-gui
docker compose -f redis/compose.yaml up -d
```

Cadastre a conexão com host `valkey` e porta `6379`. Informe usuário e secret quando a ACL de produção estiver ativa.

## Configuração

### Variáveis de ambiente

| Variável | Obrigatória | Secreta | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| `P3XRS_DOCKER_HOME` | Não | Não | `/settings` | Diretório persistente da configuração da GUI. |

### Portas

| Porta | Protocolo | Exposição recomendada | Finalidade |
| --- | --- | --- | --- |
| `7843/tcp` | HTTP | Localhost ou proxy reverso autenticado | Interface web e endpoint `/health`. |

### Persistência e mounts

| Caminho no contêiner | Modo | Conteúdo | Backup necessário |
| --- | --- | --- | --- |
| `/settings` | `rw` | Conexões e preferências da GUI | Sim |

O bind mount deve permitir escrita por `10001:0`. Não monte `/tmp` nem `/data`; esses caminhos pertenciam ao contrato antigo do RedisInsight.

### Secrets

Credenciais dos servidores gerenciados podem ser persistidas em `/settings`. Proteja e faça backup desse diretório como dado sensível, restrinja suas permissões no host e não o inclua no Git ou no contexto Docker.

## Inicialização e ciclo de vida

O entrypoint upstream inicia `p3x-redis` como UID `10001`. O health check consulta `http://localhost:7843/health` e espera HTTP 200. `SIGTERM` encerra o processo Node.js.

## Segurança

- Publique a porta somente em localhost ou atrás de proxy com TLS e autenticação.
- Não exponha a GUI diretamente à internet.
- Execute sem `--privileged` e preserve o usuário `10001:0`.
- Trate `/settings` como secret, pois pode conter credenciais de conexão.

## Build local

```bash
docker build --pull --tag lzocateli/redis-gui:2026.4.3014-r1 redis/gui
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `2026.4.3014-r1` | Imutável | P3X Redis UI 2026.4.3014 + patch npm 11.18.0 (tar 7.5.19) | Produção atrás de proxy protegido |
| `2026.4.3014` | Imutável | P3X Redis UI 2026.4.3014 | Mantida para compatibilidade histórica |

Esta versão substitui RedisInsight 2.54 por P3X Redis UI. A mudança é incompatível quanto à aplicação, porta, persistência e formato das configurações. RedisInsight usa SSPLv1; P3X Redis UI usa MIT, compatível com a política deste repositório. Recrie as conexões manualmente e não reutilize o diretório `/data` antigo.

## Validação

Antes da publicação, confirme BuildKit, build `linux/amd64`, HTTP 200 em `/health`, UID `10001`, escrita e persistência em `/settings`, encerramento normal, labels OCI, scan de vulnerabilidades, SBOM e proveniência.

## Publicação

Use **Actions > Publicar imagem de container > Run workflow** com:

- `context_path`: `redis/gui`;
- `image_name`: `redis-gui`;
- `image_tag`: `2026.4.3014-r1`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64`.

## Operação

Faça backup protegido de `/settings`. Para atualizar, use nova tag imutável, preserve o backup e valide as conexões. Para rollback, restaure o diretório compatível com a versão anterior. Consulte logs com `docker logs redis-gui`.

## Troubleshooting

| Sintoma | Causa provável | Verificação | Correção |
| --- | --- | --- | --- |
| GUI não abre | Porta não publicada ou processo iniciando | `docker logs redis-gui` | Publique `127.0.0.1:7843:7843` e aguarde o health. |
| Configuração não persiste | Permissão no bind mount | `docker inspect redis-gui` | Conceda escrita ao UID `10001`. |
| Valkey não conecta | Host incorreto ou rede ausente | Verifique a rede do contêiner | No Compose integrado, use host `valkey` e porta `6379`. |

## Limitações conhecidas

- Somente `linux/amd64` está declarado e validado neste repositório.
- A imagem não inclui autenticação para a interface web.
- Configurações do RedisInsight não são migradas automaticamente.

## Licenças e fontes

| Componente | Versão | Licença | Fonte |
| --- | --- | --- | --- |
| Conteúdo original deste repositório | Atual | MIT | `https://github.com/lzocateli/containers` |
| P3X Redis UI | 2026.4.3014 | MIT | `https://github.com/patrikx3/redis-ui` |
| Imagem base P3X Redis UI | 2026.4.3014 | Licenças dos componentes upstream | `https://hub.docker.com/r/patrikx3/p3x-redis-ui` |

O badge MIT descreve somente o conteúdo original deste repositório. O código do P3X Redis UI é MIT, mas a imagem base também distribui sistema operacional, runtime e dependências sujeitos às respectivas licenças e aos avisos upstream. Consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md).

## Histórico de alterações

- `2026.4.3014-r1`: mantém P3X Redis UI 2026.4.3014 e aplica patch de segurança npm 11.18.0 (tar 7.5.19) para mitigar o CVE-2026-59873.
- `2026.4.3014`: substitui RedisInsight por P3X Redis UI, muda a porta para 7843, persiste configuração em `/settings` e executa como UID `10001`.
