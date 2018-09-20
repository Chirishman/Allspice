function Initialize-SpiceworksConnection {
	<# Initialize-SpiceworksConnection

	.SYNOPSIS
		Logs into Spiceworks and returns a session object to be used in further page or api calls
	.PARAMETER $uri
		The root of the Spiceworks url without any trailing slashes
	.PARAMETER $username
		User login that has permission to login to /login
	.PARAMETER $password
		User password to /login
	.OUTPUTS
		Microsoft.PowerShell.Commands.WebRequestSession object containing cookies for further page or api calls using Invoke-WebRequest or Invoke-RestMethod
	.LINK
		http://community.spiceworks.com/topic/295123-fun-spiceworks-community-project
	.LINK
		http://community.spiceworks.com/topic/144808-spiceworks-api-question
	.LINK
		http://social.technet.microsoft.com/Forums/windowsserver/en-US/21e834e4-65a9-43df-8177-c4060dd66dc1/having-trouble-trying-to-get-json-info-from-spiceworks-website
	.LINK
		http://community.spiceworks.com/scripts/show/311-spiceworks-ticket-rss-atom-feed
	.NOTES
	Requires PowerShell 3.0 and .NET Framework 4.0
	Script is commented on sections I found interesting.
	.EXAMPLE
	$session = .\LoginTo-Spiceworks.ps1 "https://my.spiceworks.server" "user_login" "user_password"
	$jsonData = ConvertTo-Json(Invoke-RestMethod (([string]$Uri.GetLeftPart(1)) + "/api/tickets.json") -WebSession $session)
	#>

	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$true)][Uri]$Uri,
		[Parameter(Mandatory=$true)][pscredential] $Credential
	)

	add-type "using System.Net; using System.Security.Cryptography.X509Certificates; public class TrustAllCertsPolicy : ICertificatePolicy { public bool CheckValidationResult( ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) { return true; } }"
	[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

	# Constants
	$userAgent = "Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.101 Safari/537.36"
	$headers = @{
		"Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8";
		"Accept-Encoding"="gzip,deflate,sdch";
		"Accept-Language"="en-US,en;q=0.8";
	}

	# First call - used to get "spiceworks_session" cookie and "authenticity_token" form entry
	# UserAgent and Headers not necessary here, but included to match fiddler capture of browser
	$r = Invoke-WebRequest (-join($Uri.GetLeftPart(1),"/pro_users/login")) -SessionVariable session -UserAgent $userAgent -Headers $headers

	# There are 3 "Set-Cookie" in the response - the 2nd one is blank - fine for browsers, but powershell takes the first one and ignores the 2nd and 3rd - so we fix:
	$session.Cookies.SetCookies(([string]$Uri),$r.Headers['Set-Cookie'] -split ',' -match '.' -join ',')

	# Fill out form fields:
	# 1.) Can't use $r.Forms[0].Fields[*] because it returns the "id" on form inputs, but "name" inputs are passed to POST
	# 2.) Can't use a dictionary object as it sends data in incorrect order in the POST
	# 3.) Plain string works - pickaxe and both btn inputs are not necessary but there to match fiddler capture of browser
	$formFieldsText = "authenticity_token=" + [System.Net.WebUtility]::UrlEncode($r.Forms[0].Fields["authenticity_token"]) + `
						"&_pickaxe=%E2%B8%95" + ` # Go figure, it's an actual pickaxe in unicode
						#"&user%5Bemail%5D=" + [System.Net.WebUtility]::UrlEncode($Credential.UserName) + `
						"&pro_user%5Bemail%5D=" + [System.Net.WebUtility]::UrlEncode($Credential.UserName) + `
						#"&user%5Bpassword%5D=" + [System.Net.WebUtility]::UrlEncode($Credential.GetNetworkCredential().Password) + `
						"&pro_user%5Bpassword%5D=" + [System.Net.WebUtility]::UrlEncode($Credential.GetNetworkCredential().Password) + `
						"&btn=login&btn=login"

	# Redirection not necessary - cookies get messed up between posts unless you manually fix, so we don't follow redirections
	$session.MaximumRedirection = 0

	# Second call - post login data, authenticity_token, and spiceworks_session cookie - Ignore Error output as we'll go over the MaximumRedirection setting here
	# This call returns a different spiceworks_cookie and 2 other cookies needed for all future calls (portal_user_email and user_id)
	# Have not tested excluding these other cookies to see if other url's work without them, easier to just include them all)
	# UserAgent and Headers not necessary here, but included to match fiddler capture of browser

	#Found on Spiceworks: https://community.spiceworks.com/scripts/show/2285-log-into-spiceworks-via-powershell-for-api-access?utm_source=copy_paste&utm_campaign=growth

	$r = Invoke-WebRequest (-join($Uri.GetLeftPart(1),"/pro_users/login")) -WebSession $session -Method POST -Body $formFieldsText -UserAgent $userAgent -Headers $headers -ErrorAction SilentlyContinue

	# Fix blank set-cookie header again
	$session.Cookies.SetCookies(([string]$Uri),$r.Headers['Set-Cookie'] -split ',' -match '.' -join ',')

	# Return the session object for future calls
	$session
}