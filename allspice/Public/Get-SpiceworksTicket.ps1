function Get-SpiceworksTicket {
    Param(
        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
        [Parameter(Mandatory)]
        [Uri]$Uri,
		[Alias("id")]
		[Parameter(ValueFromPipelineByPropertyName)]
        [int[]]$TicketNumber,
        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

	if (-not $WebSession) {
		$WebSession = Initialize-SpiceworksConnection -uri (-join($Uri.GetLeftPart(1),'/pro_users')) -Credential $Credential
    }

    $TicketNumber | ForEach-Object {
        (Invoke-WebRequest -Uri (-join($Uri.GetLeftPart(1),"/api/tickets/",$_,".json")) -WebSession $WebSession).Content | ConvertFrom-Json;
    }
}