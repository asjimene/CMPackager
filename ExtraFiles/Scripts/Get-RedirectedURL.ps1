<#
.SYNOPSIS
    Aquire the url that is being redirected to when using the passed url parameter

.DESCRIPTION
    When a website only supplies a url to the latest version, but that url is redirected
    to a different url to aquire the actual binary file.
    Then this function can be used to simplify that aquiral.

.PARAMETER url
    The url to check for redirection

.PARAMETER referer
    An optional parameter to use when a website requires the referer header to
    be used

.OUTPUTS
    The redirected url when one is found, otherwise returns the same url that was passed.

.LINK
    https://wormiecorp.github.io/Wormies-AU-Helpers/docs/functions/get-redirectedurl
#>
function Get-RedirectedUrl {
    param(
        [Parameter(Mandatory = $true)]
        [uri]$url,
        [uri]$referer,
        [Alias('DisableEscape','RawUrl')]
        [switch]$NoEscape
    )

    $req = [System.Net.WebRequest]::CreateDefault($url)
    if ($referer) {
        $req.Referer = $referer

    }
    $resp = $req.GetResponse()

    if ($resp -and $resp.ResponseUri.OriginalString -ne $url) {
        Write-Verbose "Found redirected url '$($resp.ResponseUri)"
        if ($NoEscape -or $($resp.ResponseUri.OriginalString) -match '\%\d+' ) {
            $result = $resp.ResponseUri.OriginalString
        }
        else {
            $result = [uri]::EscapeUriString($resp.ResponseUri.OriginalString)
        }
    }
    else {
        Write-Warning "No redirected url was found, returning given url."
        $result = $url
    }

    $resp.Dispose()

    return $result
}