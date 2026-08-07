[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string[]] $Path = @([Environment]::GetFolderPath('UserProfile')),

    [switch] $Update,
    [switch] $Fetch,

    [string[]] $ExcludeDirectoryName = @(
        '$Recycle.Bin', 'System Volume Information', 'Recovery', 'Windows',
        'Program Files', 'Program Files (x86)', 'ProgramData', 'AppData',
        '.codex', 'node_modules', '.venv', 'venv'
    ),

    [ValidateNotNullOrEmpty()]
    [string] $PersistPath = (Join-Path ([Environment]::GetFolderPath('UserProfile')) '.git-check-computer.persist.txt')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)][string] $Repository,
        [Parameter(Mandatory = $true)][string[]] $Arguments
    )

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& git -C $Repository @Arguments 2>$null)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    [pscustomobject]@{ ExitCode = $exitCode; Output = $output }
}

function Find-GitRepository {
    param([Parameter(Mandatory = $true)][string[]] $Root)

    $pending = [Collections.Generic.Stack[string]]::new()
    foreach ($item in $Root) {
        $pending.Push((Resolve-Path -LiteralPath $item).Path)
    }

    while ($pending.Count -gt 0) {
        $directory = $pending.Pop()
        if (Test-Path -LiteralPath (Join-Path $directory '.git')) {
            $directory
            continue
        }

        try {
            $children = @(Get-ChildItem -LiteralPath $directory -Directory -Force -ErrorAction Stop)
        }
        catch [System.UnauthorizedAccessException] {
            Write-Verbose "Skipping inaccessible directory: $directory"
            continue
        }
        catch [System.IO.IOException] {
            Write-Verbose "Skipping unreadable directory: $directory"
            continue
        }

        foreach ($child in $children) {
            if (
                ($child.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0 -and
                $child.Name -notin $ExcludeDirectoryName
            ) {
                $pending.Push($child.FullName)
            }
        }
    }
}

function Get-RepositoryState {
    param([Parameter(Mandatory = $true)][string] $Repository)

    if ($Fetch) {
        $fetchResult = Invoke-Git -Repository $Repository -Arguments @('fetch', '--quiet')
        if ($fetchResult.ExitCode -ne 0) { Write-Warning "Fetch failed: $Repository" }
    }

    $statusResult = Invoke-Git -Repository $Repository -Arguments @('status', '--porcelain=v1')
    if ($statusResult.ExitCode -ne 0) {
        return [pscustomobject]@{
            Repository = $Repository; Branch = $null; Untracked = 0; Unstaged = 0; Staged = 0
            Ahead = $null; Behind = $null; Upstream = $null; Issue = 'Unable to read repository status'
        }
    }

    $untracked = 0
    $unstaged = 0
    $staged = 0
    foreach ($line in $statusResult.Output) {
        if ($line.Length -lt 2) { continue }
        $indexState = $line.Substring(0, 1)
        $workTreeState = $line.Substring(1, 1)
        if ($indexState -eq '?' -and $workTreeState -eq '?') {
            $untracked++
            continue
        }
        if ($indexState -ne ' ') { $staged++ }
        if ($workTreeState -ne ' ') { $unstaged++ }
    }

    $branchResult = Invoke-Git -Repository $Repository -Arguments @('branch', '--show-current')
    $branch = if ($branchResult.ExitCode -eq 0 -and $branchResult.Output.Count -gt 0) {
        [string] $branchResult.Output[0]
    } else { '(detached HEAD)' }

    $upstreamResult = Invoke-Git -Repository $Repository -Arguments @('rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{upstream}')
    $upstream = $null
    $ahead = $null
    $behind = $null
    $issue = $null

    if ($upstreamResult.ExitCode -eq 0 -and $upstreamResult.Output.Count -gt 0) {
        $upstream = [string] $upstreamResult.Output[0]
        $aheadResult = Invoke-Git -Repository $Repository -Arguments @('rev-list', '--count', '@{upstream}..HEAD')
        $behindResult = Invoke-Git -Repository $Repository -Arguments @('rev-list', '--count', 'HEAD..@{upstream}')
        if ($aheadResult.ExitCode -eq 0) { $ahead = [int] $aheadResult.Output[0] }
        if ($behindResult.ExitCode -eq 0) { $behind = [int] $behindResult.Output[0] }
    } else {
        $issue = 'No upstream branch'
    }

    [pscustomobject]@{
        Repository = $Repository; Branch = $branch; Untracked = $untracked; Unstaged = $unstaged; Staged = $staged
        Ahead = $ahead; Behind = $behind; Upstream = $upstream; Issue = $issue
    }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git was not found on PATH.' }

$pathWasSpecified = $PSBoundParameters.ContainsKey('Path')
if ($Update -or $pathWasSpecified -or -not (Test-Path -LiteralPath $PersistPath)) {
    Write-Host "Searching for Git repositories under: $($Path -join ', ')"
    $repositories = @(Find-GitRepository -Root $Path | Sort-Object -Unique)
    $persistParent = Split-Path -Parent $PersistPath
    if ($persistParent -and -not (Test-Path -LiteralPath $persistParent)) {
        New-Item -ItemType Directory -Path $persistParent -Force | Out-Null
    }
    Set-Content -LiteralPath $PersistPath -Value $repositories -Encoding UTF8
    Write-Host "Found $($repositories.Count) repositories. Cache: $PersistPath"
} else {
    $repositories = @(Get-Content -LiteralPath $PersistPath | Where-Object { $_ -and (Test-Path -LiteralPath $_) })
    Write-Host "Using $($repositories.Count) cached repositories from: $PersistPath"
}

$states = @($repositories | ForEach-Object { Get-RepositoryState -Repository $_ })
$needsAction = @($states | Where-Object {
    $_.Untracked -gt 0 -or $_.Unstaged -gt 0 -or $_.Staged -gt 0 -or
    $_.Ahead -gt 0 -or $_.Behind -gt 0 -or $_.Issue
})

if ($needsAction.Count -eq 0) {
    Write-Host 'All repositories are clean and synchronized with their configured upstream.' -ForegroundColor Green
    exit 0
}

$needsAction | Format-Table Repository, Branch, Untracked, Unstaged, Staged, Ahead, Behind, Upstream, Issue -AutoSize
Write-Host "$($needsAction.Count) of $($states.Count) repositories need attention." -ForegroundColor Yellow
exit 1
