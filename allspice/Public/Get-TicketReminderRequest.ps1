function Get-TicketReminderRequest {
    Param(
        [Parameter(Mandatory)]
        [SpiceworksSession]$Session
    )

	$CommandPattern = '^\!remindme\ '
	$Units = @{
		d = {
			Write-Verbose -Message 'Adding $($ThisUnit[0]) Days'
			$TargetDate = $TargetDate.AddDays($ThisUnit[0])
		}
		m = {
			Write-Verbose -Message 'Adding $($ThisUnit[0]) Months'
			$TargetDate = $TargetDate.AddMonths($ThisUnit[0])
		}
		y = {
			Write-Verbose -Message 'Adding $($ThisUnit[0]) Years'
			$TargetDate = $TargetDate.AddYears($ThisUnit[0])
		}
	}

    $FilterComments = {($_.comments | Where-Object {$_.comment_type -eq 'note' -and $_.body -match $CommandPattern})}

    $SelectReminderInfo = @(
        'id',
        'created_at',
        'description',
        'due_at',
        'summary',
        'updated_at',
        'CreatorName',
		'AssigneeName',
        'comments',
        @{
            N='NotificationDetails';
            E={
                $_.comments | Where-Object {$_.comment_type -eq 'note' -and $_.body -match $CommandPattern} | ForEach-Object {
                    $TargetDate = [datetime]::Parse($_.created_at)
                    $_.body -replace $CommandPattern -split '\ ' | Where-Object {
                        $_ -match "^\d+[$($units.Keys -join ',')]$"
                    } | ForEach-Object {
                        $ThisUnit = $_ -split '(?=[a-z])'; . $Units[$ThisUnit[1]]
                    }
                    if ($TargetDate -gt [datetime]::now) {
                        New-Object -TypeName PSObject -Property @{
                            ContactAddress = $_.CreatorEmail
                            ReminderTime = $TargetDate
                        }
                    }
                }
            }
        }
    )

    Import-SpiceworksTicketSet @PSBoundParameters -State 'open' | Where-Object $FilterComments | select $SelectReminderInfo | Where-Object {$_.NotificationDetails}
}