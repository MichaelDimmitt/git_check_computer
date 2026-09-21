#Requires -Version 7.0
<#
.SYNOPSIS
    Runs PSScriptAnalyzer for the pre-commit hook and prints findings in a
    compact, editor clickable format.
.NOTES
    Exits 97 when PSScriptAnalyzer is not installed, which the hook treats as
    a skip rather than a failure.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $Path,
    [string] $StripPrefix,
    [string] $Settings
)

if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) { exit 97 }

Import-Module PSScriptAnalyzer -ErrorAction Stop

$arguments = @{
    Path     = $Path
    Recurse  = $true
    Severity = @('ParseError', 'Error', 'Warning')
}
if ($Settings -and (Test-Path -LiteralPath $Settings)) { $arguments['Settings'] = $Settings }

$results = @(Invoke-ScriptAnalyzer @arguments)
if ($results.Count -eq 0) { exit 0 }

foreach ($result in $results) {
    $file = $result.ScriptPath
    if ($StripPrefix -and $file.StartsWith($StripPrefix)) {
        $file = $file.Substring($StripPrefix.Length).TrimStart([char]'/', [char]'\')
    }
    '{0}:{1}:{2}: {3}: {4} [{5}]' -f
        $file, $result.Line, $result.Column,
        $result.Severity.ToString().ToLower(), $result.Message, $result.RuleName
}

exit 1
