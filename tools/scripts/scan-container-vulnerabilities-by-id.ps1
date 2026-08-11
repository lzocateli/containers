<#
.SYNOPSIS
Executa scan local de vulnerabilidades por id de imagem do catalogo.

.DESCRIPTION
Resolve automaticamente contexto, Dockerfile, image_name e plataforma a partir de
`tools/container-images.json`, depois executa o scan local com Trivy usando
`tools/scripts/scan-container-vulnerabilities.ps1`.

Opcionalmente detecta imagem base interna (namespace lzocateli) usada no Dockerfile
alvo e executa scan da base antes da imagem filha.

.PARAMETER ImageId
ID da imagem no catalogo (campo id em tools/container-images.json).

.PARAMETER ImageTag
Tag local para scan da imagem alvo.
Padrao: local-scan

.PARAMETER IncludeInternalBaseScan
Quando true, tenta detectar e escanear imagem base interna do projeto.
Padrao: true

.PARAMETER ResolveOnly
Quando presente, apenas resolve metadados e imprime o plano sem executar scans.

.PARAMETER Severity
Severidades do relatorio JSON.
Padrao: HIGH,CRITICAL

.PARAMETER IgnoreUnfixed
Ignora vulnerabilidades sem correcao disponivel.
Padrao: true

.PARAMETER GateCritical
Falha se houver CRITICAL corrigivel.
Padrao: true

.PARAMETER Timeout
Timeout do Trivy.
Padrao: 20m

.PARAMETER TrivyImage
Imagem Trivy usada no scan.
Padrao: aquasec/trivy:0.70.0

.PARAMETER OutputDir
Diretorio de saida para TAR e JSON.
Padrao fixo: <repo>/artifacts/security-local
Observacao: parametro customizado e ignorado para manter o cache centralizado.

.PARAMETER CacheDir
Diretorio de cache do banco do Trivy.
Padrao fixo: <repo>/artifacts/security-local/trivy-cache
Observacao: parametro customizado e ignorado para manter o cache centralizado.

.PARAMETER DbCachePolicy
Politica de atualizacao do cache do banco do Trivy.
- auto: usa cache e permite atualizacao automatica quando necessario.
- reuse: usa apenas cache local, sem atualizar da internet.
- refresh: atualiza o banco primeiro e executa scan com cache atualizado.
Padrao: auto

.PARAMETER SkipBuild
Nao rebuilda a imagem alvo/base; usa tags locais existentes.

.PARAMETER Help
Exibe ajuda.

.PARAMETER RemainingArgs
Argumentos adicionais para compatibilidade com --help literal.

.EXAMPLE
./tools/scripts/scan-container-vulnerabilities-by-id.ps1 --help

.EXAMPLE
./tools/scripts/scan-container-vulnerabilities-by-id.ps1 -ImageId k6 -ImageTag 2.1.0-node24.15.0-bookworm

.EXAMPLE
./tools/scripts/scan-container-vulnerabilities-by-id.ps1 -ImageId angular-cli -ResolveOnly

.NOTES
Dependencias minimas:
- PowerShell 7+
- Docker ativo

Documentacao adicional:
- .github/AUTOMATION.md
- .github/skills/container-vulnerability-remediation/SKILL.md
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ImageId,

    [Parameter()]
    [string]$ImageTag = 'local-scan',

    [Parameter()]
    [bool]$IncludeInternalBaseScan = $true,

    [Parameter()]
    [switch]$ResolveOnly,

    [Parameter()]
    [string]$Severity = 'HIGH,CRITICAL',

    [Parameter()]
    [bool]$IgnoreUnfixed = $true,

    [Parameter()]
    [bool]$GateCritical = $true,

    [Parameter()]
    [string]$Timeout = '20m',

    [Parameter()]
    [string]$TrivyImage = 'aquasec/trivy:0.72.0',

    [Parameter()]
    [string]$OutputDir = 'artifacts/security-local',

    [Parameter()]
    [string]$CacheDir = 'artifacts/security-local/trivy-cache',

    [Parameter()]
    [ValidateSet('auto', 'reuse', 'refresh')]
    [string]$DbCachePolicy = 'auto',

    [Parameter()]
    [switch]$SkipBuild,

    [Parameter()]
    [switch]$Help,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Show-Usage {
    @'
scan-container-vulnerabilities-by-id.ps1

Finalidade:
- Resolver imagem pelo catalogo e executar scan local Trivy automaticamente.
- Detectar base interna lzocateli e escanear base + filha quando aplicavel.

Uso:
  ./tools/scripts/scan-container-vulnerabilities-by-id.ps1 -ImageId <id> [opcoes]

Opcoes principais:
  -ImageId <id>                  ID no catalogo (obrigatorio)
  -ImageTag <tag>                Tag local para imagem alvo (padrao: local-scan)
  -IncludeInternalBaseScan <b>   Escaneia base interna do projeto (padrao: true)
  -ResolveOnly                   Apenas imprime resolucao (sem scan)
  -SkipBuild                     Nao executa build local
    -CacheDir <path>               Compatibilidade legada. Ignorado; usa <repo>/artifacts/security-local/trivy-cache
    -DbCachePolicy <mode>          Politica de cache: auto | reuse | refresh
  --help                         Exibe esta ajuda

Exemplos:
  ./tools/scripts/scan-container-vulnerabilities-by-id.ps1 --help
  ./tools/scripts/scan-container-vulnerabilities-by-id.ps1 -ImageId k6 -ImageTag 2.1.0-node24.15.0-bookworm
  ./tools/scripts/scan-container-vulnerabilities-by-id.ps1 -ImageId angular-cli -ResolveOnly
'@ | Write-Host
}

if ($Help -or ($RemainingArgs -contains '--help') -or $ImageId -eq '--help' -or $ImageId -eq '-h') {
    Show-Usage
    exit 0
}

if ([string]::IsNullOrWhiteSpace($ImageId)) {
    Write-Error 'Parametro obrigatorio ausente: -ImageId. Use --help para exemplos.'
    exit 2
}

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $scriptDir '..\..')).Path
$catalogPath = Join-Path -Path $repoRoot -ChildPath 'tools/container-images.json'
$scanScriptPath = Join-Path -Path $repoRoot -ChildPath 'tools/scripts/scan-container-vulnerabilities.ps1'

$OutputDir = Join-Path -Path $repoRoot -ChildPath 'artifacts/security-local'
$CacheDir = Join-Path -Path $repoRoot -ChildPath 'artifacts/security-local/trivy-cache'

if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
    Write-Error "Catalogo nao encontrado: $catalogPath"
    exit 3
}

if (-not (Test-Path -LiteralPath $scanScriptPath -PathType Leaf)) {
    Write-Error "Script base de scan nao encontrado: $scanScriptPath"
    exit 4
}

$catalog = Microsoft.PowerShell.Management\Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
$entry = $catalog.images | Where-Object { $_.id -eq $ImageId }

if ($null -eq $entry) {
    Write-Error "ImageId nao encontrado no catalogo: $ImageId"
    exit 5
}

$targetContext = Join-Path -Path $repoRoot -ChildPath $entry.context
$targetDockerfile = $entry.dockerfile
$targetImageName = $entry.imageName
$targetPlatform = if ($null -ne $entry.scanPlatform -and $entry.scanPlatform) { [string]$entry.scanPlatform } else { [string]$entry.platforms[0] }
$targetDockerfilePath = Join-Path -Path $targetContext -ChildPath $targetDockerfile

if (-not (Test-Path -LiteralPath $targetDockerfilePath -PathType Leaf)) {
    Write-Error "Dockerfile da imagem alvo nao encontrado: $targetDockerfilePath"
    exit 6
}

function Resolve-DockerfileArgDefaults {
    param([string]$DockerfilePath)

    $argMap = @{}
    foreach ($line in (Microsoft.PowerShell.Management\Get-Content -LiteralPath $DockerfilePath)) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^(?i:ARG)\s+([A-Za-z_][A-Za-z0-9_]*)=(.+)$') {
            $argMap[$Matches[1]] = $Matches[2].Trim()
        }
    }

    return $argMap
}

function Resolve-FromImageRefs {
    param(
        [string]$DockerfilePath,
        [hashtable]$ArgMap
    )

    $refs = [System.Collections.Generic.List[string]]::new()

    foreach ($line in (Microsoft.PowerShell.Management\Get-Content -LiteralPath $DockerfilePath)) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^(?i:FROM)\s+([^\s]+)') {
            $ref = $Matches[1]

            foreach ($key in $ArgMap.Keys) {
                $value = [string]$ArgMap[$key]
                $ref = $ref.Replace("`$($key)", $value)
                $ref = $ref.Replace("`${$key}", $value)
            }

            $refs.Add($ref)
        }
    }

    return $refs
}

$argMap = Resolve-DockerfileArgDefaults -DockerfilePath $targetDockerfilePath
$fromRefs = Resolve-FromImageRefs -DockerfilePath $targetDockerfilePath -ArgMap $argMap

$internalBaseRef = $null
$internalBaseCatalogEntry = $null

if ($IncludeInternalBaseScan) {
    foreach ($ref in $fromRefs) {
        if ($ref -match '^lzocateli/([^:@]+)(?::([^@]+))?') {
            $candidateImageName = $Matches[1]
            $candidateEntry = $catalog.images | Where-Object { $_.imageName -eq $candidateImageName } | Select-Object -First 1
            if ($null -ne $candidateEntry) {
                $internalBaseRef = $ref
                $internalBaseCatalogEntry = $candidateEntry
                break
            }
        }
    }
}

Write-Host "[plan] image_id: $ImageId"
Write-Host "[plan] target: context=$($entry.context), dockerfile=$targetDockerfile, image_name=$targetImageName, platform=$targetPlatform"
if ($null -ne $internalBaseCatalogEntry) {
    Write-Host "[plan] internal-base: ref=$internalBaseRef, image_id=$($internalBaseCatalogEntry.id), context=$($internalBaseCatalogEntry.context)"
} else {
    Write-Host '[plan] internal-base: none'
}

if ($ResolveOnly) {
    exit 0
}

function Invoke-ScanScript {
    param(
        [string]$ContextPath,
        [string]$Dockerfile,
        [string]$ImageName,
        [string]$ImageTag,
        [string]$Platform,
        [switch]$SkipBuildRequested
    )

    $argList = @(
        '-NoLogo',
        '-NoProfile',
        '-File',
        $scanScriptPath,
        '-ContextPath',
        $ContextPath,
        '-Dockerfile',
        $Dockerfile,
        '-ImageName',
        $ImageName,
        '-ImageTag',
        $ImageTag,
        '-Platform',
        $Platform,
        '-Severity',
        $Severity,
        '-IgnoreUnfixed',
        $IgnoreUnfixed,
        '-GateCritical',
        $GateCritical,
        '-Timeout',
        $Timeout,
        '-TrivyImage',
        $TrivyImage,
        '-OutputDir',
        $OutputDir,
        '-CacheDir',
        $CacheDir,
        '-DbCachePolicy',
        $DbCachePolicy
    )

    if ($SkipBuildRequested) {
        $argList += '-SkipBuild'
    }

    & pwsh @argList | Out-Host
    $exitCode = $LASTEXITCODE
    return $exitCode
}

if ($null -ne $internalBaseCatalogEntry) {
    $basePlatform = if ($null -ne $internalBaseCatalogEntry.scanPlatform -and $internalBaseCatalogEntry.scanPlatform) { [string]$internalBaseCatalogEntry.scanPlatform } else { [string]$internalBaseCatalogEntry.platforms[0] }
    $baseContext = Join-Path -Path $repoRoot -ChildPath $internalBaseCatalogEntry.context

    $baseTagSuffix = ($ImageTag -replace '[^A-Za-z0-9_.-]', '-')
    $baseLocalTag = "base-$($internalBaseCatalogEntry.imageName)-$baseTagSuffix"

    Write-Host "[base] iniciando scan da base interna: $($internalBaseCatalogEntry.id)"
    $baseExit = Invoke-ScanScript `
        -ContextPath $baseContext `
        -Dockerfile ([string]$internalBaseCatalogEntry.dockerfile) `
        -ImageName ([string]$internalBaseCatalogEntry.imageName) `
        -ImageTag $baseLocalTag `
        -Platform $basePlatform `
        -SkipBuildRequested:$SkipBuild

    if ($baseExit -ne 0) {
        Write-Error "Falha no scan da base interna: $($internalBaseCatalogEntry.id). Corrija a base antes da imagem filha."
        exit $baseExit
    }
}

Write-Host '[target] iniciando scan da imagem alvo...'
$targetExit = Invoke-ScanScript `
    -ContextPath $targetContext `
    -Dockerfile $targetDockerfile `
    -ImageName $targetImageName `
    -ImageTag $ImageTag `
    -Platform $targetPlatform `
    -SkipBuildRequested:$SkipBuild

if ($targetExit -ne 0) {
    Write-Error "Falha no scan da imagem alvo: $ImageId"
    exit $targetExit
}

Write-Host "[ok] scan por id concluido: $ImageId"
exit 0
