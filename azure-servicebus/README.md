<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# Azure Service Bus Emulator

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fazure--servicebus-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-servicebus--emulator--digest--2026--09-2E7D32)
![Base](https://img.shields.io/badge/base-mcr.microsoft.com%2Fazure--messaging%2Fservicebus--emulator-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Emulador do Azure Service Bus para desenvolvimento local, pinado por digest e com uma topologia mínima de fallback. O stack inclui o emulador e o SQL Edge usado como backing store.

## Referencia da imagem

| Item                  | Valor                                                                     |
| --------------------- | ------------------------------------------------------------------------- |
| Imagem                | `lzocateli/azure-servicebus:servicebus-emulator-digest-2026-09`           |
| Imagem base           | `mcr.microsoft.com/azure-messaging/servicebus-emulator` fixada por digest |
| Plataformas           | `linux/amd64`                                                             |
| Usuario padrao        | Conforme a imagem oficial Microsoft                                       |
| Entry point           | Conforme a imagem oficial Microsoft                                       |
| Comando padrao        | Conforme a imagem oficial Microsoft                                       |
| Arquivo de composicao | `docker-compose.yml`                                                      |
| Codigo-fonte          | `https://github.com/lzocateli/containers/tree/main/azure-servicebus`      |
| Documentacao          | `https://github.com/lzocateli/containers/tree/main/azure-servicebus`      |

## Conteudo e finalidade

### Incluido

- Emulador oficial do Azure Service Bus fixado por digest;
- `Config.default.json` copiado para a configuracao de fallback;
- scripts PowerShell para subir, parar e testar o stack;
- projeto .NET usado pelo smoke test de mensagens.

### Nao incluido

- Uso em producao ou garantia de compatibilidade com o Azure Service Bus real;
- credenciais persistentes ou senha SQL versionada;
- acesso publico as portas do emulador.

O emulador e distribuido pela Microsoft para desenvolvimento local. Leia os termos upstream antes do primeiro uso e aceite a EULA somente no ambiente apropriado.

## Inicio rapido

Pre-requisitos: Docker Desktop com containers Linux, Docker Compose v2 e PowerShell 7.

```powershell
docker pull lzocateli/azure-servicebus:servicebus-emulator-digest-2026-09
./sb-up.ps1 -Image lzocateli/azure-servicebus:servicebus-emulator-digest-2026-09 -AcceptEula
```

Para usar a imagem Microsoft diretamente durante desenvolvimento local:

```powershell
./sb-up.ps1 -UseMcr -AcceptEula
```

---

## Docker Compose

| Peça                  | Papel                                                                                                             |
| --------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `Dockerfile`          | Fixa o emulador por digest; embute uma topologia mínima de fallback.                                              |
| `Config.default.json` | Uma fila e um tópico/assinatura — usados apenas quando nenhum config é montado via bind mount.                    |
| `docker-compose.yml`  | Emulador + SQL (backing store), totalmente parametrizado, portas em `127.0.0.1`.                                  |
| `sb-up.ps1`           | Sobe o stack: valida EULA/senha/config, `docker compose up -d`, aguarda `/health`, imprime as connection strings. |
| `sb-down.ps1`         | Derruba o stack (`-Fresh` remove volumes, forçando reconstrução limpa da topologia).                              |
| `sb-smoke.ps1`        | Envia e recebe uma mensagem de teste numa fila ou tópico/assinatura informados pelo chamador.                     |
| `tools/sb-smoke/`     | Console .NET usado por `sb-smoke.ps1` — não conhece nenhuma topologia específica de aplicação.                    |

O arquivo `docker-compose.yml` sobe o emulador e o SQL Edge. As portas sao publicadas somente em `127.0.0.1` por padrao. Para executar dois stacks lado a lado, use `./sb-up.ps1 -UseMcr -ProjectName sb-scratch -AmqpPort 5673 -HttpPort 5301`.

---

## Configuracao

### Variaveis e parametros

| Item                      | Obrigatorio | Secreto | Padrao                        | Descricao                                             |
| ------------------------- | ----------- | ------- | ----------------------------- | ----------------------------------------------------- |
| `SB_EMULATOR_ACCEPT_EULA` | Sim         | Nao     | configurado por `-AcceptEula` | Aceite persistido no ambiente do usuario.             |
| `SB_EMULATOR_SA_PASSWORD` | Sim         | Sim     | gerado pelo script            | Senha SQL gerada e persistida no ambiente do usuario. |
| `-ConfigPath`             | Nao         | Nao     | `Config.default.json`         | Arquivo JSON montado no emulador.                     |
| `-AmqpPort`               | Nao         | Nao     | `5672`                        | Porta AMQP local.                                     |
| `-HttpPort`               | Nao         | Nao     | `5300`                        | Porta HTTP/health local.                              |
| `-ProjectName`            | Nao         | Nao     | `sb-emulator`                 | Nome do projeto Compose.                              |

### Portas

| Porta      | Protocolo | Exposicao recomendada | Finalidade                              |
| ---------- | --------- | --------------------- | --------------------------------------- |
| `5672/tcp` | AMQP      | localhost             | Envio e recebimento de mensagens.       |
| `5300/tcp` | HTTP      | localhost             | Health endpoint e plano administrativo. |

### Persistencia e mounts

| Caminho no container                           | Modo | Conteudo                      | Backup necessario            |
| ---------------------------------------------- | ---- | ----------------------------- | ---------------------------- |
| `/ServiceBus_Emulator/ConfigFiles/Config.json` | `ro` | Topologia JSON                | Versionar o arquivo seguro   |
| Volume SQL Edge do Compose                     | `rw` | Estado local do backing store | Somente se o ambiente exigir |

`sb-down.ps1 -Fresh` remove os volumes e força uma recriacao limpa da topologia.

### Secrets

A senha SQL e gerada pelo `sb-up.ps1` e armazenada somente na variavel de ambiente de usuario `SB_EMULATOR_SA_PASSWORD`. Nunca versionar a senha, gravar `.env` ou exibi-la em logs.

## Inicializacao e ciclo de vida

`sb-up.ps1` valida EULA, senha e JSON, executa `docker compose up -d`, aguarda `/health` e imprime as connection strings de desenvolvimento. `sb-down.ps1` encerra o stack; com `-Fresh`, tambem remove volumes. `sb-smoke.ps1` valida o round-trip de uma fila ou topico/assinatura.

## Rodar localmente

Use `-UseMcr` para referenciar a imagem oficial Microsoft pinada pelo mesmo digest usado no Dockerfile:

```powershell
cd c:\Projects\Cat\containers\azure-servicebus
./sb-up.ps1 -UseMcr -AcceptEula
```

Na primeira execução:

- a senha do SQL SA é gerada (24 caracteres, gerador criptográfico) e persistida na variável de
  ambiente de usuário `SB_EMULATOR_SA_PASSWORD` — nunca é gravada em disco neste repositório;
- a aceitação da licença é persistida em `SB_EMULATOR_ACCEPT_EULA`.

Execuções seguintes não precisam de `-AcceptEula` nem geram uma nova senha.

### Parar / resetar

```powershell
./sb-down.ps1                # para o stack, preserva o volume do SQL
./sb-down.ps1 -Fresh          # para e remove o volume — próximo `sb-up.ps1` recria a topologia do zero
```

### Testar o round-trip de uma mensagem

```powershell
./sb-smoke.ps1 -Topic topic.default -Subscription subscription.default
./sb-smoke.ps1 -Queue queue.default
```

### Rodar dois stacks lado a lado

```powershell
./sb-up.ps1 -UseMcr -ProjectName sb-scratch -AmqpPort 5673 -HttpPort 5301
```

---

## Build local

```powershell
$IMAGE = "lzocateli/azure-servicebus"
$TAG   = "servicebus-emulator-digest-2026-09"

docker build --platform linux/amd64 -t "$($IMAGE):$($TAG)" .
```

Sem `--build-arg` de proxy: nao ha instalacao de pacotes durante o build.

---

## Tags e compatibilidade

| Tag                                  | Mutabilidade | Compatibilidade                           | Uso recomendado       |
| ------------------------------------ | ------------ | ----------------------------------------- | --------------------- |
| `servicebus-emulator-digest-2026-09` | Imutavel     | Emulador fixado por digest, `linux/amd64` | Desenvolvimento local |

Nao ha politica para `latest`. Alteracoes no digest, topologia, portas, scripts ou contrato exigem nova tag imutavel.

## Validacao

Antes da publicacao, execute:

```powershell
docker buildx build --check --file azure-servicebus/Dockerfile azure-servicebus
docker build --pull --platform linux/amd64 --tag lzocateli/azure-servicebus:servicebus-emulator-digest-2026-09 azure-servicebus
./azure-servicebus/sb-up.ps1 -UseMcr -AcceptEula
./azure-servicebus/sb-smoke.ps1 -Queue queue.default
./azure-servicebus/sb-down.ps1 -Fresh
```

Confirme os ignores, a ausencia de secrets no contexto, os labels OCI, a plataforma, o scan de vulnerabilidades, SBOM e proveniencia.

## Publicacao

Use **Actions > Publicar imagem de container > Run workflow** com:

- `context_path`: `azure-servicebus`;
- `image_name`: `azure-servicebus`;
- `image_tag`: `servicebus-emulator-digest-2026-09`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64`.

O workflow publica no Docker Hub com SBOM e proveniencia e pode sincronizar este README.

## Seguranca

- A chave SAS do emulador (`SAS_KEY_VALUE`) é uma constante fixa e publicamente documentada pela
  Microsoft — **não é segredo** e pode ser versionada.
- A senha do SQL SA **é** segredo: nunca aparece em arquivo versionado, `docker-compose.yml`,
  `Dockerfile`, linha de comando ou saída de console (apenas o tamanho é impresso).
- Nenhum `.env` e criado; `.gitignore` protege contra um aparecer por engano.
- Portas publicadas apenas em `127.0.0.1`.

## Operacao e troubleshooting

| Sintoma                   | Causa provavel                               | Verificacao                                                 | Correcao                                         |
| ------------------------- | -------------------------------------------- | ----------------------------------------------------------- | ------------------------------------------------ |
| EULA recusada             | `-AcceptEula` nao foi usado                  | Verifique `SB_EMULATOR_ACCEPT_EULA`                         | Execute o script apos ler os termos upstream     |
| SQL nao fica saudavel     | Senha ausente ou volume inconsistente        | Consulte `docker compose logs sqledge` sem imprimir secrets | Execute `-Fresh` e suba novamente                |
| Emulator nao fica healthy | Porta ocupada ou configuracao invalida       | Valide o JSON e consulte os logs                            | Altere `-AmqpPort`/`-HttpPort` ou corrija o JSON |
| Smoke test falha          | Entidade nao existe ou stack nao esta pronto | Execute o smoke test apos `/health`                         | Use nomes presentes na configuracao montada      |

Nao ha backup de producao neste stack. Para rollback, volte a tag imutavel anterior.

## Limitacoes conhecidas

- O emulador nao representa todas as capacidades do Azure Service Bus.
- A imagem e publicada somente para `linux/amd64`.
- O smoke test exige o SDK .NET e acesso ao NuGet no primeiro restore.
- A EULA e os termos da imagem oficial Microsoft prevalecem sobre esta documentacao.

## Licencas e fontes

| Componente                          | Versao           | Licenca                   | Fonte                                                                               |
| ----------------------------------- | ---------------- | ------------------------- | ----------------------------------------------------------------------------------- |
| Conteudo original deste repositorio | Atual            | MIT                       | `https://github.com/lzocateli/containers`                                           |
| Azure Service Bus Emulator          | Digest fixado    | Termos Microsoft upstream | `https://mcr.microsoft.com/en-us/product/azure-messaging/servicebus-emulator/about` |
| Azure SQL Edge                      | Conforme Compose | Termos Microsoft upstream | `https://mcr.microsoft.com/en-us/product/azure-sql-edge/about`                      |
| Azure.Messaging.ServiceBus          | 7.20.1           | MIT                       | `https://github.com/Azure/azure-sdk-for-net`                                        |

O badge MIT descreve somente o conteudo original deste repositorio. Componentes de terceiros permanecem sujeitos aos termos de suas fontes. Consulte a [politica de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md).

## Historico de alteracoes

- `servicebus-emulator-digest-2026-09`: documentacao alinhada ao padrao do projeto e ao Docker Hub.

## 8. Validação e publicação

Valide o Dockerfile com BuildKit e execute `sb-up.ps1 -UseMcr -AcceptEula` seguido de um smoke test
antes da publicação. Use `context_path: azure-servicebus`, `image_name: azure-servicebus`,
`dockerfile: Dockerfile`, plataforma `linux/amd64` e uma tag imutável.

O badge MIT cobre somente o conteúdo original deste repositório. O emulador e o SQL Edge permanecem
sujeitos às licenças upstream; consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md).
