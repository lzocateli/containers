<#
.SYNOPSIS
    Round-trips a message on a queue, or a topic/subscription, against the running emulator.

.DESCRIPTION
    Thin wrapper around tools/sb-smoke (a .NET console app). Entity names are always supplied by the
    caller — this script has no knowledge of any particular topology.
#>
[CmdletBinding(DefaultParameterSetName = 'Topic')]
param(
    [Parameter(ParameterSetName = 'Queue', Mandatory)]
    [string]$Queue,

    [Parameter(ParameterSetName = 'Topic', Mandatory)]
    [string]$Topic,

    [Parameter(ParameterSetName = 'Topic', Mandatory)]
    [string]$Subscription,

    [string]$EmulatorHost = 'localhost',
    [int]$HttpPort = 5300
)

$ErrorActionPreference = 'Stop'

$toolDir = Join-Path $PSScriptRoot 'tools/sb-smoke'
$env:EMULATOR_HOST = $EmulatorHost
$env:EMULATOR_HTTP_PORT = $HttpPort

$runArgs = @('run', '--project', $toolDir, '-c', 'Release', '--')
if ($PSCmdlet.ParameterSetName -eq 'Queue') {
    $runArgs += @('--queue', $Queue)
}
else {
    $runArgs += @('--topic', $Topic, '--subscription', $Subscription)
}

dotnet @runArgs
exit $LASTEXITCODE
