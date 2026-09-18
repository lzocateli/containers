<#
.SYNOPSIS
    Stops the local Azure Service Bus emulator stack.

.DESCRIPTION
    `-Fresh` also drops the SQL volume, forcing a clean topology rebuild from Config.json on the next
    `sb-up.ps1` run (the emulator persists neither messages nor entities across recreation anyway).
#>
[CmdletBinding()]
param(
    [string]$ProjectName = 'sb-emulator',
    [switch]$Fresh
)

$ErrorActionPreference = 'Stop'

# Defaults below only need to satisfy compose-file interpolation for `down` — they do not affect
# which containers get stopped/removed, since `down` identifies them by project name/labels.
if (-not $env:SB_IMAGE) { $env:SB_IMAGE = 'mcr.microsoft.com/azure-messaging/servicebus-emulator:latest' }
if (-not $env:SB_SQL_IMAGE) { $env:SB_SQL_IMAGE = 'mcr.microsoft.com/azure-sql-edge:latest' }
if (-not $env:SB_CONFIG_PATH) { $env:SB_CONFIG_PATH = (Join-Path $PSScriptRoot 'Config.default.json') }
if (-not $env:SB_AMQP_PORT) { $env:SB_AMQP_PORT = '5672' }
if (-not $env:SB_HTTP_PORT) { $env:SB_HTTP_PORT = '5300' }
if (-not $env:MSSQL_SA_PASSWORD) { $env:MSSQL_SA_PASSWORD = 'unused-for-down' }
if (-not $env:ACCEPT_EULA) { $env:ACCEPT_EULA = 'N' }

Push-Location $PSScriptRoot
try {
    if ($Fresh) {
        Write-Host "Stopping stack '$ProjectName' and removing volumes (-Fresh)..."
        docker compose -p $ProjectName down -v
    }
    else {
        Write-Host "Stopping stack '$ProjectName'..."
        docker compose -p $ProjectName down
    }
}
finally {
    Pop-Location
}
