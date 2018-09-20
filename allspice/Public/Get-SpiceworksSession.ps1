function Get-SpiceworksSession {
    Param(
        [Parameter()]
        [int]$id
    )
    $Global:SpiceworksSessions | ?{$_.id -match $id}
}