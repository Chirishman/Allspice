function Get-SpiceworksTicketPage {
    Param(
        [Parameter(Mandatory)]
        [SpiceworksSession]$Session,
        [Parameter(Mandatory)]
        [ref]$Count,
		[Parameter()]
		[ValidateSet('open','closed','waiting')]
        [String]$State = 'open'
    )

    if (-not $WebSession) {
		$WebSession = Initialize-SpiceworksConnection -uri (-join($Uri.GetLeftPart(1),'/pro_users')) -Credential $Credential
    }

    (Invoke-WebRequest -Uri (-join($Uri.GetLeftPart(1),"/api/tickets.json?filter=",$State,"&page=",$count.Value)) -WebSession $WebSession).Content | ConvertFrom-Json
	$count.value++
}