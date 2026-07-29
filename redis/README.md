<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# Valkey

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fredis-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-9.1.1-2E7D32)
![Base](https://img.shields.io/badge/base-valkey%2Fvalkey%3A9.1.1-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Imagem de Valkey 9.1.1 compatível com clientes RESP2 e RESP3, com persistência AOF e RDB. Ela preserva o nome público `lzocateli/redis`, mas não garante compatibilidade dos arquivos persistidos por Redis Community Edition 7.4 ou posterior.

> [!WARNING]
> A ACL incluída permite acesso irrestrito sem senha e serve somente para desenvolvimento em localhost ou em uma rede de contêineres controlada. Substitua a ACL antes de usar a imagem em produção.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/redis:9.1.1` |
| Imagem base | `valkey/valkey:9.1.1`, fixada por digest no Dockerfile |
| Plataformas | `linux/amd64` |
| Usuário padrão | `999:999` |
| Entry point | `docker-entrypoint.sh` |
| Comando | `valkey-server /usr/local/etc/valkey/valkey.conf` |
| Diretório de trabalho | `/data` |
| Porta | `6379/tcp` |
| Health check | `valkey-cli --user healthcheck --pass healthcheck ping` |
| Código-fonte | `https://github.com/lzocateli/containers/tree/main/redis` |
| Documentação | `https://github.com/lzocateli/containers/tree/main/redis` |

## Conteúdo e finalidade

### Incluído

- Valkey 9.1.1.
- Persistência AOF com `appendfsync everysec` e snapshots RDB em `900/1`, `300/10` e `60/10000` segundos/alterações.
- ACL padrão para desenvolvimento e health check com permissão exclusiva para `PING`.
- Logs no stdout e health check executado a cada 30 segundos.

### Não incluído

- TLS, Sentinel, cluster ou proxy de rede.
- ACL de produção ou secrets de aplicações.
- Ajustes de kernel do host.
- Limite `maxmemory` e política de remoção de chaves.

## Início rápido

Execute os exemplos desta seção a partir da pasta `redis/`. Crie o diretório persistente antes de iniciar o contêiner:

```bash
mkdir -p data/valkey
sudo chown 999:999 data/valkey
docker run --name valkey \
  --detach \
  --publish 127.0.0.1:6379:6379 \
  --mount type=bind,src="$(pwd)/data/valkey",dst=/data \
  lzocateli/redis:9.1.1
docker exec valkey valkey-cli ping
```

Com Podman:

```bash
mkdir -p data/valkey
podman unshare chown 999:999 data/valkey
podman run --name valkey \
  --detach \
  --publish 127.0.0.1:6379:6379 \
  --volume "$(pwd)/data/valkey:/data:Z" \
  lzocateli/redis:9.1.1
podman exec valkey valkey-cli ping
```

O usuário `default` da ACL incluída não exige senha e aceita todos os comandos, chaves e canais. O modo protegido fica desativado para permitir clientes em outros contêineres; nunca publique a porta em uma interface externa sem substituir a ACL.

## Docker Compose

O arquivo `compose.yaml` inicia Valkey e P3X Redis UI em uma rede dedicada. Ele não publica a porta 6379 no host e publica a GUI somente em `127.0.0.1:7843`.

```bash
mkdir -p data/valkey settings/redis-gui
sudo chown 999:999 data/valkey
sudo chown 10001:0 settings/redis-gui
docker compose up -d
```

Na GUI, conecte ao host `valkey`, porta `6379`, sem TLS. Para Podman, use `podman compose up -d` com um provedor Compose instalado.

## Configuração

### Variáveis de ambiente

A imagem não adiciona variáveis de ambiente de configuração. O servidor lê `/usr/local/etc/valkey/valkey.conf`.

As configurações relevantes são `bind * -::*`, `protected-mode no`, AOF e RDB habilitados e a ACL externa em `/usr/local/etc/valkey/users.acl`. Como `protected-mode` está desativado, segurança de rede e autenticação são obrigatórias fora do ambiente de desenvolvimento.

### Parâmetros de `valkey.conf`

| Parâmetro | Valor | Efeito |
| --- | --- | --- |
| `bind` | `* -::*` | Escuta em todas as interfaces IPv4 e IPv6 disponíveis. O prefixo `-` faz o servidor continuar iniciando se o endereço IPv6 não estiver disponível; ele não restringe a interface. |
| `protected-mode` | `no` | Desativa a proteção que limitaria clientes remotos quando não há senha. É necessário para conexões entre contêineres, mas exige isolamento de rede e ACL segura em produção. |
| `port` | `6379` | Define a porta TCP sem TLS usada por clientes RESP2 e RESP3. |
| `loglevel` | `notice` | Registra eventos operacionais com verbosidade moderada, adequada ao uso normal. |
| `logfile` | `""` | Envia logs para stdout, permitindo coleta por Docker ou Podman. |
| `dir` | `/data` | Define o diretório de trabalho onde Valkey grava AOF e RDB. |
| `aclfile` | `/usr/local/etc/valkey/users.acl` | Carrega usuários e permissões de um arquivo ACL externo. Não combine esse modo com declarações `user` dentro de `valkey.conf`. |
| `appendonly` | `yes` | Habilita AOF: cada operação de escrita é registrada para reconstruir os dados no reinício. |
| `appendfsync` | `everysec` | Solicita `fsync` do AOF aproximadamente uma vez por segundo. Em uma falha abrupta, até cerca de um segundo de escritas pode ser perdido. |
| `save` | `900 1` | Cria snapshot RDB após 900 segundos se ocorreu pelo menos uma alteração. |
| `save` | `300 10` | Cria snapshot RDB após 300 segundos se ocorreram pelo menos dez alterações. |
| `save` | `60 10000` | Cria snapshot RDB após 60 segundos se ocorreram pelo menos dez mil alterações. |

As três diretivas `save` são alternativas avaliadas continuamente; basta uma condição ser atendida para iniciar um snapshot. Quando AOF e RDB existem no reinício, Valkey carrega o AOF por representar o estado mais completo.

### Portas

| Porta | Protocolo | Exposição recomendada | Finalidade |
| --- | --- | --- | --- |
| `6379/tcp` | RESP | Rede interna confiável ou localhost | Clientes compatíveis com Redis/Valkey. |

### Persistência e mounts

| Caminho no contêiner | Modo | Conteúdo | Backup necessário |
| --- | --- | --- | --- |
| `/data` | `rw` | AOF multiparte, manifesto AOF e snapshots RDB | Sim |
| `/usr/local/etc/valkey/users.acl` | `ro` | ACL substituta para produção | Sim |
| `/usr/local/etc/valkey/valkey.conf` | `ro` | Configuração substituta opcional | Sim |

Em Linux, o bind mount de `/data` deve permitir escrita pelo UID/GID `999:999`. A configuração e a ACL embarcadas pertencem a root e são somente leitura. Não monte `/tmp` nem arquivo de log; logs vão para stdout e parâmetros de kernel são configurados no host.

### ACL e secrets

#### Diferença entre os arquivos ACL

| Arquivo | Origem e finalidade | Entra na imagem | Deve conter secret |
| --- | --- | --- | --- |
| `users.acl` | Arquivo versionado, copiado pelo Dockerfile. Mantém o ambiente de desenvolvimento acessível sem senha e fornece o usuário restrito do health check. | Sim | Não |
| `users.acl.local` | Override criado localmente pelo operador para produção. Substitui `users.acl` por bind mount e deve desativar o usuário padrão sem senha. | Não | Somente hashes, nunca senha em texto claro |

O repositório contém apenas `users.acl`. `users.acl.local` é criado pelo exemplo abaixo quando necessário e é ignorado por `*.acl.local` no `.gitignore` e no `.dockerignore`. Se esse arquivo aparecer na pasta local, ele foi gerado para configuração ou validação e não deve ser commitado.

O `users.acl` distribuído contém:

```text
user default on nopass ~* &* +@all
user healthcheck on nopass -@all +ping
```

| Regra | Explicação |
| --- | --- |
| `user <nome>` | Inicia a definição do usuário ACL indicado. |
| `default` | Usuário associado automaticamente a novas conexões quando está ativo com `nopass`. |
| `healthcheck` | Usuário usado exclusivamente pela prova de saúde da imagem. |
| `on` | Habilita autenticação e uso do usuário. |
| `off` | Impede novas autenticações com o usuário; conexões já autenticadas não são encerradas automaticamente. |
| `nopass` | Remove a exigência de senha e faz qualquer senha ser aceita. No usuário `default`, também autentica novas conexões automaticamente. |
| `~*` | Permite acesso a todas as chaves. |
| `&*` | Permite acesso a todos os canais Pub/Sub. |
| `+@all` | Permite todos os comandos atuais e futuros, inclusive comandos de módulos. |
| `-@all` | Remove permissão para todos os comandos. |
| `+ping` | Readiciona somente o comando `PING`; como as regras são processadas da esquerda para a direita, vem depois de `-@all`. |
| `#<hash>` | Adiciona um hash SHA-256 hexadecimal de 64 caracteres como credencial, sem armazenar a senha em texto claro. |

Assim, `default` é irrestrito e inseguro para produção. `healthcheck` não acessa chaves ou canais e só pode executar `PING`.

Para produção, gere um segredo e grave somente o hash SHA-256 em um arquivo local ignorado pelo Git:

```bash
VALKEY_PASSWORD="$(docker exec valkey valkey-cli ACL GENPASS)"
VALKEY_PASSWORD_HASH="$(printf '%s' "$VALKEY_PASSWORD" | sha256sum | cut -d ' ' -f 1)"
cat > users.acl.local <<EOF
user default off
user healthcheck on nopass -@all +ping
user app on #${VALKEY_PASSWORD_HASH} ~* &* +@all
EOF
```

No `users.acl.local` do exemplo, `default off` bloqueia novas conexões pelo usuário padrão; `healthcheck` é preservado para a prova de saúde; e `app` exige a senha correspondente ao hash. As regras `~*`, `&*` e `+@all` ainda concedem acesso total ao usuário `app`.

O exemplo concede acesso total ao usuário `app` apenas para demonstrar a sintaxe. Em produção, substitua `~*`, `&*` e `+@all` pelos padrões de chave, canais e categorias estritamente necessários.

Recrie o contêiner montando `users.acl.local` como somente leitura:

```bash
docker rm --force valkey

docker run --name valkey \
  --detach \
  --publish 127.0.0.1:6379:6379 \
  --mount type=bind,src="$(pwd)/data/valkey",dst=/data \
  --mount type=bind,src="$(pwd)/users.acl.local",dst=/usr/local/etc/valkey/users.acl,readonly \
  lzocateli/redis:9.1.1
```

Configure o cliente com usuário `app` e o valor de `VALKEY_PASSWORD`. Armazene o segredo em um secret manager; não o grave em Compose, Dockerfile, imagem, log ou repositório. Preserve o usuário `healthcheck` para manter a prova de saúde.

O usuário `healthcheck` usa `nopass`, portanto o argumento `--pass healthcheck` não representa um secret: qualquer senha seria aceita para esse usuário. Sua proteção está na permissão exclusiva para `PING`.

ACL não cifra a conexão. Use TLS ou uma rede privada quando houver risco de interceptação.

## Inicialização e ciclo de vida

O contêiner inicia diretamente como UID/GID `999:999`. O entrypoint upstream não consegue corrigir bind mounts pertencentes a outro usuário, portanto `/data` deve estar gravável antes da inicialização. `SIGTERM` aciona o encerramento normal. O health check começa após 10 segundos, roda a cada 30 segundos, espera até 5 segundos e falha após três tentativas.

## Segurança

- Nunca exponha `6379` diretamente à internet.
- Substitua a ACL de desenvolvimento em produção e conceda somente comandos e padrões de chave necessários.
- Mantenha `/data` e a ACL fora do Git e do contexto de build.
- Restrinja acesso aos bind mounts no host.
- Não adicione `--privileged`; ajuste `vm.overcommit_memory` no host quando a carga exigir.
- Defina `maxmemory` e uma política de remoção coerentes com a carga e o limite do contêiner.
- Avalie Transparent Huge Pages e memória adicional para forks de RDB e reescritas AOF no host.

## Build local

Execute o build a partir da raiz do repositório:

```bash
docker build --pull --tag lzocateli/redis:9.1.1 redis
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `9.1.1` | Imutável | Protocolo Redis OSS; Valkey 9.1 | Produção após configurar ACL |

Esta versão substitui Redis 7.4 por Valkey 9.1.1. Valkey mantém compatibilidade de protocolo e de arquivos com Redis OSS 7.2 e versões anteriores. Entretanto, arquivos RDB e AOF produzidos por Redis Community Edition 7.4 ou posterior não são compatíveis com Valkey.

Não aponte esta imagem para o diretório `/data` usado pelo Redis 7.4. Migre por exportação lógica ou ferramenta compatível, valide a quantidade e o conteúdo das chaves e mantenha o backup original até concluir a verificação. A troca também altera implementação, licença, executáveis, caminho de configuração, usuário efetivo, ACL e health check.

## Validação

Antes da publicação, confirme BuildKit, build `linux/amd64`, `PING`, leitura e escrita, health check, UID do PID principal, persistência após recriação, encerramento normal, labels OCI, scan de vulnerabilidades, SBOM e proveniência.

## Publicação

Use **Actions > Publicar imagem de container > Run workflow** com:

- `context_path`: `redis`;
- `image_name`: `redis`;
- `image_tag`: `9.1.1`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64`.

## Operação

Esta imagem usa AOF e RDB simultaneamente; em reinícios, o AOF é preferido por conter o estado mais completo. Não copie arbitrariamente o AOF durante uma reescrita. Antes do backup, confirme em `INFO persistence` que `aof_rewrite_in_progress` é `0` e siga o procedimento oficial para preservar todos os arquivos do AOF multiparte. Mantenha também snapshots RDB e a ACL fora do host principal.

Teste a restauração em outro diretório antes de considerar o backup válido. Para atualizar, use uma nova tag imutável. Para rollback, restaure somente dados compatíveis com a versão anterior. Consulte logs com `docker logs valkey`.

## Troubleshooting

| Sintoma | Causa provável | Verificação | Correção |
| --- | --- | --- | --- |
| `NOAUTH` | ACL de produção ativa | Verifique usuário configurado no cliente | Informe usuário e secret corretos. |
| Health `unhealthy` | Usuário `healthcheck` removido | `docker inspect valkey` | Restaure `user healthcheck on nopass -@all +ping`. |
| Erro de escrita em `/data` | Permissão do bind mount | `docker logs valkey` | Conceda escrita ao UID `999`. |
| Aviso de overcommit | Kernel do host | Consulte os logs | Configure `vm.overcommit_memory=1` no host. |
| Dados de Redis 7.4 não carregam | Formato RDB/AOF incompatível | Consulte os logs de startup | Restaure o backup antigo e faça migração lógica. |

## Limitações conhecidas

- Somente `linux/amd64` está declarado e validado neste repositório.
- A ACL incluída é insegura para produção.
- `protected-mode` está desativado para permitir clientes em outros contêineres.
- A imagem não fornece TLS nem alta disponibilidade.
- Não há limite de memória predefinido.

## Licenças e fontes

| Componente | Versão | Licença | Fonte |
| --- | --- | --- | --- |
| Conteúdo original deste repositório | Atual | MIT | `https://github.com/lzocateli/containers` |
| Valkey | 9.1.1 | BSD-3-Clause | `https://github.com/valkey-io/valkey` |
| Imagem base Valkey | 9.1.1 | BSD-3-Clause | `https://hub.docker.com/r/valkey/valkey` |

O badge MIT descreve somente o conteúdo original deste repositório. Componentes de terceiros permanecem sujeitos aos termos e avisos upstream. Consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md).

## Referências

- Releases e suporte: `https://valkey.io/topics/releases/`
- ACL: `https://valkey.io/topics/acl/`
- Persistência: `https://valkey.io/topics/persistence/`
- Migração do Redis: `https://valkey.io/topics/migration/`
- Administração: `https://valkey.io/topics/admin/`

## Histórico de alterações

- `9.1.1`: substitui Redis 7.4 por Valkey 9.1.1, adiciona ACL externa, AOF e RDB, health check restrito e integração opcional com P3X Redis UI.
