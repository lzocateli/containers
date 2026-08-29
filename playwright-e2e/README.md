<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# Playwright E2E com pytest e WireGuard

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fplaywright--e2e-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-0.1.0-2E7D32)
![Base](https://img.shields.io/badge/base-mcr.microsoft.com%2Fplaywright%2Fpython%3Av1.49.0--noble-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Imagem base para suites E2E em Python com Playwright e pytest. Inclui ferramentas WireGuard para cenarios opcionais de VPN; o codigo dos testes e montado pelo consumidor em runtime.

## Referencia da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/playwright-e2e:0.1.0` |
| Imagem base | `mcr.microsoft.com/playwright/python:v1.49.0-noble` |
| Plataformas | `linux/amd64` |
| Usuario padrao | `root` (necessario somente para VPN) |
| Entry point | `uv run --frozen pytest --confcutdir=/app` |
| Diretorio de trabalho | `/app` |
| Codigo-fonte | `https://github.com/lzocateli/containers/tree/main/playwright-e2e` |
| Documentacao | `https://github.com/lzocateli/containers/tree/main/playwright-e2e` |

## Conteudo e finalidade

### Incluido

- Playwright Python 1.49.0, Chromium, Firefox e WebKit.
- pytest 8.3.4, `pytest-playwright`, `pytest-html` e `pytest-xdist`.
- `uv` 0.5.18 e utilitarios WireGuard, DNS e rede.

### Nao incluido

- Testes, fixtures, configuracoes WireGuard e relatorios do consumidor.
- Servico VPN, credenciais ou configuracao de destino.

## Inicio rapido

Monte a suite em `/app` e preserve o caminho de relatorios gravavel:

```bash
docker pull lzocateli/playwright-e2e:0.1.0
docker run --rm \
  --volume "$(pwd)/tests:/app/tests:ro" \
  --volume "$(pwd)/src:/app/src:ro" \
  --volume "$(pwd)/reports:/app/reports" \
  lzocateli/playwright-e2e:0.1.0 \
  --base-url=https://example.com
```

Para usar uma configuracao WireGuard montada em `/app/vpn/configs`, adicione `--cap-add=NET_ADMIN --device=/dev/net/tun`. Essas permissoes nao sao necessarias para execucoes sem VPN.

## Docker Compose

```yaml
services:
  e2e:
    image: lzocateli/playwright-e2e:0.1.0
    volumes:
      - /caminho/absoluto/testes:/app/tests:ro
      - /caminho/absoluto/src:/app/src:ro
      - /caminho/absoluto/reports:/app/reports
      - /caminho/absoluto/vpn-configs:/app/vpn/configs:ro
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    command: ["--base-url=https://example.com"]
```

## Configuracao

### Variaveis de ambiente

| Variavel | Obrigatoria | Secreta | Padrao | Descricao |
| --- | --- | --- | --- | --- |
| `PYTHONPATH` | Nao | Nao | `/app/src` | Caminho para modulos da suite montada. |

### Portas

Nenhuma porta publica faz parte do contrato desta imagem.

### Persistencia e mounts

| Caminho no conteiner | Modo | Conteudo | Backup necessario |
| --- | --- | --- | --- |
| `/app/tests` | `ro` | Testes pytest | Sim, no repositorio consumidor |
| `/app/src` | `ro` | Fixtures, plugins e utilitarios | Sim, no repositorio consumidor |
| `/app/reports` | `rw` | Relatorios HTML e videos | Sim, conforme politica da suite |
| `/app/vpn/configs` | `ro` | Configuracoes WireGuard | Sim, de forma segura |

### Secrets

Forneca credenciais via secrets do orquestrador ou `--env-file`. Arquivos WireGuard sao sensiveis e devem ser montados somente em runtime, nunca copiados para a imagem.

## Inicializacao e ciclo de vida

O entrypoint executa pytest com o diretorio de configuracao em `/app`. O comando padrao usa `http://host.containers.internal:1313` como URL base e pode ser substituido por argumentos pytest. A imagem nao possui health check pois e um processo de curta duracao, nao um servico de rede.

## Seguranca

- A imagem inicia como `root` para permitir `wg-quick` quando a VPN estiver habilitada; execute sem `NET_ADMIN` e sem dispositivo TUN quando ela nao for necessaria.
- Nao expoe portas e nao armazena configuracoes VPN ou credenciais.
- Prefira mounts de codigo somente leitura e mantenha gravavel apenas `/app/reports`.
- A imagem base oficial do Playwright e fixada na versao 1.49.0; atualize-a junto da tag da imagem.

## Build local

```bash
docker build --pull --tag lzocateli/playwright-e2e:0.1.0 playwright-e2e
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `0.1.0` | Imutavel | Playwright 1.49.0 e Python 3.12 | CI e suites compativeis |

Nao ha tag movel publicada. Atualizacoes de Playwright, Python ou do entrypoint requerem uma nova tag imutavel.

## Validacao

Antes da publicacao, confirme:

- `docker buildx build --check --file playwright-e2e/Dockerfile playwright-e2e`;
- build para `linux/amd64`;
- `bash playwright-e2e/scripts/smoke-test.sh --image lzocateli/playwright-e2e:0.1.0`;
- exclusao de `.env`, secrets e `.git` do contexto;
- scan de vulnerabilidades, SBOM e proveniencia pelo workflow oficial.

## Publicacao

Use **Actions > Publicar imagem de container > Run workflow** com:

- `context_path`: `playwright-e2e`;
- `image_name`: `playwright-e2e`;
- `image_tag`: `0.1.0`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64`.

## Operacao

Preserve os relatorios no volume do host. Para atualizar, publique uma nova tag, execute a suite em homologacao e reverta a referencia da imagem da suite consumidora caso necessario.

## Troubleshooting

| Sintoma | Causa provavel | Verificacao | Correcao |
| --- | --- | --- | --- |
| `permission denied` ao conectar VPN | Capacidade de rede ausente | conferir `cap_add` e `/dev/net/tun` | adicionar `NET_ADMIN` e o dispositivo TUN |
| Relatorio nao e criado | `/app/reports` nao esta gravavel | verificar o bind mount | conceder escrita ao diretorio de relatorios |
| Browser nao inicia | Sandbox ou recursos insuficientes | revisar logs do pytest | executar no runtime Docker suportado e revisar limites |

## Limitacoes conhecidas

- Plataforma validada neste repositorio: `linux/amd64`.
- A VPN depende de configuracao WireGuard fornecida pelo consumidor e de capacidades Linux explicitas.

## Licencas e fontes

| Componente | Versao | Licenca | Fonte |
| --- | --- | --- | --- |
| Conteudo original deste repositorio | Atual | MIT | `https://github.com/lzocateli/containers` |
| Playwright | 1.49.0 | Apache-2.0 | `https://playwright.dev/` |
| pytest | 8.3.4 | MIT | `https://pytest.org/` |
| uv | 0.5.18 | MIT ou Apache-2.0 | `https://github.com/astral-sh/uv` |

O badge MIT descreve somente o conteudo original deste repositorio. Componentes de terceiros permanecem sujeitos aos seus termos e avisos de licenca. Consulte a [politica de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md).

## Historico de alteracoes

- `0.1.0`: primeira imagem base migrada do projeto `playwright-e2e`.