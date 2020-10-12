# Copy old logs to HTML directory for download is needed
# Build html file to show current log (if any) and list old logs (folder contents)
#

$dateMidnight = Get-Date -Hour 0 -Minute 0 -Second 0
$pathSource = "C:\ScriptOutput\DNSChecks"
$pathDest = "C:\WebSites\DNSChecks"
$pathHTML = "Default.htm"

#Copy log files and rename to .txt
Get-ChildItem -Path $pathSource -Filter "*.log" | Where-Object { $_.lastWriteTime -le $dateMidnight } | ForEach-Object {
    $newName = $_.name -replace '\.log$', '.txt'
    $destination = Join-Path -path $pathDest -ChildPath $newName
    Copy-Item -Path $_.FullName -Destination $destination -Force
}

#These are copied from the main script that does the checking. I'm too lazy to create a common config file.
[array]$sites = $null
#Remove for testing
#$sites = @("tams.microsoft.com")
$sites += @("teams.microsoft.com", "outlook.office.com", "outlook.office365.com", "www.bbc.co.uk", "www.google.co.uk", "www.yahoo.com")

[array]$DNSServers = @(
    ('192.168.0.1', 'Internal'),
    ('8.8.4.4', 'Google A'),
    ('8.8.8.8', 'Google B'),
    ('1.1.1.1', 'Cloudflare A'),
    ('1.0.0.1', 'Cloudflare B'),
    ('208.67.222.222', 'OpenDNS A'),
    ('208.67.220.220', 'OpenDNS B')
)
#sort
$DNSServers=$DNSServers | Sort-Object @{expression={$_[1]};}

$dnsServersHTML = "<div class='section'><div class='header'>DNS Resolvers Used</div><div class='container'>"
foreach ($server in $DNSServers) {
    $dnsServersHTML += "<div class='tableInc-row'><div class='tableInc-cell-l'>&nbsp$($server[1])</div><div class='tableInc-cell-l'>&nbsp$($server[0])</div></div>`r`n"
}
$dnsServersHTML+="</div></div>"
$sitesHTML = "<div class='section'><div class='header'>Hosts to be resolved</div><div>&nbsp;$($sites -join("<br>&nbsp;"))</div></div>"

function BuildHTML {
    Param (
        [Parameter(Mandatory = $true)] [string]$Title,
        [Parameter(Mandatory = $true)] [string]$contentOne,
        [Parameter(Mandatory = $true)] [string]$HTMLOutput
    )
    [array]$htmlHeader = @()
    [array]$htmlBody = @()
    [array]$htmlFooter = @()
    [string]$addJava = ""
    $htmlHeader = @"
		<!DOCTYPE html>
		<html>
		<head>
        <link rel="stylesheet" href="dns.css">
        <title>$($Title)</title>
		<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
		<meta http-equiv="Pragma" content="no-cache" />
		<meta http-equiv="Expires" content="0" />
        </head>
"@
    $htmlBody = @"
        <body>
        <h1>$($Title)</h1>
        <p>Page refreshed: <span id="datetime"></span><span>&nbsp;&nbsp;Data refresh:$(Get-Date -f 'MMM dd yyyy HH:mm:ss')</span></p>
        $($contentOne)
"@
    $htmlFooter = @"
        <script>
        var dt = new Date();
        document.getElementById("datetime").innerHTML = (("0"+dt.getDate()).slice(-2)) +"-"+ (("0"+(dt.getMonth()+1)).slice(-2)) +"-"+ (dt.getFullYear()) +" "+ (("0"+dt.getHours()).slice(-2)) +":"+ (("0"+dt.getMinutes()).slice(-2))+":"+ (("0"+dt.getSeconds()).slice(-2));
        </script>
        </body>
        </html>
"@

    #Add in code to refresh page
    # 300000 is 5 mins (5 *60 * 1000)
    #Assumes the code is scheduled and runs at least every 5 mins
    # $addJava = "<script language=""JavaScript"" type=""text/javascript"">"
    # $addJava += "setTimeout(""location.href='$($HTMLOutput)'"",$($pageRefresh*60*1000));"
    # $addjava += "</script>"

    $htmlReport = $htmlHeader + $addJava + $htmlBody + $htmlFooter
    $htmlReport | Out-File "$($pathDest)\$($HTMLOutput)"
}

$htmlContent = "<br>"
$htmlContent += "DNS checks are performed against various resolvers in order to verify they are correctly functioning<br>`r`n"
$htmlContent += "Resolvers and sites checked are listed at the bottom of the page<br><br>`r`n"
$htmlContent += "<div class='container'><div class='section'><div class='header'>Todays Entries</div>"
$todaysLog = "$($pathSource)\DNSLookupErrors-$(get-date -f 'yyyyMMdd').log"
if (test-path $todaysLog) {
    $logContent = get-content $todayslog
    $logContent = $logcontent -join "<br>`r`n"
    $htmlContent += "$logContent"
}
else {
    $htmlContent += "<i>No logs to show today</i>"
}
$htmlContent += "</div>"
$htmlContent += "<div class='section'><div class='header'>Previous Log Files</div>"
$htmlContent += "<ul>"
$logList = Get-ChildItem -Path $pathDest -Filter "DNSLookup*.txt" | sort-object name -desc
foreach ($file in $logList) {
    $con = get-content $file.fullname
    $lines = ($con | select-string .).count
    $htmlContent += "<li><a href='$($file.name)' target=_blank>$($file.name)</a> Entries: $($lines)</li>`r`n"
}
$htmlContent += "</ul>"
$htmlContent += "</div></div><br><br>"
$htmlContent += "<h1>Whats Occurin'?</h1>`r`n"
$htmlContent += "Every minute, each DNS resolver is asked to resolve a few DNS entries. Only errors are logged.<br>`r`n"
$htmlContent += "These are scrapped together and shown in 'Todays Entries' above. Each 'grouping' is from the same 1 minute task (as shown in timestamps).<br>`r`n"
$htmlContent += "Previous log files are shown on the right.<br>`r`n"
$htmlContent += "<div class='container'>$($DNSServershtml)`r`n"
$htmlContent += "$($sitesHTML)</div><br><br>`r`n"

$htmlTitle = "DNS Check - Log Files"
BuildHTML $htmlTitle $htmlContent $pathHTML
