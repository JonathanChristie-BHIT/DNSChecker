[string]$errNotes = $null
$errData = @()
$errLookup = $null

[array]$DNSServers = @(
    ('192.168.0.1', 'Internal'),
    ('8.8.4.4', 'Google A'),
    ('8.8.8.8', 'Google B'),
    ('1.1.1.1', 'Cloudflare A'),
    ('1.0.0.1', 'Cloudflare B'),
    ('208.67.222.222', 'OpenDNS A'),
    ('208.67.220.220', 'OpenDNS B')
)
[array]$sites = $null
#Remove for testing
#$sites = @("tams.microsoft.com")
$sites += @("teams.microsoft.com", "outlook.office.com", "outlook.office365.com", "www.bbc.co.uk", "www.google.co.uk", "www.yahoo.com", "portal.office.com", "portal.azure.com")

foreach ($dnsServer in $DNSServers) {
    foreach ($site in $sites) {
        $serverIP = $dnsServer[0]
        $serverName = $dnsServer[1]
        try {
            $resultDNS = Resolve-DnsName $site -Server $serverIP -Type a -TcpOnly -erroraction SilentlyContinue
            $result = $resultDNS.ip4address
            #Write-Output "$($serverIP)`t$($site)`t$($result)"
        }
        catch {
            $result = $null
        }

        if ($null -eq $result) {
            $errNotes += "[$(get-date -f 'yyyy.MMM.dd HH:mm:ss')] Log Error: $($serverIP) ($($serverName)): $($site)`r`n"
            $errLookup = new-object PSObject
            $errLookup | add-member -MemberType NoteProperty -Name Date -Value $(get-date)
            $errLookup | add-member -MemberType NoteProperty -Name DNSServerName -Value $serverName
            $errLookup | add-member -MemberType NoteProperty -Name DNSServer -Value $serverIP
            $errLookup | add-member -MemberType NoteProperty -Name Site -Value $site
            $errData += $errLookup
        }
    }
}
if (!([string]::isNullorEmpty($errNotes))) {
    $errNotes | Out-File "C:\ScriptOutput\DNSChecks\DNSLookupErrors-$(get-date -f 'yyyyMMdd').log" -Append
}
if ($null -ne $errData) {
    $errData | Export-csv -path "C:\ScriptOutput\DNSChecks\DNSLookupErrors-$(get-date -f 'yyyyMMdd').csv" -Append -notypeinformation
}
