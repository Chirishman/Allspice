function Get-SpiceworksTicket {
    Param(
        [Parameter(Mandatory)]
        [SpiceworksSession]$Session,
		[Alias("id")]
		[Parameter(ValueFromPipelineByPropertyName)]
        [int[]]$TicketNumber
    )

	if (-not $Session.State = 'Connected') {
		$Session.Connect()
    }

    $TicketNumber | ForEach-Object {
        (Invoke-WebRequest -Uri ($Session.TicketDetailUri -f $_) -WebSession $Session.WebSession).Content | ConvertFrom-Json;
    }
}