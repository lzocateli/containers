<#
.SYNOPSIS
Configura governança de repositório no GitHub usando gh CLI.

.DESCRIPTION
Aplica proteções para branch principal e governança de workflows:
1) Define proteção de branch com PR obrigatório, review de CODEOWNERS e sem bypass.
2) Define variável de repositório para ator autorizado a workflow_dispatch.
3) Cria/atualiza environment protegido com reviewer obrigatório.

.PARAMETER RepoOwner
Owner do repositório no GitHub.

.PARAMETER RepoName
Nome do repositório no GitHub.

.PARAMETER BranchName
Branch protegida.
Padrao: main

.PARAMETER AuthorizedActor
Login GitHub autorizado para disparo manual de workflows.
Padrao: lzocateli

.PARAMETER EnvironmentName
Environment protegido para jobs sensiveis.
Padrao: container-release

.PARAMETER RequireLinearHistory
Exige historico linear na branch protegida.
Padrao: true

.PARAMETER DryRun
Mostra as operacoes sem alterar configuracoes remotas.

.PARAMETER Help
Exibe ajuda.

.PARAMETER RemainingArgs
Argumentos adicionais para compatibilidade com --help literal.

.EXAMPLE
tools/scripts/setup-github-governance.ps1 --help

.EXAMPLE
tools/scripts/setup-github-governance.ps1 -RepoOwner lzocateli -RepoName containers

.EXAMPLE
tools/scripts/setup-github-governance.ps1 -RepoOwner lzocateli -RepoName containers -AuthorizedActor lzocateli -DryRun

.INPUTS
None.

.OUTPUTS
Resumo das configuracoes aplicadas e codigos de saida.

.NOTES
Dependencias minimas:
- PowerShell 7+
- gh CLI autenticado com permissao administrativa no repositório alvo

Referencias:
- .github/AUTOMATION.md
- tools/scripts/setup-github-governance.ps1 --help

.LINK
https://cli.github.com/manual/gh_api
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$RepoOwner,

    [Parameter()]
    [string]$RepoName,

    [Parameter()]
    [string]$BranchName = 'main',

    [Parameter()]
    [string]$AuthorizedActor = 'lzocateli',

    [Parameter()]
    [string]$EnvironmentName = 'container-release',

    [Parameter()]
    [bool]$RequireLinearHistory = $true,

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
setup-github-governance.ps1

Finalidade:
- Configurar branch protection para main (ou branch alvo), exigindo PR com aprovacao de CODEOWNERS.
- Configurar variavel AUTHORIZED_WORKFLOW_DISPATCH_ACTOR no repositorio.
- Configurar environment protegido com reviewer obrigatorio.

Dependencias minimas:
- PowerShell 7+
- gh CLI autenticado com permissao de administracao no repo alvo

Uso:
  tools/scripts/setup-github-governance.ps1 -RepoOwner <owner> -RepoName <repo> [opcoes]

Opcoes principais:
  -RepoOwner <owner>          Owner GitHub (obrigatorio)
  -RepoName <repo>            Repositorio GitHub (obrigatorio)
  -BranchName <branch>        Branch protegida (padrao: main)
  -AuthorizedActor <login>    Ator autorizado para workflow_dispatch (padrao: lzocateli)
  -EnvironmentName <name>     Environment protegido (padrao: container-release)
  -RequireLinearHistory <b>   Exigir historico linear (padrao: true)
  -DryRun                     Exibe operacoes sem aplicar
  --help                      Exibe esta ajuda

Exemplos:
  tools/scripts/setup-github-governance.ps1 --help
  tools/scripts/setup-github-governance.ps1 -RepoOwner lzocateli -RepoName containers
  tools/scripts/setup-github-governance.ps1 -RepoOwner lzocateli -RepoName containers -DryRun
'@ | Write-Host
}

function Assert-CommandExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (-not (Get-Command -Name $Name -ErrorAction SilentlyContinue)) {
        throw "Comando obrigatorio nao encontrado: $Name"
    }
}

function Invoke-GhCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    if (Get-Command -Name 'GithubCli' -ErrorAction SilentlyContinue) {
        & GithubCli @Arguments
        return
    }

    & gh @Arguments
}

function Invoke-GhWithInput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputText,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    # GithubCli runs gh inside Docker (mounts CWD as /workspace).
    # PowerShell pipeline stdin does not cross the Docker boundary, so write
    # the payload to a temp file and replace '--input -' with the mounted path.
    if (Get-Command -Name 'GithubCli' -ErrorAction SilentlyContinue) {
        $tempFile = Join-Path (Get-Location) '.gh-input-temp.json'
        try {
            [System.IO.File]::WriteAllText($tempFile, $InputText, [System.Text.UTF8Encoding]::new($false))
            $fixedArgs = [System.Collections.Generic.List[string]]::new()
            for ($i = 0; $i -lt $Arguments.Count; $i++) {
                if ($Arguments[$i] -eq '--input' -and ($i + 1) -lt $Arguments.Count -and $Arguments[$i + 1] -eq '-') {
                    $fixedArgs.Add('--input')
                    $fixedArgs.Add('/workspace/.gh-input-temp.json')
                    $i++
                } else {
                    $fixedArgs.Add($Arguments[$i])
                }
            }
            Invoke-GhCommand -Arguments $fixedArgs.ToArray()
        } finally {
            if (Test-Path -LiteralPath $tempFile) { Remove-Item -LiteralPath $tempFile -Force }
        }
        return
    }

    $InputText | gh @Arguments
}

function Invoke-GhJson {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $output = Invoke-GhCommand -Arguments $Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao executar gh $($Arguments -join ' ')"
    }

    if ([string]::IsNullOrWhiteSpace($output)) {
        return $null
    }

    $text = ($output | Out-String).Trim()
    $text = [regex]::Replace($text, "`e\[[\d;]*[A-Za-z]", '')

    $startMatch = [regex]::Match($text, '[\{\[]')
    if (-not $startMatch.Success) {
        throw "Resposta do gh nao contem JSON parseavel. Saida: $text"
    }

    $startIndex = $startMatch.Index
    $lastObjectEnd = $text.LastIndexOf('}')
    $lastArrayEnd = $text.LastIndexOf(']')
    $endIndex = [Math]::Max($lastObjectEnd, $lastArrayEnd)

    if ($endIndex -lt $startIndex) {
        throw "Resposta do gh nao contem JSON completo. Saida: $text"
    }

    $jsonText = $text.Substring($startIndex, ($endIndex - $startIndex + 1))
    return $jsonText | ConvertFrom-Json
}

function Invoke-GhRaw {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    Invoke-GhCommand -Arguments $Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao executar gh $($Arguments -join ' ')"
    }
}

if ($Help -or ($RemainingArgs -contains '--help') -or $RepoOwner -eq '--help' -or $RepoName -eq '--help') {
    Show-Usage
    exit 0
}

if ([string]::IsNullOrWhiteSpace($RepoOwner) -or [string]::IsNullOrWhiteSpace($RepoName)) {
    Write-Error 'Parametros obrigatorios ausentes: -RepoOwner e -RepoName. Use --help para exemplos.'
    exit 2
}

Assert-CommandExists -Name 'gh'

$repo = "$RepoOwner/$RepoName"

Write-Host "[info] Repositorio alvo: $repo"
Write-Host "[info] Branch protegida: $BranchName"
Write-Host "[info] Ator autorizado workflow_dispatch: $AuthorizedActor"
Write-Host "[info] Environment protegido: $EnvironmentName"
Write-Host "[info] DryRun: $($DryRun.IsPresent)"

$viewer = Invoke-GhJson -Arguments @('api', 'user')
Write-Host "[info] Autenticado no gh como: $($viewer.login)"

$branchEndpoint = "repos/$repo/branches/$BranchName"
$protectionEndpoint = "repos/$repo/branches/$BranchName/protection"
$repoVariableEndpoint = "repos/$repo/actions/variables/AUTHORIZED_WORKFLOW_DISPATCH_ACTOR"
$environmentEndpoint = "repos/$repo/environments/$EnvironmentName"

$null = Invoke-GhJson -Arguments @('api', $branchEndpoint)

$authorizedActorUser = Invoke-GhJson -Arguments @('api', "users/$AuthorizedActor")
$authorizedActorId = [int]$authorizedActorUser.id

$protectionBody = @{
    required_status_checks            = $null
    enforce_admins                    = $true
    required_pull_request_reviews     = @{
        # dismissal_restrictions and bypass_pull_request_allowances require
        # an organization repository; omit them for personal repos.
        dismiss_stale_reviews           = $true
        require_code_owner_reviews      = $true
        required_approving_review_count = 1
        require_last_push_approval      = $true
    }
    restrictions                      = $null
    required_linear_history           = $RequireLinearHistory
    allow_force_pushes                = $false
    allow_deletions                   = $false
    block_creations                   = $false
    required_conversation_resolution  = $true
    lock_branch                       = $false
    allow_fork_syncing                = $true
}

$environmentBody = @{
    wait_timer = 0
    prevent_self_review = $true
    reviewers = @(
        @{
            type = 'User'
            id = $authorizedActorId
        }
    )
    deployment_branch_policy = @{
        protected_branches = $true
        custom_branch_policies = $false
    }
}

if ($DryRun.IsPresent) {
    Write-Host '[dry-run] Operacao 1: aplicar branch protection'
    $protectionBody | ConvertTo-Json -Depth 20 | Write-Host

    Write-Host '[dry-run] Operacao 2: definir variavel AUTHORIZED_WORKFLOW_DISPATCH_ACTOR'
    (@{ name = 'AUTHORIZED_WORKFLOW_DISPATCH_ACTOR'; value = $AuthorizedActor } | ConvertTo-Json) | Write-Host

    Write-Host '[dry-run] Operacao 3: configurar environment protegido'
    $environmentBody | ConvertTo-Json -Depth 20 | Write-Host

    Write-Host '[dry-run] Nenhuma alteracao foi aplicada.'
    exit 0
}

Write-Host '[apply] Aplicando branch protection...'
$protectionJson = $protectionBody | ConvertTo-Json -Depth 20
Invoke-GhWithInput -InputText $protectionJson -Arguments @('api', '--method', 'PUT', $protectionEndpoint, '--input', '-') | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'Falha ao aplicar branch protection.'
}

Write-Host '[apply] Definindo variavel AUTHORIZED_WORKFLOW_DISPATCH_ACTOR...'
try {
    Invoke-GhRaw -Arguments @('api', '--method', 'PATCH', $repoVariableEndpoint, '-f', "name=AUTHORIZED_WORKFLOW_DISPATCH_ACTOR", '-f', "value=$AuthorizedActor")
}
catch {
    Invoke-GhRaw -Arguments @('api', '--method', 'POST', "repos/$repo/actions/variables", '-f', 'name=AUTHORIZED_WORKFLOW_DISPATCH_ACTOR', '-f', "value=$AuthorizedActor")
}

Write-Host '[apply] Configurando environment protegido...'
$environmentJson = $environmentBody | ConvertTo-Json -Depth 20
Invoke-GhWithInput -InputText $environmentJson -Arguments @('api', '--method', 'PUT', $environmentEndpoint, '--input', '-') | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'Falha ao configurar environment protegido.'
}

Write-Host '[ok] Governanca aplicada com sucesso.'
Write-Host "[ok] Repositorio: $repo"
Write-Host "[ok] Branch protegida: $BranchName"
Write-Host "[ok] Ator autorizado workflow_dispatch: $AuthorizedActor"
Write-Host "[ok] Environment protegido: $EnvironmentName"
