# Copy old logs to HTML directory for download is needed
# Build html file to show current log (if any) and list old logs (folder contents)


$dateMidnight = Get-Date -Hour 0 -Minute 0 -Second 0
#Location of log files
$pathSource = "C:\ScriptOutput\DNSChecks"
#Location to place web page and log files as .txt
$pathDest = "C:\WebSites\DNSChecks"
#Web page name
$pathHTML = "Default.htm"

#Copy log files and rename to .txt
Get-ChildItem -Path $pathSource -Filter "*.log" | Where-Object { $_.lastWriteTime -le $dateMidnight } | ForEach-Object {
    $newName = $_.name -replace '\.log$', '.txt'
    $destination = Join-Path -path $pathDest -ChildPath $newName
    Copy-Item -Path $_.FullName -Destination $destination -Force
}
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
        document.getElementById("datetime").innerHTML = (("0"+dt.getDate()).slice(-2)) +"-"+ (("0"+(dt.getMonth()+1)).slice(-2)) +"-"+ (dt.getFullYear()) +" "+ (("0"+dt.getHours()).slice(-2)) +":"+ (("0"+dt.getMinutes()).slice(-2));
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

$htmlContent = ""
$htmlContent += "DNS checks are performed against various resolvers in order to verify they are correctly functioning<br><br>"
$htmlContent += "<div class='section'><div class='header'>Todays Entries</div>"
$todaysLog = "$($pathSource)\DNSLookupErrors-$(get-date -f 'yyyyMMdd').log"
if (test-path $todaysLog) {
    $logContent = get-content $todayslog
    $logContent = $logcontent -join "<br>`r`n"
    $htmlContent += "<blockquote>$logContent</blockquote>"
}
else {
    $htmlContent += "<i>No logs to show today</i>"
}
$htmlContent += "</div><br><br><br>"
$htmlContent += "<div class='section'><div class='header'>Previous Log Files</div>"
$htmlContent += "<ul>"
$logList = Get-ChildItem -Path $pathDest -Filter "DNSLookup*.txt"
foreach ($file in $logList) {
    $con = get-content $file.fullname
    $lines = ($con | select-string .).count
    $htmlContent += "<li><a href='$($file.name)' target=_blank>$($file.name)</a> Entries: $($lines)</li>`r`n"
}
$htmlContent += "</ul><br>"
$htmlContent += "</div>"

$htmlTitle = "DNS Check - Log Files"
BuildHTML $htmlTitle $htmlContent $pathHTML
