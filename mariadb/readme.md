<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# lzocateli/mariadb

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fmariadb-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-11.4.11--ubi9-2E7D32)
![Base](https://img.shields.io/badge/base-mariadb%3A11.4.11--ubi9-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64%2Clinux%2Farm64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Imagem MariaDB 11.4.11 para uso em bancos de dados persistentes em ambientes locais, desenvolvimento e homelab. A imagem usa a variante oficial `mariadb:11.4.11-ubi9`, mantendo o contrato de runtime e o diretório de dados compatíveis com bind mounts e volumes nomeados.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/mariadb:11.4.11-ubi9` |
| Imagem base | `mariadb:11.4.11-ubi9` |
| Plataformas | `linux/amd64`, `linux/arm64` |
| Usuário padrão | `mysql` |
| Entry point | `docker-entrypoint.sh` (script oficial do MariaDB) |
| Diretório de trabalho | `/var/lib/mysql` |
| Código-fonte | `https://github.com/lzocateli/containers/tree/main/mariadb` |
| Documentação | `https://github.com/lzocateli/containers/tree/main/mariadb` |

## Conteúdo e finalidade

### Incluído

- MariaDB 11.4.11 em imagem baseada em UBI 9.
- Variáveis de inicialização do container oficial do MariaDB.
- Suporte a persistência de dados em `/var/lib/mysql`.
- Porta TCP 3306 exposta para uso no host ou em redes internas.

### Não incluído

- Gerenciamento de backup automatizado.
- Configuração de rede pública, TLS ou auth provider externo.
- Banco já carregado com dados; o armazenamento deve ser fornecido pelo consumidor.

## Início rápido

```bash
docker pull lzocateli/mariadb:11.4.11-ubi9
docker run --rm --name mariadb \
  --publish 127.0.0.1:3306:3306 \
  --env MARIADB_DATABASE=appdb \
  --env MARIADB_USER=appuser \
  --env MARIADB_PASSWORD=change-me \
  --env MARIADB_ROOT_PASSWORD=change-me \
  --volume /srv/mariadb:/var/lib/mysql \
  lzocateli/mariadb:11.4.11-ubi9
```

## Docker Compose

```yaml
services:
  mariadb:
    image: lzocateli/mariadb:11.4.11-ubi9
    restart: unless-stopped
    ports:
      - "127.0.0.1:3306:3306"
    environment:
      MARIADB_DATABASE: appdb
      MARIADB_USER: appuser
      MARIADB_PASSWORD: change-me
      MARIADB_ROOT_PASSWORD: change-me
    volumes:
      - /srv/mariadb:/var/lib/mysql
```

## Configuração

### Variáveis de ambiente

| Variável | Obrigatória | Secreta | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| `MARIADB_ROOT_PASSWORD` | Sim, quando `MARIADB_ALLOW_EMPTY_ROOT_PASSWORD` não for usado | Sim | Nenhum | Senha da conta `root` do MariaDB. |
| `MARIADB_DATABASE` | Não | Não | Nenhum | Cria um banco de dados no primeiro boot. |
| `MARIADB_USER` | Não | Não | Nenhum | Cria um usuário específico para o banco recém-criado. |
| `MARIADB_PASSWORD` | Sim, quando `MARIADB_USER` estiver definido | Sim | Nenhum | Senha do usuário criado automaticamente. |
| `MARIADB_ALLOW_EMPTY_ROOT_PASSWORD` | Não | Não | `0` | Permite root sem senha apenas em ambientes controlados. |
| `MARIADB_RANDOM_ROOT_PASSWORD` | Não | Não | `0` | Gera senha aleatória para `root` na inicialização. |

### Portas

| Porta | Protocolo | Exposição recomendada | Finalidade |
| --- | --- | --- | --- |
| `3306/tcp` | TCP | `127.0.0.1:3306` ou rede interna | Conexão do cliente MariaDB. |

### Persistência e mounts

| Caminho no contêiner | Modo | Conteúdo | Backup necessário |
| --- | --- | --- | --- |
| `/var/lib/mysql` | `rw` | Dados do banco, logs e arquivos de inicialização | Sim |

Use bind mount ou volume nomeado em `/var/lib/mysql` para preservar dados entre recriações do contêiner. O diretório deve ser de propriedade adequada e acessível pelo processo do MariaDB, com permissões compatíveis com o usuário `mysql`.

### Secrets

Secrets e senhas não devem ser gravadas no Dockerfile, em `docker-compose.yml` versionado nem em arquivos de build. Use variáveis de ambiente do runtime, arquivos secret no orchestrator ou `podman secret`/`docker secret` quando disponível.

## Inicialização e ciclo de vida

A imagem usa o entrypoint oficial do MariaDB e executa a inicialização do banco no primeiro boot. Quando o diretório `/var/lib/mysql` está vazio, o contêiner cria o banco definido por `MARIADB_DATABASE`, cria o usuário indicado por `MARIADB_USER` e configura as credenciais informadas. Reinicializações subsequentes preservam o estado dos dados persistidos. O processo principal do contêiner é o `mysqld` e ele responde a sinais de término do PID 1 do container.

## Segurança

A variante Ubuntu e a variante UBI 9 `mariadb:11.4.11-ubi9` publicam `/usr/local/bin/gosu` compilado com Go `v1.24.6`, que falha no gate CRITICAL corrigivel do Trivy por causa da `CVE-2025-68121`. O Dockerfile recompila o gosu oficial `1.19` com Go `1.25.7` e o copia para a imagem final, mantendo o entrypoint MariaDB oficial.

Quando uma imagem oficial MariaDB futura trouxer o gosu compilado com uma versao corrigida da stdlib, testar a remocao do estagio `gosu-builder` e do `COPY --from` nas variantes Ubuntu e UBI 9. A imagem oficial deve ser preferida novamente se o resultado permanecer verde e o smoke test confirmar o mesmo contrato.

- O contêiner deve ser executado com uma senha para `root` ou com política controlada de senha aleatória.
- O uso de `MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=1` deve ser evitado em produção.
- Preserve o diretório `/var/lib/mysql` em um volume persistente e restrinja acesso de rede ao banco.
- Atualize a imagem base regularmente e acompanhe vulnerabilidades do MariaDB e do sistema base.
- Evite expor a porta 3306 para a Internet; prefira `127.0.0.1` ou redes internas.

## Build local

```bash
docker build \
  --pull \
  --tag lzocateli/mariadb:11.4.11-ubi9 \
  .
```

Para múltiplas plataformas:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag lzocateli/mariadb:11.4.11-ubi9 \
  .
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `11.4.11-ubi9` | Imutável | MariaDB 11.4.11 em UBI 9 | Produção e ambientes estáveis |

A política de release desta imagem é manter tags imutáveis e documentadas. Alterações de configuração do runtime ou necessidade de compatibilidade exigem revisão do README e do contrato da imagem.

## Validação

Antes da publicação, confirme:

- `.gitignore` e `.dockerignore` presentes e adaptados à imagem;
- `.env`, secrets, dados persistentes e backups fora do Git e do contexto Docker;
- `.git` excluído do contexto Docker;
- análise do Dockerfile com BuildKit;
- build sem cache quando necessário;
- smoke test do processo principal;
- health check;
- execução sem root, quando suportada;
- persistência após recriação;
- plataformas declaradas;
- inspeção de vulnerabilidades;
- geração de SBOM e proveniência;
- labels OCI e tag final.

## Publicação

Use **Actions > Publicar imagem de container > Run workflow** e informe:

- `context_path`: `mariadb`;
- `image_name`: `mariadb`;
  - `image_tag`: `11.4.11-ubi9`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64,linux/arm64`.

O workflow publica no Docker Hub e pode sincronizar este README como descrição completa.

## Operação

- Monte `/var/lib/mysql` em volume persistente ou bind mount.
- Acesse o banco localmente em `127.0.0.1:3306` ou via rede interna do host.
- Para backups, faça dump do banco com `mysqldump` ou snapshot do volume persistente.
- Verifique logs do contêiner ao iniciar ou reiniciar para confirmar que o processo `mysqld` iniciou sem erros.

## Troubleshooting

| Sintoma | Causa provável | Verificação | Correção |
| --- | --- | --- | --- |
| Falha ao iniciar o banco | Permissão de volume ruim ou dados corrompidos | Verifique logs do container e permissões em `/var/lib/mysql` | Ajuste ownership e remova apenas diretórios de dados corrompidos após backup |
| Erro de autenticação do usuário | Senha errada ou usuário inexistente | Conecte com `mysql -u appuser -p` | Revalidar variáveis `MARIADB_USER` e `MARIADB_PASSWORD` |
| Container reinicia em loop | Problema de configuração do banco ou volume montado incorretamente | Revise `docker logs` | Corrija o caminho do volume e a inicialização do banco |

## Limitações conhecidas

- A imagem não inclui painel de gerenciamento, backup automático nem autenticação externa.
- O volume persistente deve ser gerenciado por quem opera a instância.

## Licenças e fontes

| Componente | Versão | Licença | Fonte |
| --- | --- | --- | --- |
| Conteúdo original deste repositório | Atual | MIT | `https://github.com/lzocateli/containers` |
| Imagem base | `mariadb:11.4.11-ubi9` | MariaDB licensing + UBI image terms | `https://hub.docker.com/_/mariadb` |

O badge MIT descreve somente o conteúdo original deste repositório. A imagem inclui componentes de terceiros que permanecem sujeitos aos termos e avisos de suas fontes. Consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md), preserve as atribuições upstream e verifique também os avisos distribuídos dentro da imagem.

## Histórico de alterações

- 2026-08-19: migração para a variante oficial MariaDB UBI 9 após a falha da variante Ubuntu no gate CRITICAL do Trivy; mantido o plano de reavaliar a variante Ubuntu quando o `gosu` upstream for atualizado.
