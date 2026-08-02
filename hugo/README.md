<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# Hugo Extended

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fhugo-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-exts--0.165.0--dev.8a468df--1-2E7D32)
![Base](https://img.shields.io/badge/base-hugomods%2Fhugo%3Anightly--non--root%40sha256-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Hugo Extended reproduzível e compartilhado pelos projetos Blog zocate.li e ThothisIT. A imagem substitui as unidades específicas `blog-hugo` e `thothis-hugo`, fixa a base por digest e executa sem root.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/hugo:exts-0.165.0-dev.8a468df-1` |
| Imagem base | `hugomods/hugo:nightly-non-root` fixada pelo digest do commit `8a468df065a7` |
| Plataforma | `linux/amd64` |
| Usuário padrão | `hugo` (`1000:1000`) |
| Entry point | `docker-entrypoint.sh` herdado da base |
| Diretório de trabalho | `/src` |
| Porta declarada | `1313/tcp` |
| Health check | Não aplicável; a imagem executa comandos finitos ou o servidor de desenvolvimento |
| Código-fonte | `https://github.com/lzocateli/containers/tree/main/hugo` |

## Conteúdo e finalidade

### Incluído

- Hugo Extended `0.165.0-DEV`, commit `8a468df065a7`, para Linux amd64.
- npm CLI `12.0.2`, atualizado sobre a base para usar `node-tar` corrigido.
- Usuário não root `hugo` e diretório de trabalho `/src`.
- Suporte a transformação Sass exigido pelos dois consumidores.

### Não incluído

- Código-fonte ou conteúdo dos sites consumidores.
- Timezone específico; Blog e ThothisIT configuram `TZ` no ambiente de execução.
- Servidor HTTP de produção; publique os arquivos estáticos com um runtime dedicado.
- Secrets, configuração de ambiente ou dados persistentes.

## Início rápido

```bash
docker pull lzocateli/hugo:exts-0.165.0-dev.8a468df-1
docker run --rm lzocateli/hugo:exts-0.165.0-dev.8a468df-1 version
```

Para construir um site no diretório atual:

```bash
docker run --rm \
  --volume "${PWD}:/src" \
  lzocateli/hugo:exts-0.165.0-dev.8a468df-1 \
  hugo --gc --minify --cleanDestinationDir
```

## Docker Compose

```yaml
services:
  hugo:
    image: lzocateli/hugo:exts-0.165.0-dev.8a468df-1
    command: server --bind 0.0.0.0 --port 1313 --buildDrafts
    environment:
      TZ: America/Sao_Paulo
    ports:
      - "127.0.0.1:1313:1313"
    volumes:
      - .:/src
```

## Configuração

A imagem não adiciona variáveis de ambiente. Argumentos, subcomandos Hugo e o formato legado `hugo <argumentos>` são encaminhados pelo entrypoint herdado.

### Persistência e mounts

| Caminho | Modo | Conteúdo | Backup necessário |
| --- | --- | --- | --- |
| `/src` | `rw` em desenvolvimento | Código-fonte e saída padrão `public/` | Conforme a política do consumidor |

O bind mount deve permitir leitura e escrita ao UID/GID `1000:1000`. Em CI, prefira origem somente leitura e destino de publicação separado e gravável.

## Segurança

- Execução padrão sem root como `hugo` (`1000:1000`).
- Nenhuma capacidade Linux adicional é necessária.
- Builds finitos aceitam root filesystem somente leitura quando `/tmp` e o destino de publicação são graváveis.
- O npm da base é atualizado de forma reproduzível para remover vulnerabilidade crítica corrigível em `node-tar`.
- A porta do servidor de desenvolvimento deve ser publicada somente em localhost.
- A base é fixada por tag e digest; sua atualização exige nova tag imutável e nova validação.

## Build local

```bash
docker buildx build \
  --pull \
  --platform linux/amd64 \
  --load \
  --tag local/hugo:exts-0.165.0-dev.8a468df-1 \
  hugo
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `exts-0.165.0-dev.8a468df-1` | Imutável | Hugo Extended pré-release no commit `8a468df065a7`, Linux amd64 | Desenvolvimento e CI do Blog e ThothisIT |

A tag preserva o prefixo público `exts-` da imagem `lzocateli/hugo`. Mudanças de Hugo, base, usuário, entrypoint, porta ou ferramentas geram uma nova tag imutável.

## Validação

O smoke test verifica versão, edição Extended, usuário padrão, root filesystem somente leitura e build Sass minificado com fixture sintética:

```bash
bash hugo/scripts/smoke-test.sh --image local/hugo:exts-0.165.0-dev.8a468df-1
```

O catálogo executa esse teste na validação contínua e antes da publicação. O workflow também valida o Dockerfile com BuildKit, bloqueia vulnerabilidades `CRITICAL` corrigíveis e gera SBOM e proveniência na release.

## Publicação

Use **Actions > Publicar imagem de container > Run workflow** com:

- `context_path`: `hugo`;
- `image_name`: `hugo`;
- `image_tag`: `exts-0.165.0-dev.8a468df-1`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64`.

Push e publicação exigem solicitação explícita e credenciais já configuradas.

## Operação

A imagem não mantém estado nem requer backup próprio. Para rollback, restaure no consumidor a tag ou o digest imutável anterior. Logs são emitidos pelo processo Hugo em stdout e stderr.

## Troubleshooting

| Sintoma | Causa provável | Verificação | Correção |
| --- | --- | --- | --- |
| `permission denied` no build | Bind mount não permite escrita ao UID 1000 | `docker run --rm IMAGEM id` | Ajuste a propriedade do destino ou monte uma saída gravável |
| Porta 1313 indisponível | Conflito local | Verifique o processo que usa a porta | Publique outra porta somente em localhost |
| Transformação Sass falha | Tag incorreta ou entrada inválida | Execute `version` e o smoke test | Use a tag Extended documentada e corrija o recurso Sass |

## Limitações conhecidas

- Publicação restrita a `linux/amd64` enquanto essa for a plataforma validada pelos consumidores.
- O servidor embutido do Hugo é destinado somente ao desenvolvimento.
- A base é uma build oficial pré-release, fixada por digest e commit, adotada porque a última release estável disponível contém vulnerabilidade `CRITICAL` corrigível. Substitua-a por uma release estável assim que uma versão posterior corrigida estiver disponível.

## Licenças e fontes

| Componente | Versão | Licença | Fonte |
| --- | --- | --- | --- |
| Conteúdo original deste repositório | Atual | MIT | `https://github.com/lzocateli/containers` |
| Hugo | `0.165.0-DEV`, commit `8a468df065a7` | Apache-2.0 | `https://github.com/gohugoio/hugo` |
| npm CLI | `12.0.2` | Artistic-2.0 | `https://github.com/npm/cli` |
| Imagem base Hugomods | `nightly-non-root` por digest | Componentes sob suas licenças upstream | `https://github.com/hugomods/docker` |

O badge MIT descreve somente o conteúdo original deste repositório. A imagem inclui componentes de terceiros que permanecem sujeitos aos termos e avisos de suas fontes. Consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md) e preserve as atribuições upstream.

## Histórico de alterações

- `exts-0.165.0-dev.8a468df-1`: consolida Blog e ThothisIT em uma imagem Hugo Extended compartilhada, sem root e com smoke test funcional.