function Get-SpiceworksTicketPage {
    Param(
        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
        [Parameter(Mandatory)]
        [Uri]$Uri,
		[Parameter(Mandatory)]
        [ref]$Count,
		[Parameter()]
		[ValidateSet('open','closed','waiting')]
        [String]$State = 'open',
        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

    if (-not $WebSession) {
		$WebSession = Initialize-SpiceworksConnection -uri (-join($Uri.GetLeftPart(1),'/pro_users')) -Credential $Credential
    }

    (Invoke-WebRequest -Uri (-join($Uri.GetLeftPart(1),"/api/tickets.json?filter=",$State,"&page=",$count.Value)) -WebSession $WebSession).Content | ConvertFrom-Json
	$count.value++
}