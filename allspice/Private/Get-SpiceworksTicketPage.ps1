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

    if (-not ($Session.State -eq 'Connected')) {
		$Session.Connect()
    }

    (Invoke-WebRequest -Uri ($Session.TicketQueryUri -f @($State,$count.Value)) -WebSession $Session.WebSession).Content | ConvertFrom-Json
	$count.value++
}