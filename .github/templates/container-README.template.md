<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# NOME DA IMAGEM

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2FNOME-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-TAG-2E7D32)
![Base](https://img.shields.io/badge/base-IMAGEM%3ATAG-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Descrição objetiva da finalidade, público e principal diferença em relação à imagem base.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/NOME:TAG` |
| Imagem base | `IMAGEM_BASE:TAG_BASE` |
| Plataformas | `linux/amd64` |
| Usuário padrão | `UID:GID` ou `root` com justificativa |
| Entry point | `ENTRYPOINT` efetivo |
| Diretório de trabalho | `/caminho` |
| Código-fonte | `https://github.com/lzocateli/containers/tree/main/PASTA` |
| Documentação | `https://github.com/lzocateli/containers/tree/main/PASTA` |

## Conteúdo e finalidade

### Incluído

- Software, extensão ou ferramenta e versão.
- Configuração adicionada pela imagem.

### Não incluído

- Serviço externo, dado ou configuração que o consumidor deve fornecer.
- Uso deliberadamente fora do escopo.

## Início rápido

```bash
docker pull lzocateli/NOME:TAG
docker run --rm lzocateli/NOME:TAG --version
```

Exemplo mínimo executável:

```bash
docker run --name NOME \
  --detach \
  --publish 127.0.0.1:PORTA_HOST:PORTA_CONTAINER \
  lzocateli/NOME:TAG
```

## Docker Compose

```yaml
services:
  servico:
    image: lzocateli/NOME:TAG
    restart: unless-stopped
    ports:
      - "127.0.0.1:PORTA_HOST:PORTA_CONTAINER"
    environment:
      VARIAVEL: valor
    volumes:
      - /caminho/absoluto/no/host:/caminho/no/container
```

## Configuração

### Variáveis de ambiente

| Variável | Obrigatória | Secreta | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| `VARIAVEL` | Sim/Não | Sim/Não | `valor` ou nenhum | Efeito e formato aceito. |

### Portas

| Porta | Protocolo | Exposição recomendada | Finalidade |
| --- | --- | --- | --- |
| `PORTA/tcp` | TCP | Rede interna ou localhost | Descrição. |

### Persistência e mounts

| Caminho no contêiner | Modo | Conteúdo | Backup necessário |
| --- | --- | --- | --- |
| `/caminho` | `rw` ou `ro` | Dados/configuração | Sim/Não |

Descreva propriedade `UID:GID`, permissões, bind mounts e comportamento na primeira inicialização.

### Secrets

Explique como fornecer secrets pelo runtime. Não use `ARG`, `ENV` no Dockerfile nem valores versionados.

## Inicialização e ciclo de vida

Documente bootstrap, ordem de scripts, migrations, health check, sinais de término e comportamento em reinícios.

## Segurança

- Usuário e privilégios efetivos.
- Capacidades Linux necessárias ou removíveis.
- Recomendação de filesystem somente leitura e diretórios graváveis.
- Exposição de rede e política de secrets.
- Origem e atualização da imagem base.

## Build local

```bash
docker build \
  --pull \
  --tag lzocateli/NOME:TAG \
  PASTA
```

Para múltiplas plataformas:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag lzocateli/NOME:TAG \
  PASTA
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `TAG` | Imutável | Descrição | Produção |

Explique versionamento, política de atualização e qualquer tag móvel deliberada.

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

- `context_path`: pasta desta imagem;
- `image_name`: nome sem o namespace `lzocateli/`;
- `image_tag`: tag imutável;
- `dockerfile`: nome do Dockerfile;
- `platforms`: plataformas separadas por vírgula.

O workflow publica no Docker Hub e pode sincronizar este README como descrição completa.

## Operação

Descreva backup, restore, atualização, rollback, logs, métricas e limites de recursos relevantes.

## Troubleshooting

| Sintoma | Causa provável | Verificação | Correção |
| --- | --- | --- | --- |
| Exemplo | Exemplo | Comando sem segredo | Ação segura |

## Limitações conhecidas

- Limitação ou decisão explícita.

## Licenças e fontes

| Componente | Versão | Licença | Fonte |
| --- | --- | --- | --- |
| Conteúdo original deste repositório | Atual | MIT | `https://github.com/lzocateli/containers` |
| Imagem base | Versão | Licença | URL oficial |

O badge MIT descreve somente o conteúdo original deste repositório. A imagem inclui componentes de terceiros que permanecem sujeitos aos termos e avisos de suas fontes. Consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md), preserve as atribuições upstream e verifique também os avisos distribuídos dentro da imagem.

## Histórico de alterações

Registre mudanças observáveis por tag ou referencie um `CHANGELOG.md` da imagem.
