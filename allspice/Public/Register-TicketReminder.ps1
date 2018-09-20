function Register-TicketReminder {
	Param(
		[Parameter(Mandatory)]
		[array]$TicketReminderRequest
	)

	$TicketReminderEmails = New-TicketReminderEmail -TicketReminderRequest $TicketReminderRequest
	$now = [datetime]::Now
	$TicketReminderEmails | ?{$_.ReminderTime -gt $now} | %{
		$UniqueString = $_.ReminderTime.ToFileTime()
		$ExistingJob = Get-ScheduledJob -name $UniqueString -ErrorAction SilentlyContinue

		if (-not $ExistingJob) {
			$ScheduledJob = @{
				Name = $UniqueString
				Trigger = New-JobTrigger -Once -At $_.ReminderTime
				ScheduledJobOption = New-ScheduledJobOption -MultipleInstancePolicy StopExisting -RequireNetwork -WakeToRun
				ScriptBlock = [ScriptBlock]::Create("`$Email = $($_.EmailObject | ConvertTo-Metadata);Send-NewMailMessage @Email -Credential (Get-StoredCredential -CredName Admin);Unregister-ScheduledJob -Name '$UniqueString'")
				Credential = Get-StoredCredential -CredName Admin
			}
			Write-Information -MessageData "Registering Notification Job $UniqueString" -InformationAction Continue
			Register-ScheduledJob @ScheduledJob
			$RegistrationNotification = $_.EmailObject.Clone()
			$RegistrationNotification.Subject = -join('[Registration]',$RegistrationNotification.Subject)
			$RegistrationNotification.body = "You are now registered to receive a reminder about this ticket at $($_.ReminderTime.ToString('G'))"
			Send-NewMailMessage @RegistrationNotification -Credential (Get-StoredCredential -CredName Admin)
		} else {
			Write-Information -MessageData "Notification Job $UniqueString already exists" -InformationAction Continue
		}
	}
}