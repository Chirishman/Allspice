function Get-SpiceworksSession {
    Param(
        [Parameter()]
        [int]$id
    )
    $Script:SpiceworksSessions | ?{$_.id -match $id}
}