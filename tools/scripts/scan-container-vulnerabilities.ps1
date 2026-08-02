<#
.SYNOPSIS
Executa scan local de vulnerabilidades em imagem de container com Trivy via Docker.

.DESCRIPTION
Este script reproduz localmente o fluxo de seguranca usado nos workflows do repositorio:
1) Build local da imagem (opcional)
2) Gera relatorio JSON com severidade configuravel
3) Aplica gate de vulnerabilidades CRITICAL corrigiveis

A execucao usa o Trivy em container (aquasec/trivy) e nao requer instalacao local do binario.

.PARAMETER ContextPath
Pasta da imagem relativa ou absoluta (ex.: k6, node, nginx).

.PARAMETER Dockerfile
Nome do Dockerfile dentro de ContextPath.
Padrao: Dockerfile

.PARAMETER ImageName
Nome local para a imagem no scan.
Padrao: nome da pasta de ContextPath

.PARAMETER ImageTag
Tag local para build e scan.
Padrao: local-scan

.PARAMETER Platform
Plataforma usada no build local.
Padrao: linux/amd64

.PARAMETER Severity
Severidades para o relatorio JSON.
Padrao: HIGH,CRITICAL

.PARAMETER IgnoreUnfixed
Quando true, ignora vulnerabilidades sem correcao disponivel.
Padrao: true

.PARAMETER GateCritical
Quando true, falha o script se houver vulnerabilidades CRITICAL corrigiveis.
Padrao: true

.PARAMETER Timeout
Timeout do Trivy para analise da imagem.
Padrao: 20m

.PARAMETER TrivyImage
Imagem do Trivy usada para scan.
Padrao: aquasec/trivy:0.72.0

.PARAMETER OutputDir
Diretorio local para TAR e relatorio JSON.
Padrao: artifacts/security-local

.PARAMETER CacheDir
Diretorio local para cache do banco do Trivy.
Padrao: artifacts/security-local/trivy-cache

.PARAMETER DbCachePolicy
Politica de atualizacao do cache de banco do Trivy.
- auto: usa cache local e permite atualizacao automatica quando necessario (padrao).
- reuse: reutiliza somente cache local, sem atualizar da internet.
- refresh: baixa/atualiza o banco primeiro e depois executa scan reutilizando cache.
Padrao: auto

.PARAMETER SkipBuild
Quando presente, usa imagem local existente sem rebuild.

.PARAMETER Help
Exibe ajuda completa.

.PARAMETER RemainingArgs
Argumentos adicionais para compatibilidade com --help literal.

.EXAMPLE
./tools/scripts/scan-container-vulnerabilities.ps1 --help

.EXAMPLE
./tools/scripts/scan-container-vulnerabilities.ps1 -ContextPath k6 -ImageTag 2.1.0-node24.15.0-bookworm

.EXAMPLE
./tools/scripts/scan-container-vulnerabilities.ps1 -ContextPath node -ImageTag 24.15.0-bookworm -Severity CRITICAL

.INPUTS
None.

.OUTPUTS
Arquivo JSON com o relatorio do Trivy e codigo de saida do gate de seguranca.

.NOTES
Dependencias minimas:
- PowerShell 7+
- Docker Engine / Docker Desktop com daemon ativo

Documentacao adicional:
- .github/AUTOMATION.md
- .github/workflows/publish-image.yml

.LINK
https://trivy.dev/docs/
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ContextPath,

    [Parameter()]
    [string]$Dockerfile = 'Dockerfile',

    [Parameter()]
    [string]$ImageName,

    [Parameter()]
    [string]$ImageTag = 'local-scan',

    [Parameter()]
    [string]$Platform = 'linux/amd64',

    [Parameter()]
    [string]$Severity = 'HIGH,CRITICAL',

    [Parameter()]
    [string]$IgnoreUnfixed = 'true',

    [Parameter()]
    [string]$GateCritical = 'true',

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

function ConvertTo-Boolean {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value,
        [Parameter(Mandatory = $true)]
        [string]$ParameterName
    )

    switch -Regex ($Value.Trim().ToLowerInvariant()) {
        '^(1|true|t|yes|y)$' { return $true }
        '^(0|false|f|no|n)$' { return $false }
        default {
            Write-Error "Valor invalido para -${ParameterName}: '$Value'. Use true/false."
            exit 2
        }
    }
}

function Show-Usage {
        @'
scan-container-vulnerabilities.ps1

Finalidade:
- Executar scan local de vulnerabilidades com Trivy (via Docker) para uma imagem.
- Reproduzir localmente o gate CRITICAL corrigivel do workflow.

Dependencias minimas:
- PowerShell 7+
- Docker ativo

Uso:
    ./tools/scripts/scan-container-vulnerabilities.ps1 -ContextPath <pasta-imagem> [opcoes]

Opcoes principais:
    -ContextPath <path>       Pasta da imagem (obrigatorio)
    -Dockerfile <name>        Nome do Dockerfile (padrao: Dockerfile)
    -ImageName <name>         Nome local da imagem (padrao: nome da pasta)
    -ImageTag <tag>           Tag local (padrao: local-scan)
    -Platform <platform>      Plataforma de build (padrao: linux/amd64)
    -Severity <list>          Severidades para relatorio JSON (padrao: HIGH,CRITICAL)
    -IgnoreUnfixed <bool>     Ignora vulnerabilidades sem fix (padrao: true)
    -GateCritical <bool>      Aplica gate para CRITICAL corrigivel (padrao: true)
    -Timeout <value>          Timeout do Trivy (padrao: 20m)
    -TrivyImage <ref>         Imagem Trivy (padrao: aquasec/trivy:0.72.0)
    -OutputDir <path>         Diretorio de saida (padrao: artifacts/security-local)
    -CacheDir <path>          Diretorio de cache do Trivy (padrao: artifacts/security-local/trivy-cache)
    -DbCachePolicy <mode>     Politica de cache: auto | reuse | refresh (padrao: auto)
    -SkipBuild                Nao executa build; usa imagem local existente
    --help                    Exibe esta ajuda

Exemplos:
    ./tools/scripts/scan-container-vulnerabilities.ps1 --help
    ./tools/scripts/scan-container-vulnerabilities.ps1 -ContextPath k6 -ImageTag 2.1.0-node24.15.0-bookworm
    ./tools/scripts/scan-container-vulnerabilities.ps1 -ContextPath node -ImageTag 24.15.0-bookworm -Severity CRITICAL

Referencias:
- .github/AUTOMATION.md
- .github/workflows/publish-image.yml
'@ | Write-Host
}

function Write-TrivyDbCacheStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolvedCacheDir
    )

    $metadataCandidates = @(
        (Join-Path -Path $ResolvedCacheDir -ChildPath 'db/metadata.json'),
        (Join-Path -Path $ResolvedCacheDir -ChildPath 'db/metadata.json.gz')
    )

    $metadataPath = $metadataCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    if ($null -eq $metadataPath) {
        Write-Host '[cache] metadata do DB nao encontrada no cache local (primeiro uso ou formato diferente).'
        return
    }

    try {
        if ($metadataPath.EndsWith('.gz')) {
            Write-Host "[cache] metadata compactada detectada: $metadataPath"
            Write-Host '[cache] use DbCachePolicy=refresh para forcar update e gerar metadata descompactada quando suportado.'
            return
        }

        $metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
        $updatedAt = if ($null -ne $metadata.UpdatedAt) { [string]$metadata.UpdatedAt } else { 'indisponivel' }
        $nextUpdate = if ($null -ne $metadata.NextUpdate) { [string]$metadata.NextUpdate } else { 'indisponivel' }
        $downloadedAt = if ($null -ne $metadata.DownloadedAt) { [string]$metadata.DownloadedAt } else { 'indisponivel' }

        Write-Host "[cache] db metadata path: $metadataPath"
        Write-Host "[cache] db UpdatedAt: $updatedAt"
        Write-Host "[cache] db NextUpdate: $nextUpdate"
        Write-Host "[cache] db DownloadedAt: $downloadedAt"
    } catch {
        Write-Host "[cache] nao foi possivel ler metadata do DB em: $metadataPath"
    }
}

if ($Help -or ($RemainingArgs -contains '--help') -or $ContextPath -eq '--help' -or $ContextPath -eq '-h') {
        Show-Usage
    exit 0
}

if ([string]::IsNullOrWhiteSpace($ContextPath)) {
    Write-Error 'Parametro obrigatorio ausente: -ContextPath. Use --help para exemplos.'
    exit 2
}

$ignoreUnfixedEnabled = ConvertTo-Boolean -Value $IgnoreUnfixed -ParameterName 'IgnoreUnfixed'
$gateCriticalEnabled = ConvertTo-Boolean -Value $GateCritical -ParameterName 'GateCritical'

$dockerCommand = Get-Command docker -ErrorAction SilentlyContinue
if ($null -eq $dockerCommand) {
    Write-Error 'Docker nao encontrado no PATH. Instale/ative Docker e tente novamente.'
    exit 3
}

if (-not (Test-Path -LiteralPath $ContextPath -PathType Container)) {
    Write-Error "ContextPath nao encontrado: $ContextPath"
    exit 4
}

$resolvedContextPath = (Resolve-Path -LiteralPath $ContextPath).Path
$resolvedDockerfilePath = Join-Path -Path $resolvedContextPath -ChildPath $Dockerfile

if (-not (Test-Path -LiteralPath $resolvedDockerfilePath -PathType Leaf)) {
    Write-Error "Dockerfile nao encontrado: $resolvedDockerfilePath"
    exit 5
}

if (-not (Test-Path -LiteralPath (Join-Path $resolvedContextPath '.gitignore') -PathType Leaf)) {
    Write-Warning "Nao foi encontrado .gitignore em $resolvedContextPath"
}

if (-not (Test-Path -LiteralPath (Join-Path $resolvedContextPath '.dockerignore') -PathType Leaf)) {
    Write-Warning "Nao foi encontrado .dockerignore em $resolvedContextPath"
}

if ([string]::IsNullOrWhiteSpace($ImageName)) {
    $ImageName = Split-Path -Path $resolvedContextPath -Leaf
}

$localImageRef = "local/${ImageName}:$ImageTag"

if (-not (Test-Path -LiteralPath $OutputDir -PathType Container)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}
$resolvedOutputDir = (Resolve-Path -LiteralPath $OutputDir).Path

if (-not (Test-Path -LiteralPath $CacheDir -PathType Container)) {
    New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
}
$resolvedCacheDir = (Resolve-Path -LiteralPath $CacheDir).Path

$safeTag = ($ImageTag -replace '[^A-Za-z0-9_.-]', '-')
$tarFileName = "$ImageName-$safeTag.tar"
$jsonFileName = "trivy-$ImageName-$safeTag.json"
$tarPath = Join-Path -Path $resolvedOutputDir -ChildPath $tarFileName
$jsonPath = Join-Path -Path $resolvedOutputDir -ChildPath $jsonFileName

Write-Host "[scan] contexto: $resolvedContextPath"
Write-Host "[scan] imagem local: $localImageRef"
Write-Host "[scan] output: $jsonPath"
Write-Host "[scan] cache trivy: $resolvedCacheDir"
Write-Host "[scan] politica cache db: $DbCachePolicy"

if (-not $SkipBuild) {
    Write-Host '[build] construindo imagem local...'
    & docker build --pull --platform $Platform --file $resolvedDockerfilePath --tag $localImageRef $resolvedContextPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Falha no build da imagem: $localImageRef"
        exit $LASTEXITCODE
    }
}

Write-Host '[pack] exportando imagem para TAR...'
if (Test-Path -LiteralPath $tarPath -PathType Leaf) {
    Remove-Item -LiteralPath $tarPath -Force
}
& docker save -o $tarPath $localImageRef
if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha ao exportar imagem para TAR: $tarPath"
    exit $LASTEXITCODE
}

$dockerMount = "${resolvedOutputDir}:/work"
$cacheMount = "${resolvedCacheDir}:/root/.cache/trivy"
$ignoreUnfixedArg = @()
if ($ignoreUnfixedEnabled) {
    $ignoreUnfixedArg = @('--ignore-unfixed')
}

$dbPolicyArgs = @()
if ($DbCachePolicy -eq 'reuse') {
    $dbPolicyArgs = @('--skip-db-update')
}

if ($DbCachePolicy -eq 'refresh') {
    Write-Host '[trivy] atualizando banco de vulnerabilidades no cache local...'
    & docker run --rm `
        -e TRIVY_DISABLE_VEX_NOTICE=true `
        -v $cacheMount `
        $TrivyImage image `
        --download-db-only

    if ($LASTEXITCODE -ne 0) {
        Write-Error 'Falha ao atualizar banco do Trivy no cache local.'
        exit $LASTEXITCODE
    }

    # Evita nova verificacao remota imediata apos refresh explicito.
    $dbPolicyArgs = @('--skip-db-update')
}

Write-Host '[trivy] gerando relatorio JSON...'
& docker run --rm `
    -e TRIVY_DISABLE_VEX_NOTICE=true `
    -v $dockerMount `
    -v $cacheMount `
    $TrivyImage image `
    --input "/work/$tarFileName" `
    --scanners vuln `
    --severity $Severity `
    --format json `
    --output "/work/$jsonFileName" `
    @ignoreUnfixedArg `
    @dbPolicyArgs `
    --timeout $Timeout

if ($LASTEXITCODE -ne 0) {
    Write-Error 'Falha ao gerar relatorio JSON do Trivy.'
    exit $LASTEXITCODE
}

if ($gateCriticalEnabled) {
    Write-Host '[trivy] aplicando gate CRITICAL corrigivel...'
    $report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
    $criticalFixable = @(
        $report.Results |
            ForEach-Object {
                $vulnerabilities = $_.PSObject.Properties['Vulnerabilities']
                if ($null -ne $vulnerabilities -and $null -ne $vulnerabilities.Value) {
                    $vulnerabilities.Value
                }
            } |
            Where-Object {
                $_.Severity -eq 'CRITICAL' -and
                -not [string]::IsNullOrWhiteSpace([string]$_.FixedVersion)
            }
    )
    if ($criticalFixable.Count -gt 0) {
        $criticalFixable |
            Select-Object VulnerabilityID, PkgName, InstalledVersion, FixedVersion |
            Format-Table -AutoSize |
            Out-Host
        Write-Error "Gate falhou: vulnerabilidades CRITICAL corrigiveis detectadas. Veja: $jsonPath"
        exit 1
    }
}

Write-TrivyDbCacheStatus -ResolvedCacheDir $resolvedCacheDir

Write-Host "[ok] scan concluido sem bloqueio. Relatorio: $jsonPath"
exit 0
