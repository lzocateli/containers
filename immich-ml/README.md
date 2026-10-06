<!--
SPDX-FileCopyrightText: 2026 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# Immich Machine Learning

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fimmich--ml-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-v3.2.4--v2-2E7D32)
![Base](https://img.shields.io/badge/base-immich--machine--learning%3Av3.2.4-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-linux%2Famd64_local-success)

Variante CPU do serviço de machine learning Immich v3.2.4 usada pelo Compose do TrueNAS. Atualiza `perl-base` do Debian e AnyIO 4.2.0 para 4.14.2 no virtualenv da aplicação. Preserva usuário, entrypoint, comando e health check upstream.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem prevista | `lzocateli/immich-ml:v3.2.4-v2` |
| Base | `ghcr.io/immich-app/immich-machine-learning:v3.2.4@sha256:e16c2f166a8174901959fdf85e2e4c7bd1ebc4b37e0b6655de97c41408a260c4` |
| Plataformas declaradas | `linux/amd64` (upstream também fornece `linux/arm64`) |
| Usuário, entrypoint e comando | Config.User vazio (root inicial); `tini --`, `python -m immich_ml`, herdados da base |
| Exposição | Rede interna do Compose, sem porta publicada no host |
| Código-fonte e documentação | [Repositório da imagem](https://github.com/lzocateli/containers/tree/main/immich-ml) |

## Conteúdo e finalidade

Inclui a imagem oficial de inferência CPU com AnyIO 4.14.2 no lugar de 4.2.0 e `perl-base` atualizado no runtime Debian. O build prepara o pacote AnyIO em um estágio temporário usando a mesma base upstream; não inclui `pip` na imagem final. Não inclui modelos pré-baixados, dados de mídia, servidor, banco, cache nem aceleração CUDA/ROCm/OpenVINO. O servidor Immich solicita as tarefas de inferência na rede interna.

## Início rápido

```bash
docker buildx build --pull --platform linux/amd64 --load -t lzocateli/immich-ml:v3.2.4-v2 immich-ml
```

Execute com o servidor do mesmo release, não isoladamente como serviço público.

## Docker Compose

```yaml
services:
  immich-machine-learning:
    image: lzocateli/immich-ml:v3.2.4-v2
    env_file: .env
    volumes:
      - /mnt/pve_pool/immich/model-cache:/cache
    restart: always
```

## Configuração

| Variável | Obrigatória | Secreta | Origem e função |
| --- | --- | --- | --- |
| `TZ` | Não | Não | Fuso horário, caso configurado no `.env`. |
| Variáveis de ML do Immich | Não para CPU padrão | Depende | Consulte a documentação da mesma release para ajustes de modelos, memória e workers. |

O volume `/cache` é gravável e guarda modelos baixados; preservá-lo evita novo download. Não contém a biblioteca original, mas pode consumir muito espaço. Verifique UID/GID efetivo e permissões do mount antes de subir no TrueNAS. Secrets, se usados, entram apenas em runtime.

## Inicialização e ciclo de vida

O serviço baixa modelos na primeira utilização; o health check herdado da base não comprova que todos os modelos terminaram de carregar. Reinícios e encerramento seguem o entrypoint upstream. Mantenha o cache enquanto atualiza a stack e avalie a compatibilidade dos modelos após o upgrade.

## Segurança

Não publique a porta interna do serviço, não inclua modelos privados ou credenciais no build e mantenha ACLs do cache limitadas à stack. Não force usuário ou filesystem read-only sem confirmar os diretórios graváveis da imagem upstream.

## Build local

```bash
docker buildx build --check --file immich-ml/Dockerfile immich-ml
docker buildx build --pull --platform linux/amd64 --load -t lzocateli/immich-ml:v3.2.4-v2 immich-ml
```

## Tags e compatibilidade

| Tag | Mutabilidade | Uso |
| --- | --- | --- |
| `v3.2.4-v2` | Imutável após publicação | Servidor Immich da mesma release, variante CPU com AnyIO e Perl corrigidos. |

Não reutilize `v3.2.4-v2` depois de publicada e não publique `latest`; `v3.2.4-v1` não foi publicada porque o gate de segurança a bloqueou. Uma variante com GPU precisa de imagem/tag e validação próprias.

## Validação

O run de publicação da tag `v3.2.4-v1` foi bloqueado pelo Trivy 0.70.0 por `CVE-2026-13221`, `CVE-2026-42496` e `CVE-2026-8376` em `perl-base` `5.36.0-7+deb12u3`; a versão corrigida indicada é `5.36.0-7+deb12u4`. Para `v3.2.4-v2`, BuildKit `--check`, build `linux/amd64`, `perl-base` `5.36.0-7+deb12u4` e importação de AnyIO no runtime passaram. O scanner oficial com Trivy 0.72.0 e banco atualizado encontrou zero CRITICAL, portanto o gate corrigível passou; o relatório mantém 21 HIGH para análise. Antes de publicar, conclua o teste funcional de inferência em stack descartável, teste do cache após recriação, SBOM e proveniência.

## Publicação

No workflow **Publicar imagem de container**, use `context_path=immich-ml`, `image_name=immich-ml`, `image_tag=v3.2.4-v2`, `dockerfile=Dockerfile`, `platforms=linux/amd64` somente após todos os gates da release.

## Operação

Monitore consumo de CPU, memória e tamanho do cache. Em rollback, mantenha a tag compatível com o servidor; o cache pode ser reconstruído, mas exige rede e tempo de download.

## Troubleshooting

| Sintoma | Verificação | Correção |
| --- | --- | --- |
| Modelo não carrega | Logs, espaço e permissões de `/cache` | Corrigir ACL/capacidade e repetir a tarefa. |
| Inferência indisponível | Rede Compose e saúde do processo | Validar comunicação com o servidor na rede interna. |

## Limitações conhecidas

Variante somente CPU; não inclui teste funcional dos modelos nem garantia de desempenho no TrueNAS.

## Licenças e fontes

| Componente | Licença | Fonte |
| --- | --- | --- |
| Conteúdo original deste repositório | MIT | [containers](https://github.com/lzocateli/containers) |
| Immich v3.2.4 | AGPL-3.0 | [Immich](https://github.com/immich-app/immich/tree/v3.2.4) |
| Modelos baixados no runtime | Licenças dos modelos individuais | [Documentação de ML](https://docs.immich.app/features/ml-hardware-acceleration/) |

MIT cobre somente o conteúdo original deste repositório. Preserve avisos de terceiros e consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md) e os avisos distribuídos na imagem.

## Histórico de alterações

- `v3.2.4-v2`: atualiza perl-base para corrigir os CVEs bloqueantes reportados pelo Trivy; mantém AnyIO 4.14.2.
- `v3.2.4-v1`: corrige CVE-2026-63374 com AnyIO 4.14.2, mas não foi publicada porque o Trivy encontrou CVEs corrigíveis em perl-base.
- `v3.2.4`: atualiza a base de inferência CPU para a release v3.2.4.
- `v2.6.3`: wrapper inicial da variante CPU para TrueNAS.
