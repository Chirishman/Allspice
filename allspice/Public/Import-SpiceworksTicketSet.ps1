function Import-SpiceworksTicketSet {
    Param(
        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
        [Parameter(Mandatory)]
        [Uri]$Uri,
		[Parameter()]
		[ValidateSet('open','closed','waiting')]
        [String]$State = 'open',
        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

	$state = $state.ToLower()

	$FlattenComments = @{
		Property = @(
			'*',
			@{
				N='CreatorName';
				E={($_.creator.last_name,$_.creator.first_name) -join ', '}
			},
			@{
				N='CreatorEmail';
				E={$_.creator.email}
			}
		)
		ExcludeProperty = @('creator')
	}

	$FlattenTickets = @{
		Property = @(
			'*',
			@{
				N='CreatorName';
				E={@($_.Creator.last_name,$_.Creator.first_name) -join ', '}
			},
			@{
				N='CreatorEmail';
				E={$_.Creator.email}
			},
			@{
				N='AssigneeName';
				E={if($_.assignee.last_name){($_.assignee.last_name,$_.assignee.first_name) -join ', '}}
			},
			@{
				N='AssigneeEmail';
				E={$_.assignee.email}
			},
			@{
				N='closed_at';
				E={[datetime]::Parse($_.closed_at)}
			},
			@{
				N='created_at';
				E={[datetime]::Parse($_.created_at)}
			},
			@{
				N='due_at';
				E={[datetime]::Parse($_.due_at)}
			},
			@{
				N='updated_at';
				E={[datetime]::Parse($_.updated_at)}
			},
			@{
				N='statusupdated_at';
				E={[datetime]::Parse($_.statusupdated_at)}
			},
			@{
				N='viewed_at';
				E={[datetime]::Parse($_.viewed_at)}
			},
			@{
				N='due_date';
				E={[datetime]::Parse($_.due_date)}
			},
			@{
				N='comments';
				E={
					$_.comments | select @FlattenComments
				}
			}
		)
		ExcludeProperty = @('assigned_to','creator','assignee','closed_at','created_at','due_at','updated_at','statusupdated_at','viewed_at','due_date','comments')
	}

    if (-not $WebSession) {
		$WebSession = Initialize-SpiceworksConnection -uri (-join($Uri.GetLeftPart(1),'/pro_users')) -Credential $Credential
    }

	$count = 1
    $StateTickets = $(
        while (($ThisResponse = Get-SpiceworksTicketPage @PSBoundParameters -Count ([ref]$count))) {
            $ThisResponse
        }
    )

	[void]$PSBoundParameters.Remove('state')

	Get-SpiceworksTicket @PSBoundParameters -TicketNumber $StateTickets.id | Select @FlattenTickets
}