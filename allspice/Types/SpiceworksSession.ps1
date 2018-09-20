class SpiceworksSession {
    [int] $Id;
    [validateset('Connected','Disconnected')][string] $State = 'Disconnected';
    [string] $Server;
    hidden [Microsoft.PowerShell.Commands.WebRequestSession] $WebSession;
    hidden [string] $AuthenticityToken;
    hidden [Nullable[int]] $Port;
    hidden [pscredential] $credential;
    hidden [bool] $UseHTTPS;
    hidden [uri] $uri;
    hidden [string] $LoginUri;
    hidden [string] $TicketQueryUri;
    hidden [string] $TicketDetailUri;
    hidden [string] $userAgent = "Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.101 Safari/537.36";
    hidden [hashtable] $Headers = @{
        "Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8";
        "Accept-Encoding"="gzip,deflate,sdch";
        "Accept-Language"="en-US,en;q=0.8";
    }
    hidden [string] $LoginBody = "authenticity_token={0}&_pickaxe=%E2%B8%95&pro_user%5Bemail%5D={1}&pro_user%5Bpassword%5D={2}&btn=login&btn=login"
    
    hidden [uri] CreateURI($subpath,$query){
        $UriBuilder = [uribuilder]::new()
        $UriBuilder.Host = $this.Server
        if ($this.Port){
            $UriBuilder.Port = $this.Port
        }
        $UriBuilder.Scheme = "http$('s'*$this.UseHTTPS)"
        $UriBuilder.Path = $subpath
        $UriBuilder.Query = $query
        return $UriBuilder.uri
    }
    hidden [uri] CreateURI($subpath){
        return $this.CreateURI($subpath,$null)
    }
    hidden [uri] CreateURI(){
        return $this.CreateURI($null,$null)
    }
    hidden [void] NewSession([string]$server,[pscredential]$credential,[bool]$UseHTTPS,[Nullable[int]]$port){
        if (-not $Script:SpiceworksSessions){
            $Script:SpiceworksSessions = [System.Collections.ArrayList]::new()
        }
        $this.Id = $Script:SpiceworksSessions.Count;
        $this.Server = $server
        $this.UseHTTPS = $UseHTTPS
        $this.Port = $port
        $this.uri = $this.CreateURI()
        $this.LoginUri = $this.CreateURI('pro_users/login')
        $this.TicketQueryUri = $this.CreateURI('/api/tickets.json','filter={0}&page={1}')
        $this.TicketDetailUri = $this.CreateURI('/api/tickets/{0}.json')
        $this.credential = $credential

        [void]$Script:SpiceworksSessions.Add($this)
    }

    SpiceworksSession([string]$server,[pscredential]$credential,[bool]$UseHTTPS,[int]$port){
        $this.NewSession($server,$credential,$UseHTTPS,$port)
    }
    SpiceworksSession([string]$server,[pscredential]$credential,[bool]$UseHTTPS){
        $this.NewSession($server,$credential,$UseHTTPS,$null)
    }
    SpiceworksSession([string]$server,[pscredential]$credential,[int]$port){
        $this.NewSession($server,$credential,$false,$port)
    }
    SpiceworksSession([string]$server,[pscredential]$credential){
        $this.NewSession($server,$credential,$false,$null)
    }

    [void] Connect(){
        add-type "using System.Net; using System.Security.Cryptography.X509Certificates; public class TrustAllCertsPolicy : ICertificatePolicy { public bool CheckValidationResult( ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) { return true; } }"
	    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        
        $ThisSession = $null

        $LoginRequest = @{
            Uri = $this.LoginUri
            UserAgent = $this.UserAgent
            Headers = $this.Headers
        }

        $LoginChallenge = Invoke-WebRequest @LoginRequest -SessionVariable 'ThisSession'
        
        $ThisSession.Cookies.SetCookies(([string]$this.Uri),$LoginChallenge.Headers['Set-Cookie'] -split ',' -match '.' -join ',')
        $ThisSession.MaximumRedirection = 0
        
        $LoginReply = @{
            WebSession = $ThisSession
            Method = 'POST'
            Body = $this.LoginBody -f (@($LoginChallenge.Forms[0].Fields["authenticity_token"],$this.Credential.UserName,$this.Credential.GetNetworkCredential().Password)|%{[System.Net.WebUtility]::UrlEncode($_)})
            ErrorAction = 'SilentlyContinue'
        }

        $LoginResponse = Invoke-WebRequest @LoginRequest @LoginReply

        $ThisSession.Cookies.SetCookies(([string]$this.Uri),$LoginResponse.Headers['Set-Cookie'] -split ',' -match '.' -join ',')
        $this.WebSession = $ThisSession
        $this.State = 'Connected'
    }
}