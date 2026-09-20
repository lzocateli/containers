<#
.SYNOPSIS
Configura o hook Gitleaks Docker-only no clone atual.
.DESCRIPTION
Configura apenas core.hooksPath=.githooks. O hook executa a imagem fixa
lzocateli/gitleaks:8.30.1 e não instala ferramentas no host.
.EXAMPLE
./tools/scripts/install-gitleaks-hook.ps1
.NOTES
Requer Git, PowerShell 7 e Docker disponíveis no host.
#>
#requires -Version 7.0
[CmdletBinding(PositionalBinding = $false)]
param(
    [string] $RepositoryRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [Parameter(ValueFromRemainingArguments)] [string[]] $RemainingArguments
)

$ErrorActionPreference = 'Stop'
if ($RemainingArguments -contains '--help') { Get-Help $PSCommandPath -Full; exit 0 }
if ($RemainingArguments.Count -gt 0) { throw "Argumento desconhecido. Use --help." }

$root = [IO.Path]::GetFullPath($RepositoryRoot)
if (-not (Test-Path -LiteralPath (Join-Path $root '.git'))) { throw "Nao e um clone Git: $root" }
if ($null -eq (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git nao foi encontrado no PATH.' }
if ($null -eq (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Docker nao foi encontrado no PATH.' }

& git -C $root config --local core.hooksPath .githooks
if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel configurar core.hooksPath.' }
Write-Output 'Hook Gitleaks configurado via Docker: core.hooksPath=.githooks'
