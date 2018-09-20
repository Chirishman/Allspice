function New-TicketReminderEmail {
    Param(
		[Parameter(Mandatory)]
        [array]$TicketReminderRequest,
		[Parameter(Mandatory)]
		[string]$From,
		[Parameter(Mandatory)]
		[string]$SmtpServer
    )

    $EmailTemplate = @{
        From = $From
        To = ''
        SmtpServer = $SmtpServer
        Subject = ''
        Body = "You have requested a reminder about this ticket on this day"
        UseSsl = $true
    }

    $TicketReminderRequest | %{
        $ThisID = $_.id
        $ThisSummary = $_.summary
        $_.NotificationDetails | select ReminderTime,@{N='EmailObject';E={
            $ThisEmail = $EmailTemplate.Clone()
            $ThisEmail.Subject = -join('[Reminder] Ticket: ',$ThisID,' - ',$ThisSummary)
            $ThisEmail.To = $_.ContactAddress
            $ThisEmail
        }}
    }
}