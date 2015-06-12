<#
Written by: Stephen W Thomas
Email: me@biztalkguru.com
Twitter: @stephenwthomas
Community Site: www.BIzTalkGurus.com
Personal Site: www.BizTalkGuru.com

Content provided as-is.  Use at your own risk.  Charges may/will apply when creating VMs inside Windows Azure. 

This script is using remote desktop to launch tasks on the BizTalk Servers.

Change Log:
1.0 (6/2/2014) - Initial release (Tested with May 2014 PowerShell Commands - older versions may not work)
1.1 (6/10/2014) - Added support to start SQL Agent and adjust MSDTC settings
#>
"Start - Setup variables"

Set-AzureSubscription -SubscriptionName $subscriptionName -CurrentStorageAccount $defaultStorageAccount -ErrorAction SilentlyContinue
Select-AzureSubscription -SubscriptionName $subscriptionName

"End - Setup variables"
"Start - Run Remote Desktop locally"

# Get Remote Desktop helper locally
if ([System.IO.Directory]::Exists($setupDir)) { Remove-Item $setupDir -Force -Recurse }
    mkdir $setupDir;
    
# Download Needed Files for Remote Desktop automation
$remoteUriRDP = "$workStorgeAccount/rdp.exe"
$fileNameRDP = "$setupDir\rdp.exe"
$webClientRDP = new-object System.Net.WebClient
$webClientRDP.DownloadFile($remoteUriRDP, $fileNameRDP)   

# Get the port for the RDP End Point BizTalk 01
$drpPort2 = (Get-AzureVM –ServiceName $vmnameBTS02 –Name $vmnameBTS02 | Get-AzureEndpoint | Where-Object {$_.Name.contains('RDP')}).Port

# From http://www.donkz.nl/  BizTalk 02
iex "$fileNameRDP /v:$vmnameBTS02.cloudapp.net:$drpPort2 /u:$domainNamePreFix\$domainAdminUserName /p:$password" #/h:1 /w:1

# Give the Task time to run and get started
Start-Sleep -s 180

# Get the port for the RDP End Point BizTalk 01
$drpPort = (Get-AzureVM –ServiceName $vmnameBTS01 –Name $vmnameBTS01 | Get-AzureEndpoint | Where-Object {$_.Name.contains('RDP')}).Port

# From http://www.donkz.nl/  BizTalk 01
iex "$fileNameRDP /v:$vmnameBTS01.cloudapp.net:$drpPort /u:$domainNamePreFix\$domainAdminUserName /p:$password" #/h:1 /w:1

"End - Run Remote Desktop locally"
"Start - Cleanup on BTS01"

# Wait for process to complete and cleanup on BizTalk01
Invoke-Command -ConnectionUri $uriBTS01.ToString() -Credential $credentialsDomain -ScriptBlock {
    param($setupDir)
    
    $doneFile = "$setupDir\done.txt"
    
    while (!(Test-Path -Path $doneFile)) {
        "Waiting for process to complete ..."
        Start-Sleep -s 30
    }

    iex "C:\Windows\System32\schtasks.exe /Delete /TN:ConfigBizTalk /F"

    # Adjust MSDTC Settings
    # Set Security and MSDTC path
    $msdtcRegPath = “HKLM:\SOFTWARE\Microsoft\MSDTC\”
    $msdtcRegSecPath = “$msdtcRegPath\Security”
    
    Set-ItemProperty -path $msdtcRegSecPath -name “NetworkDtcAccess” -value 1
    Set-ItemProperty -path $msdtcRegSecPath -name “NetworkDtcAccessClients” -value 1
    Set-ItemProperty -path $msdtcRegSecPath -name “NetworkDtcAccessAdmin” -value 1
    Set-ItemProperty -path $msdtcRegSecPath -name “NetworkDtcAccessTransactions” -value 1
    Set-ItemProperty -path $msdtcRegSecPath -name “NetworkDtcAccessInbound” -value 1
    Set-ItemProperty -path $msdtcRegSecPath -name “NetworkDtcAccessOutbound” -value 1
    Set-ItemProperty -path $msdtcRegSecPath -name “XaTransactions” -value 1
                 
    Set-ItemProperty -path $msdtcRegPath -name “AllowOnlySecureRpcCalls” -value 0
    Set-ItemProperty -path $msdtcRegPath -name “TurnOffRpcSecurity” -value 1
    Set-ItemProperty -path $msdtcRegPath -name “FallbackToUnsecureRPCIfNecessary” -value 0

    Start-Service -Name 'MSDTC'

} -ArgumentList $setupDir

"End - Cleanup on BTS01"
"Start - Cleanup on BTS02"

# Cleanup on BizTalk02 and Log Off
Invoke-Command -ConnectionUri $uriBTS02.ToString() -Credential $credentialsDomain -ScriptBlock {
param($vmnameBTS02)
    
    iex "C:\Windows\System32\schtasks.exe /Delete /TN:ConfigBizTalk /F"

    # Adjust MSDTC Settings
    # Set Security and MSDTC path
    $msdtcRegPath = “HKLM:\SOFTWARE\Microsoft\MSDTC\”
    $msdtcRegSecPath = “$msdtcRegPath\Security”
    
    Set-ItemProperty -path $msdtcRegSecPath -name “NetworkDtcAccess” -value 1
    Set-ItemProperty -path $msdtcRegSecPath -name “NetworkDtcAccessClients” -value 1
    Set-ItemProperty -path $msdtcRegSecPath -name “NetworkDtcAccessAdmin” -value 1
    Set-ItemProperty -path $msdtcRegSecPath -name “NetworkDtcAccessTransactions” -value 1
    Set-ItemProperty -path $msdtcRegSecPath -name “NetworkDtcAccessInbound” -value 1
    Set-ItemProperty -path $msdtcRegSecPath -name “NetworkDtcAccessOutbound” -value 1
    Set-ItemProperty -path $msdtcRegSecPath -name “XaTransactions” -value 1
                 
    Set-ItemProperty -path $msdtcRegPath -name “AllowOnlySecureRpcCalls” -value 0
    Set-ItemProperty -path $msdtcRegPath -name “TurnOffRpcSecurity” -value 1
    Set-ItemProperty -path $msdtcRegPath -name “FallbackToUnsecureRPCIfNecessary” -value 0

    Start-Service -Name 'MSDTC'

    $server   = $vmnameBTS02
    $username = $env:USERNAME
    
    $server
    $username

    $session = ((quser /server:$server | ? { $_ -match $username }) -split ' +')[2]

    logoff $session /server:$server

} -ArgumentList $vmnameBTS02


# Need to restart it agian mostly just to end the remote desktop session
#Restart-AzureVM -ServiceName $vmnameBTS02 -Name $vmnameBTS02

"End - Cleanup on BTS02"
"Start - Cleanup on SQL"

Invoke-Command -ConnectionUri $uriSQL01.ToString() -credential $credentials -ScriptBlock {

    # Adjust the SQL Agent settings
    Set-Service -Name 'SQLSERVERAGENT' -StartupType Automatic
    Start-Service -Name 'SQLSERVERAGENT'

} 

"End - Cleanup on SQL"
"Start - Cleanup on local"

# Cleanup local
Remove-Item $setupDir -Force -Recurse

# Stop the backgroud job running the service via remote powershell
#stop-job -Id $bt2Job.Id

"End - Cleanup on local"

