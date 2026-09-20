<#
.SYNOPSIS
    Starts the reusable local Azure Service Bus emulator stack (emulator + SQL backing store).

.DESCRIPTION
    Resolves parameters, gates on EULA acceptance and a generated SQL SA password (both persisted to
    User-scope environment variables, never written to disk in this repo), validates the mounted
    config as JSON, starts the stack via `docker compose`, polls the health endpoint, and prints the
    two connection strings (data-plane and admin-plane) on success.

    No `.env` file is used anywhere in this stack; every value flows through the process environment
    of this script into `docker compose`.
#>
[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'Config.default.json'),
    [string]$ProjectName = 'sb-emulator',
    [string]$Image,
    [switch]$UseMcr,
    [string]$SqlImage = 'mcr.microsoft.com/azure-sql-edge:latest',
    [int]$AmqpPort = 5672,
    [int]$HttpPort = 5300,
    [switch]$Fresh,
    [switch]$AcceptEula,
    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = 'Stop'

# Resolved via: docker inspect --format '{{index .RepoDigests 0}}' <image>:latest
$McrPinnedImage = 'mcr.microsoft.com/azure-messaging/servicebus-emulator@sha256:5a96d893b245031740f7d46e0fe5ff282d24b78c4b7d761dd57590f3f010a9b3'

function New-EmulatorSaPassword {
    # 24 chars, all four character categories guaranteed by construction (not left to chance),
    # excluding characters that are shell/YAML/Compose-interpolation hazards ($ ` " ' \ ; %).
    param([int]$Length = 24)

    $categories = @(
        , [char[]](65..90 | ForEach-Object { [char]$_ })      # A-Z
        , [char[]](97..122 | ForEach-Object { [char]$_ })     # a-z
        , [char[]](48..57 | ForEach-Object { [char]$_ })      # 0-9
        , [char[]]@('!', '#', '*', '+', '-', '.', '?', '@', '^', '_')
    )

    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        function Get-RandomIndex([int]$Max) {
            $buffer = [byte[]]::new(4)
            $rng.GetBytes($buffer)
            return [Math]::Abs([BitConverter]::ToInt32($buffer, 0)) % $Max
        }

        $chars = [System.Collections.Generic.List[char]]::new()
        foreach ($category in $categories) {
            $chars.Add($category[(Get-RandomIndex $category.Length)])
        }

        $allChars = @($categories | ForEach-Object { $_ })
        for ($i = $chars.Count; $i -lt $Length; $i++) {
            $chars.Add($allChars[(Get-RandomIndex $allChars.Length)])
        }

        for ($i = $chars.Count - 1; $i -gt 0; $i--) {
            $j = Get-RandomIndex ($i + 1)
            $tmp = $chars[$i]; $chars[$i] = $chars[$j]; $chars[$j] = $tmp
        }

        return -join $chars
    }
    finally {
        $rng.Dispose()
    }
}

# ---- Resolve image (K2) ----
if ($UseMcr) {
    $resolvedImage = $McrPinnedImage
}
elseif ($Image) {
    $resolvedImage = $Image
}
else {
    Write-Error "No image resolved. The JFrog image (infra/servicebus-emulator) is not published yet (see readme.md). Re-run with -UseMcr, or pass -Image explicitly once it is published."
    Write-Error "No image resolved. The JFrog image (infra/azure-servicebus) is not published yet (see README.md). Re-run with -UseMcr, or pass -Image explicitly once it is published."
    exit 1
}

# ---- EULA gate (K7) ----
$eulaVarName = 'SB_EMULATOR_ACCEPT_EULA'
$eulaAccepted = [Environment]::GetEnvironmentVariable($eulaVarName, 'User')
if ($AcceptEula) {
    [Environment]::SetEnvironmentVariable($eulaVarName, 'true', 'User')
    $eulaAccepted = 'true'
}
if ($eulaAccepted -ne 'true') {
    Write-Error "Azure Service Bus Emulator EULA not accepted. Read azure-service-bus-emulator-installer/EMULATOR_EULA.txt, then re-run with -AcceptEula. This is a one-time gate; the choice is remembered in the '$eulaVarName' user environment variable."
    exit 1
}

# ---- Password gate (K3) ----
$pwdVarName = 'SB_EMULATOR_SA_PASSWORD'
$saPassword = [Environment]::GetEnvironmentVariable($pwdVarName, 'User')
if (-not $saPassword) {
    Write-Host "Generating a local SQL SA password (stored only in the '$pwdVarName' user environment variable; it is never written to disk in this repo)..."
    $saPassword = New-EmulatorSaPassword
    [Environment]::SetEnvironmentVariable($pwdVarName, $saPassword, 'User')
    Write-Host "$pwdVarName set ($($saPassword.Length) chars)."
}
else {
    Write-Host "$pwdVarName already set ($($saPassword.Length) chars); reusing."
}

# ---- Config validation (K8) ----
$resolvedConfigPath = (Resolve-Path $ConfigPath -ErrorAction Stop).ProviderPath
try {
    Get-Content $resolvedConfigPath -Raw | ConvertFrom-Json | Out-Null
}
catch {
    Write-Error "Config file '$resolvedConfigPath' is not valid JSON: $($_.Exception.Message)"
    exit 1
}

# ---- Compose invocation ----
$env:COMPOSE_PROJECT_NAME = $ProjectName
$env:SB_IMAGE = $resolvedImage
$env:SB_SQL_IMAGE = $SqlImage
$env:SB_CONFIG_PATH = $resolvedConfigPath
$env:SB_AMQP_PORT = $AmqpPort
$env:SB_HTTP_PORT = $HttpPort
$env:ACCEPT_EULA = 'Y'
$env:MSSQL_SA_PASSWORD = $saPassword

Push-Location $PSScriptRoot
try {
    if ($Fresh) {
        Write-Host "Tearing down any existing '$ProjectName' stack and volumes (-Fresh)..."
        docker compose -p $ProjectName down -v 2>$null
    }

    Write-Host "Starting stack '$ProjectName' (image: $resolvedImage, sql: $SqlImage)..."
    docker compose -p $ProjectName up -d
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose up failed with exit code $LASTEXITCODE"
    }

    $healthUrl = "http://127.0.0.1:$HttpPort/health"
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $healthy = $false
    Write-Host "Waiting for $healthUrl to report healthy (timeout: ${TimeoutSeconds}s)..."
    while ((Get-Date) -lt $deadline) {
        try {
            $response = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 5
            if ($response.status -eq 'healthy') {
                $healthy = $true
                break
            }
        }
        catch {
            # Not ready yet; keep polling.
        }
        Start-Sleep -Seconds 2
    }

    if (-not $healthy) {
        Write-Error "Emulator did not report healthy within $TimeoutSeconds seconds. Recent logs:"
        docker compose -p $ProjectName logs --tail 50
        exit 1
    }

    Write-Host ""
    Write-Host "Emulator is healthy." -ForegroundColor Green
    Write-Host ""
    Write-Host "Data-plane connection string (send/receive):"
    Write-Host "  Endpoint=sb://localhost;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;"
    Write-Host ""
    Write-Host "Admin-plane connection string (ServiceBusAdministrationClient, port required):"
    Write-Host "  Endpoint=sb://localhost:$HttpPort;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;"
}
finally {
    Pop-Location
    Remove-Item Env:\MSSQL_SA_PASSWORD -ErrorAction SilentlyContinue
}
