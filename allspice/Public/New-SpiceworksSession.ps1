function New-SpiceworksSession {
    Param(
        [Parameter(Mandatory)]
        [string]$Server,
        [Parameter(Mandatory)]
        [pscredential]$Credential,
        [switch]$UseHTTPS,
        [Nullable[int]]$Port
    )
    if (-not $Script:SpiceworksSessions){
        $Script:SpiceworksSessions = [System.Collections.ArrayList]::new()
    }
    
    $NewSession = [spiceworkssession]::new($server,$Credential,[bool]$UseHTTPS,[int]$Port)
    
    $NewSession.Connect()

    $NewSession
}