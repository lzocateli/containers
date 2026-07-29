# Scripts e automação

Este documento define onde criar scripts e o contrato mínimo de linha de comando no repositório `containers`.

## Estrutura

```text
tools/
├── container-images.json  # fonte de verdade das imagens publicáveis
├── pyproject.toml          # único projeto Python/uv do repositório
├── uv.lock                 # lockfile compartilhado das ferramentas Python
└── scripts/
    ├── validar.ps1         # automação PowerShell do repositório
    ├── publicar.sh         # automação Bash do repositório
    └── catalogo/
        └── main.py         # ferramenta Python executada com uv
<imagem>/
└── scripts/                # entrypoints e scripts pertencentes à imagem
```

Scripts de administração, manutenção e validação do repositório pertencem a `tools/scripts/`. Scripts usados por Dockerfile, Compose, entrypoint, health check ou runtime pertencem à pasta da imagem correspondente, pois fazem parte do contrato dessa imagem.

Arquivos existentes fora dessa estrutura não devem ser movidos incidentalmente. A migração ocorre quando o script for refatorado e deve atualizar todos os consumidores no mesmo conjunto de mudanças.

## Ajuda obrigatória

Todo script criado ou refatorado deve aceitar `--help` e apresentar, sem executar a operação principal:

- finalidade e escopo;
- dependências e versões mínimas;
- sintaxe e parâmetros, incluindo valores padrão;
- pelo menos um exemplo executável;
- caminho ou URL para documentação mais ampla, quando existir.

O comando deve encerrar com código `0` e não pode exigir rede, credenciais ou dependências opcionais apenas para mostrar a ajuda. Erros de uso devem ir para stderr, retornar código diferente de zero e indicar `--help`.

## PowerShell

Use o comment-based help nativo para integração com `Get-Help`. Dependências ficam em `.NOTES`; referências adicionais ficam em `.LINK`. Scripts expostos como comandos também devem reconhecer literalmente `--help`, além de `-?`.

```powershell
Get-Help .\tools\scripts\validar.ps1 -Full
.\tools\scripts\validar.ps1 --help
```

## Bash

Implemente `-h` e `--help` com recursos nativos do shell e valide a sintaxe antes da execução funcional.

```bash
bash -n tools/scripts/publicar.sh
bash tools/scripts/publicar.sh --help
```

## Python com uv

Todas as ferramentas Python compartilham `tools/pyproject.toml`. Dependências são gerenciadas com `uv`, e `tools/uv.lock` deve permanecer sincronizado e versionado.

```bash
uv add --project tools pacote
uv run --project tools python tools/scripts/catalogo/main.py --help
```

Não crie `requirements.txt`, ambientes virtuais manuais ou outros arquivos `pyproject.toml` para automação do repositório.

## Revisão

Uma alteração de script somente está completa quando a ajuda corresponde à implementação, o caminho de ajuda foi executado, um fluxo funcional foi testado e todos os consumidores afetados foram atualizados. Nunca inclua tokens, senhas, conteúdo de `.env` ou credenciais em exemplos, logs ou mensagens de ajuda.