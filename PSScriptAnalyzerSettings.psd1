@{
    # Write-Host is deliberate in git_check_computer.ps1. It is a user facing
    # CLI report: the progress lines must not land on stdout beside the
    # Format-Table result, and the summary lines use -ForegroundColor, which
    # Write-Output cannot do. Since PowerShell 5.0 Write-Host writes to the
    # information stream, so it is capturable and redirectable anyway.
    ExcludeRules = @(
        'PSAvoidUsingWriteHost'
    )
}
