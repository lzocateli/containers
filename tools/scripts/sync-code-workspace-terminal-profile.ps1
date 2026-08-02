<#
.SYNOPSIS
Padroniza profile de terminal em arquivos .code-workspace.

.DESCRIPTION
Lê um arquivo de template JSON com as chaves de terminal integrado do VS Code
e aplica os valores em todos os arquivos .code-workspace abaixo de uma raiz.

.PARAMETER WorkspaceRoot
Diretorio raiz onde a busca de arquivos .code-workspace sera executada.
Padrao: pasta projetos acima deste repositorio.

.PARAMETER TemplateFile
Arquivo JSON com as chaves:
- terminal.integrated.profiles.windows
- terminal.integrated.defaultProfile.windows

.PARAMETER DryRun
Exibe quais arquivos seriam atualizados sem gravar alteracoes.

.PARAMETER Help
Exibe ajuda.

.PARAMETER RemainingArgs
Argumentos adicionais para compatibilidade com --help literal.

.EXAMPLE
tools/scripts/sync-code-workspace-terminal-profile.ps1 --help

.EXAMPLE
tools/scripts/sync-code-workspace-terminal-profile.ps1 -DryRun

.EXAMPLE
tools/scripts/sync-code-workspace-terminal-profile.ps1 -WorkspaceRoot C:\Users\lzob8c1\projetos

.INPUTS
None.

.OUTPUTS
Resumo com total de arquivos processados, atualizados e ignorados.

.NOTES
Dependencias minimas:
- PowerShell 7+

Documentacao:
- .github/SCRIPTING.md

.LINK
https://code.visualstudio.com/docs/editor/multi-root-workspaces
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,

    [Parameter()]
    [string]$TemplateFile = (Join-Path $PSScriptRoot 'workspace-terminal-profile.template.json'),

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [switch]$Help,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Show-Usage {
@'
sync-code-workspace-terminal-profile.ps1

Finalidade:
- Padronizar profile do terminal integrado em arquivos .code-workspace.

Dependencias minimas:
- PowerShell 7+

Uso:
  tools/scripts/sync-code-workspace-terminal-profile.ps1 [opcoes]

Opcoes principais:
  -WorkspaceRoot <path>   Raiz para busca de .code-workspace
  -TemplateFile <path>    Arquivo template JSON
  -DryRun                 Mostra alteracoes sem gravar
  --help                  Exibe esta ajuda

Exemplos:
  tools/scripts/sync-code-workspace-terminal-profile.ps1 --help
  tools/scripts/sync-code-workspace-terminal-profile.ps1 -DryRun
  tools/scripts/sync-code-workspace-terminal-profile.ps1 -WorkspaceRoot C:\Users\lzob8c1\projetos
'@ | Write-Host
}

function Read-JsonHashtable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $content = Get-Content -Path $Path -Raw -Encoding UTF8
    if ($null -eq $content) {
        $content = ''
    }

    if ([string]::IsNullOrWhiteSpace($content)) {
        throw "Arquivo JSON vazio: $Path"
    }

    return $content | ConvertFrom-Json -AsHashtable
}

if ($Help -or ($RemainingArgs -contains '--help') -or $WorkspaceRoot -eq '--help' -or $TemplateFile -eq '--help') {
    Show-Usage
    exit 0
}

if (-not (Test-Path -Path $WorkspaceRoot -PathType Container)) {
    throw "Diretorio WorkspaceRoot nao encontrado: $WorkspaceRoot"
}

if (-not (Test-Path -Path $TemplateFile -PathType Leaf)) {
    throw "TemplateFile nao encontrado: $TemplateFile"
}

$template = Read-JsonHashtable -Path $TemplateFile

if (-not $template.ContainsKey('terminal.integrated.profiles.windows')) {
    throw "Template invalido: chave obrigatoria ausente: terminal.integrated.profiles.windows"
}

if (-not $template.ContainsKey('terminal.integrated.defaultProfile.windows')) {
    throw "Template invalido: chave obrigatoria ausente: terminal.integrated.defaultProfile.windows"
}

$workspaceFiles = Get-ChildItem -Path $WorkspaceRoot -Recurse -File -Filter '*.code-workspace' -ErrorAction SilentlyContinue

if (-not $workspaceFiles -or $workspaceFiles.Count -eq 0) {
    Write-Host '[info] Nenhum arquivo .code-workspace encontrado.'
    exit 0
}

$updatedCount = 0
$unchangedCount = 0
$errorCount = 0

foreach ($file in $workspaceFiles) {
    try {
        $workspace = Read-JsonHashtable -Path $file.FullName

        if (-not $workspace.ContainsKey('settings') -or $null -eq $workspace.settings) {
            $workspace.settings = @{}
        }

        if (-not ($workspace.settings -is [hashtable])) {
            $workspace.settings = @{} + $workspace.settings
        }

        $before = $workspace | ConvertTo-Json -Depth 100

        $workspace.settings['terminal.integrated.profiles.windows'] = $template['terminal.integrated.profiles.windows']
        $workspace.settings['terminal.integrated.defaultProfile.windows'] = $template['terminal.integrated.defaultProfile.windows']

        $after = $workspace | ConvertTo-Json -Depth 100

        if ($before -eq $after) {
            $unchangedCount++
            Write-Host "[skip] $($file.FullName)"
            continue
        }

        if ($DryRun.IsPresent) {
            $updatedCount++
            Write-Host "[dry-run] atualizaria: $($file.FullName)"
            continue
        }

        Set-Content -Path $file.FullName -Value $after -Encoding UTF8
        $updatedCount++
        Write-Host "[ok] atualizado: $($file.FullName)"
    }
    catch {
        $errorCount++
        Write-Error "Falha ao processar '$($file.FullName)': $($_.Exception.Message)"
    }
}

Write-Host ''
Write-Host '[resumo]'
Write-Host "  total encontrados : $($workspaceFiles.Count)"
Write-Host "  atualizados       : $updatedCount"
Write-Host "  sem mudanca       : $unchangedCount"
Write-Host "  erros             : $errorCount"

if ($errorCount -gt 0) {
    exit 1
}

exit 0