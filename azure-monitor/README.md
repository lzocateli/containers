<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# Azure Monitor Agent

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fazure--monitor-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-3.12--bookworm-2E7D32)
![Base](https://img.shields.io/badge/base-python%3A3.12--bookworm-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Imagem de suporte ao Azure Monitor Agent para coleta de logs de aplicacoes. O workspace e a chave sao
fornecidos somente em runtime; nenhum segredo ou identificador de ambiente e incorporado a imagem.

## Referência da imagem

| Item                  | Valor                                                             |
| --------------------- | ----------------------------------------------------------------- |
| Imagem                | `lzocateli/azure-monitor:3.12-bookworm`                           |
| Imagem base           | `python:3.12-bookworm`                                            |
| Plataformas           | `linux/amd64`                                                     |
| Usuario padrao        | `root` (necessario para instalar o agente e coletar logs)         |
| Entry point           | `/usr/local/bin/azure-monitor-entrypoint`                         |
| Comando padrao        | `/opt/microsoft/omsagent/bin/service_control start`               |
| Diretorio de trabalho | O diretorio herdado da imagem Python                              |
| Codigo-fonte          | `https://github.com/lzocateli/containers/tree/main/azure-monitor` |
| Documentacao          | `https://github.com/lzocateli/containers/tree/main/azure-monitor` |

## Conteudo e finalidade

### Incluido

- Python 3.12 sobre Debian Bookworm;
- Azure CLI, Terraform, ferramentas de shell e utilitarios de suporte;
- entrypoint que executa o onboarding do agente no primeiro inicio;
- metadados OCI para identificacao da imagem.

### Nao incluido

- Workspace, chave, tokens ou connection strings do Azure;
- configuracoes de ambiente especificas;
- persistencia de logs ou dados aplicacionais dentro da imagem;
- suporte oficial para `linux/arm64`.

## Inicio rapido

```bash
docker run --rm -d \
  --name azure-monitor \
  -e WORKSPACE_ID="<workspace-id>" \
  -e WORKSPACE_KEY="<workspace-key>" \
  -v /var/log/nginx:/var/log/nginx:ro \
  lzocateli/azure-monitor:3.12-bookworm
```

O primeiro inicio pode baixar e instalar componentes do agente. Forneca `WORKSPACE_KEY` por secret do
runtime, nunca por Dockerfile, Git ou argumento persistido em shell history.

## Docker Compose

```yaml
services:
  azure-monitor:
    image: lzocateli/azure-monitor:3.12-bookworm
    restart: unless-stopped
    environment:
      WORKSPACE_ID: ${WORKSPACE_ID}
      WORKSPACE_KEY: ${WORKSPACE_KEY}
    volumes:
      - /var/log/nginx:/var/log/nginx:ro
```

## Configuracao

| Variavel        | Obrigatoria | Secreta | Padrao | Descricao                       |
| --------------- | ----------- | ------- | ------ | ------------------------------- |
| `WORKSPACE_ID`  | Sim         | Nao     | nenhum | ID do Log Analytics Workspace.  |
| `WORKSPACE_KEY` | Sim         | Sim     | nenhum | Chave de ingestao do workspace. |

### Portas

Nao ha portas declaradas pela imagem. A coleta usa a conectividade de saida necessaria ao agente.

### Persistencia e mounts

| Caminho no container | Modo | Conteudo                   | Backup necessario |
| -------------------- | ---- | -------------------------- | ----------------- |
| `/var/log/nginx`     | `ro` | Logs da aplicacao ou proxy | Conforme o host   |

Monte somente os diretorios de logs necessarios. Configuracoes adicionais do agente devem ser fornecidas pelo consumidor no runtime.

### Secrets

Forneca `WORKSPACE_KEY` por secret do Docker Compose, orquestrador ou pipeline. Nao versionar valores reais, nao usar `ARG` para credenciais e nao gravar a chave em arquivos de configuracao.

## Inicializacao e ciclo de vida

O entrypoint valida `WORKSPACE_ID` e `WORKSPACE_KEY`. Se o agente ainda nao estiver instalado, executa o script upstream de onboarding e depois substitui o processo pelo comando recebido. O container encerra quando o processo principal encerra e nao possui migracoes ou bootstrap de dados.

## Build local

```bash
docker build --pull --tag lzocateli/azure-monitor:3.12-bookworm azure-monitor
```

## Seguranca

- Nunca inclua secrets no contexto de build, na imagem ou na documentacao.
- A imagem executa como `root` porque o agente precisa instalar componentes e acessar logs.
- Restrinja a rede de saida ao necessario para o Azure Monitor.
- A base e as dependencias devem ser atualizadas e escaneadas antes de cada release.

## Tags e compatibilidade

| Tag             | Mutabilidade | Compatibilidade                                  | Uso recomendado    |
| --------------- | ------------ | ------------------------------------------------ | ------------------ |
| `3.12-bookworm` | Imutavel     | Python 3.12 sobre Debian Bookworm, `linux/amd64` | Release versionada |

Alteracoes na base, no entrypoint, nas variaveis ou no processo de onboarding exigem nova tag imutavel e nova validacao. Nao ha politica para `latest`.

## Validacao

Antes da publicacao, execute:

```bash
docker buildx build --check --file azure-monitor/Dockerfile azure-monitor
docker build --pull --tag lzocateli/azure-monitor:3.12-bookworm azure-monitor
docker inspect lzocateli/azure-monitor:3.12-bookworm
```

Confirme os ignores, a ausencia de secrets no contexto, os labels OCI, o entrypoint, o usuario, o scan de vulnerabilidades, SBOM e proveniencia. O smoke test deve usar secrets efemeros.

## Publicacao

Use **Actions > Publicar imagem de container > Run workflow** com:

- `context_path`: `azure-monitor`;
- `image_name`: `azure-monitor`;
- `image_tag`: `3.12-bookworm`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64`.

O workflow publica no Docker Hub com SBOM e proveniencia e pode sincronizar este README.

## Operacao e troubleshooting

| Sintoma                                             | Causa provavel                                | Verificacao                                    | Correcao                                          |
| --------------------------------------------------- | --------------------------------------------- | ---------------------------------------------- | ------------------------------------------------- |
| Container encerra informando `WORKSPACE_ID` ausente | Variavel obrigatoria nao fornecida            | Inspecione a configuracao sem imprimir secrets | Defina `WORKSPACE_ID` no runtime                  |
| Onboarding falha                                    | Rede ou credencial indisponivel               | Consulte logs sem exibir `WORKSPACE_KEY`       | Libere somente a rede necessaria e valide a chave |
| Logs nao aparecem                                   | Diretorio nao montado ou permissao inadequada | Confirme o bind mount em modo leitura          | Monte o caminho correto de logs                   |

Nao ha dados aplicacionais para backup dentro da imagem. Para rollback, use a tag imutavel anterior.

## Limitacoes conhecidas

- A imagem e executada como root por requisito operacional do agente.
- O onboarding depende dos servicos upstream e de credenciais validas do Azure Monitor.
- A imagem e publicada somente para `linux/amd64`.
- A base Python pode apresentar vulnerabilidades upstream; repita o scan antes da promocao.

## Licencas e fontes

O badge MIT descreve somente o conteudo original deste repositorio. Componentes de terceiros permanecem sujeitos aos termos de suas fontes. Consulte a [politica de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md).

## Historico de alteracoes

- `3.12-bookworm`: documentacao alinhada ao padrao do projeto e onboarding configurado por runtime.
