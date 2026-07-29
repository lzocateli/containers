---
description: "Use ao criar, mover ou refatorar scripts PowerShell, Bash ou Python, automações locais, comandos uv e pyproject.toml do repositório containers."
applyTo: ["**/*.ps1", "**/*.sh", "**/*.bash", "**/*.py", "**/pyproject.toml", "tools/**"]
---

# Criação e manutenção de scripts

## Localização e propriedade

- Coloque scripts PowerShell (`.ps1`) e Bash (`.sh` ou `.bash`) usados para administrar, validar ou manter este repositório em `tools/scripts/`.
- Coloque cada ferramenta Python do repositório em `tools/scripts/<nome>/`. Use nomes minúsculos em kebab-case para diretórios e snake_case para módulos Python.
- Use somente `tools/pyproject.toml` para dependências, ambientes, comandos e configuração das ferramentas Python do repositório. Não crie outro `pyproject.toml`.
- Execute Python e suas ferramentas exclusivamente por `uv`, por exemplo `uv run python tools/scripts/<nome>/main.py` ou um comando declarado em `[project.scripts]`.
- Scripts que pertencem ao build, entrypoint, health check, inicialização ou runtime de uma imagem não são automação global do repositório. Mantenha-os dentro do diretório específico da imagem e preserve os caminhos consumidos pelo Dockerfile ou Compose.
- Não coloque scripts novos de automação do repositório em `.github/scripts/`, na raiz ou em diretórios de imagens.
- Não mova scripts existentes apenas para adequação estrutural durante uma mudança não relacionada. Ao refatorá-los, planeje a migração de todos os consumidores e preserve compatibilidade quando necessário.

## Contrato de ajuda

- Todo script criado ou refatorado deve aceitar `--help`, encerrar com código `0` e funcionar sem efeitos colaterais, acesso à rede, credenciais ou pré-requisitos opcionais instalados.
- A ajuda deve informar: o que o script faz, dependências e versões mínimas, sintaxe de uso, parâmetros e valores padrão, pelo menos um exemplo executável e o caminho ou URL da documentação mais ampla quando existir.
- Mensagens de erro devem ser acionáveis, ir para stderr e recomendar `--help` quando o uso estiver incorreto.
- Mantenha a saída de ajuda coerente com o comportamento real e atualize-a na mesma alteração que modificar parâmetros, dependências ou exemplos.

## PowerShell

- Use comment-based help nativo do PowerShell com `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, `.INPUTS`, `.OUTPUTS`, `.NOTES` e `.LINK` quando houver documentação mais ampla.
- Registre dependências e versões mínimas em `.NOTES`. Use `[CmdletBinding()]` e `param(...)` para obter `Get-Help` e `-?` de forma nativa.
- Além de `-?`, aceite literalmente `--help` quando o script for chamado como executável por pessoas, workflows ou outras ferramentas.
- Valide o contrato com `Get-Help .\tools\scripts\<script>.ps1 -Full` e com a execução `<script>.ps1 --help`.

## Bash

- Implemente `-h` e `--help` sem dependências externas. Use uma função dedicada, como `usage`, e um heredoc para manter a mensagem legível.
- Comece scripts novos com `#!/usr/bin/env bash` e habilite `set -Eeuo pipefail`, salvo incompatibilidade documentada.
- Valide sintaxe com `bash -n` e execute o caminho `--help` antes dos testes funcionais.

## Python e uv

- Use `argparse` ou biblioteca já declarada em `tools/pyproject.toml`; a ajuda não deve depender de imports opcionais.
- Declare versão mínima do Python, dependências e comandos em `tools/pyproject.toml`, mantendo `tools/uv.lock` versionado quando dependências forem resolvidas.
- Use `uv add --project tools <pacote>` e `uv remove --project tools <pacote>` para alterar dependências. Não edite versões resolvidas manualmente no lockfile.
- Execute validações com `uv run --project tools <comando>` e confirme `uv run --project tools python tools/scripts/<nome>/main.py --help`.
- Não use `pip`, ambientes virtuais manuais, requirements novos ou um `pyproject.toml` por script.

## Validação da alteração

- Verifique o caminho `--help` e pelo menos um fluxo funcional do script.
- Execute o formatador, linter e testes definidos no projeto correspondente.
- Atualize workflows, Dockerfiles, Compose, documentação e chamadas internas quando um caminho ou interface mudar.
- Consulte `.github/SCRIPTING.md` para estrutura, exemplos de invocação e critérios de revisão.