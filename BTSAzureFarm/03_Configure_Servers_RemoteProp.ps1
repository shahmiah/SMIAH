<#
Written by: Stephen W Thomas
Email: me@biztalkguru.com
Twitter: @stephenwthomas
Community Site: www.BIzTalkGurus.com
Personal Site: www.BizTalkGuru.com

Content provided as-is.  Use at your own risk.  Charges may/will apply when creating VMs inside Windows Azure. 

This script will prep auto configure the new domain using remote PowerShell and tasks on the BizTalk Servers.

Change Log:
1.0 (6/2/2014) - Initial release (Tested with May 2014 PowerShell Commands - older versions may not work)
#>
"Start - Setup variables"

Set-AzureSubscription -SubscriptionName $subscriptionName -CurrentStorageAccount $defaultStorageAccount -ErrorAction SilentlyContinue
Select-AzureSubscription -SubscriptionName $subscriptionName

# Create the credentialss for Remote PowerShell
# Note we are using the Domain Admin
$strPassword = ConvertTo-SecureString $password -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PScredential ($adminUserName, $strPassword)
$credentialsDomain = New-Object System.Management.Automation.PScredential ("$domainNamePreFix\$domainAdminUserName", $strPassword)

$uriSQL01 = Get-AzureWinRMUri -ServiceName $vmnameSQL01 -Name $vmnameSQL01 
InstallWinRMCert $vmnameSQL01 $vmnameSQL01

$uriBTS01 = Get-AzureWinRMUri -ServiceName $vmnameBTS01 -Name $vmnameBTS01 
InstallWinRMCert $vmnameBTS01 $vmnameBTS01

$uriBTS02 = Get-AzureWinRMUri -ServiceName $vmnameBTS02 -Name $vmnameBTS02 
InstallWinRMCert $vmnameBTS02 $vmnameBTS02

"End - Setup variables"
"Start - Add Admin Domain user to SQL"

# Moving Remote PowerShell calls to the end to see if they run better - getting random errors
# Moving the SQL Remote Powershell to the end of the file since it sometimes does not work right away
Invoke-Command -ConnectionUri $uriSQL01.ToString() -credential $credentials -ScriptBlock {
    param($vmnameSQL01, $domainNamePreFix, $domainAdminUserName)

    # Turning off the firewall is different in Windows 2008 R2
    netsh advfirewall set allprofiles state off
    
    # Wait for SQL to start just in case
    while ((get-service -Name 'MSSQLServer').Status -ne "Running") {
        "Waiting for SQL to start ..."
        Start-Sleep -s 15
    }
  
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null 
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.SMO') | out-null 
    # Create SMO Connections to SQL
    $Svr = New-Object ('Microsoft.SqlServer.Management.Smo.Server')
     
    # Add the Domain User and set the role
    $Login = New-Object Microsoft.SqlServer.Management.SMO.Login ($Svr, "$domainNamePreFix\$domainAdminUserName")
    $Login.Name = "$domainNamePreFix\$domainAdminUserName"
    $Login.LoginType = [Microsoft.SqlServer.Management.Smo.LoginType]::WindowsUser
    $Login.Create()
     
    # Made the Domain Admin a SysAdmin
    $svrole = $svr.Roles | where {$_.Name -eq 'sysadmin'}
    $svrole.AddMember("$domainNamePreFix\$domainAdminUserName")

    # Make security Mixed Mode for BizTalk 360
    $Svr.Settings.LoginMode = [Microsoft.SqlServer.Management.SMO.ServerLoginMode]::Mixed
    $Svr.Alter()

} -ArgumentList $vmnameSQL01, $domainNamePreFix, $domainAdminUserName

"End - Add Admin Domain user to SQL"
"Waiting for SQL to get up and running"
Start-Sleep -s 90
"Start - Local Service on BTS02"

# This runs the Local Client via a Task when a users logs in
Invoke-Command -ConnectionUri $uriBTS02.ToString() -Credential $credentialsDomain -ScriptBlock {
    param($domainNamePreFix, $domainName, $domainAdminUserName, $adminUserName, $password, $setupDir, $workStorgeAccount, $installCU2, $installClassicShell, $installBizTalkProv)
        
    Get-NetFirewallProfile | Set-NetFirewallProfile –Enabled False

    Set-ExecutionPolicy Unrestricted

    if ([System.IO.Directory]::Exists($setupDir)) { Remove-Item $setupDir -Force -Recurse }
    mkdir $setupDir; 

    # Logic to install ClassShell to get the Start button back
    # The exe below must exist in the storage account
    if($installClassicShell -eq "true")
    {
        # Download Classic Shell because I can't live without it
        $remoteUriClassicShell = "$workStorgeAccount/ClassicShellSetup_4_1_0.exe"
        $fileNameClassicShell = "$setupDir\ClassicShellSetup_4_1_0.exe"
        $webClientClassicShell = new-object System.Net.WebClient
        $webClientClassicShell.DownloadFile($remoteUriClassicShell, $fileNameClassicShell)
    
        Start-Process "$setupDir\ClassicShellSetup_4_1_0.exe" -ArgumentList('/qn') -Wait
    }

    # Logic to install BizTalk 2013 CU2 
    # The exe below must exist in the storage account
    if($installCU2 -eq "true")
    {
        mkdir "$setupDir\BizTalk2013CU2" 
        
        # Download BizTalk 2013 Cu2
        $remoteUriCU2 = "$workStorgeAccount/BTS2013-RTM-KB2892599-ENU.exe"
        $fileNameCU2 = "$setupDir\BizTalk2013CU2\BTS2013-RTM-KB2892599-ENU.exe"
        $webClientCU2 = new-object System.Net.WebClient
        $webClientCU2.DownloadFile($remoteUriCU2, $fileNameCU2)

        Start-Process "$setupDir\BizTalk2013CU2\BTS2013-RTM-KB2892599-ENU.exe" -ArgumentList('/quiet') -Wait
    }

    # Logic to install a working version of the BizTalk Provisioning Tools and setup Auto-Configure
    # The provisioning files can be copied from a BizTalk 2013 Development VM on Windows Azure
    # They are located at C:\BizTalk_Provisioning\
    # All 5 files will be needed
    # All files below must exist in the storage account at the root level
    if($installBizTalkProv -eq "true")
    {
        mkdir "$setupDir\BizTalk.Provisioning.Client"   
        
        # Download Needed Files for Running PowerShell
        $remoteUriHelper = "$workStorgeAccount/StartPowershell.exe"
        $fileNameHelper = "$setupDir\StartPowershell.exe"
        $webClientHelper = new-object System.Net.WebClient
        $webClientHelper.DownloadFile($remoteUriHelper, $fileNameHelper) 

        # Download Needed Files for PowerShell
        $remoteUriPowerShell = "$workStorgeAccount/RunLocalClientServer2.ps1"
        $fileNamePowerShell = "$setupDir\RunLocalClient_o.ps1"
        $webClientPowerShell = new-object System.Net.WebClient
        $webClientPowerShell.DownloadFile($remoteUriPowerShell, $fileNamePowerShell)

        # Download Needed Files for Task
        $remoteUriRDHelper = "$workStorgeAccount/RunBizTalkTask_Domain.xml"
        $fileNameRDHelper = "$setupDir\RunBizTalkTask_o.xml"
        $webClientRDHelper = new-object System.Net.WebClient
        $webClientRDHelper.DownloadFile($remoteUriRDHelper, $fileNameRDHelper) 
        
        # Download BizTalk Provisioning Tool updates
        $remoteUriF3 = "$workStorgeAccount/Microsoft.Cloud.BizTalk.Provisioning.Common.dll"
        $fileNameF3 = "$setupDir\BizTalk.Provisioning.Client\Microsoft.Cloud.BizTalk.Provisioning.Common.dll"
        $webClientF3 = new-object System.Net.WebClient
        $webClientF3.DownloadFile($remoteUriF3, $fileNameF3) 

        # Download BizTalk Provisioning Tool updates
        $remoteUriF4 = "$workStorgeAccount/Microsoft.Cloud.BizTalk.Provisioning.LocalService.exe"
        $fileNameF4 = "$setupDir\BizTalk.Provisioning.Client\Microsoft.Cloud.BizTalk.Provisioning.LocalService.exe"
        $webClientF4 = new-object System.Net.WebClient
        $webClientF4.DownloadFile($remoteUriF4, $fileNameF4) 

        # Download BizTalk Provisioning Tool updates
        $remoteUriF5 = "$workStorgeAccount/Microsoft.Cloud.BizTalk.Provisioning.LocalService.exe.config"
        $fileNameF5 = "$setupDir\BizTalk.Provisioning.Client\Microsoft.Cloud.BizTalk.Provisioning.LocalService.exe.config"
        $webClientF5 = new-object System.Net.WebClient
        $webClientF5.DownloadFile($remoteUriF5, $fileNameF5) 

        # Update Powershell script
        $configFilePS = Get-Content("$setupDir\RunLocalClient_o.ps1")
        $configFilePS = $configFilePS.Replace("SETUPDIR", $setupDir);
        $configFilePS | out-file "$setupDir\RunLocalClient.ps1" -Encoding utf8

        # Update wtih computer and user information
        $configFileTask = Get-Content("$setupDir\RunBizTalkTask_o.xml")
        $configFileTask = $configFileTask.Replace("COMPUTERNAME", $domainNamePreFix);
        $configFileTask = $configFileTask.Replace("USERACCOUNT", $domainAdminUserName);
        $configFileTask = $configFileTask.Replace("SETUPDIR", $setupDir);
        $configFileTask | out-File "$setupDir\RunBizTalkTask.xml" -Encoding ascii

        # Install the task to run at logon
        iex "C:\Windows\System32\schtasks.exe /Create /XML:$setupDir\RunBizTalkTask.xml /TN:ConfigBizTalk"
    }
} -ArgumentList $domainNamePreFix, $domainName, $domainAdminUserName, $adminUserName, $password, $setupDir, $workStorgeAccount, $installCU2, $installClassicShell, $installBizTalkProv

"End - Local Service on BTS02"
"Start - Command setup on BTS01"

Invoke-Command -ConnectionUri $uriBTS01.ToString() -Credential $credentialsDomain -ScriptBlock {
    param($vmnameBTS01, $vmnameBTS02, $vmnameSQL01, $domainNamePreFix, $domainName, $domainAdminUserName, $adminUserName, $password, $hostName1, $hostName2, $hostName3, $hostName4, $setupDir, $workStorgeAccount, $installCU2, $installClassicShell, $installBizTalkProv)
    
    Get-NetFirewallProfile | Set-NetFirewallProfile –Enabled False
        
    Set-ExecutionPolicy Unrestricted

    if ([System.IO.Directory]::Exists($setupDir)) { Remove-Item $setupDir -Force -Recurse }
        mkdir $setupDir;
    
    # Logic to install ClassShell to get the Start button back
    # The exe below must exist in the storage account
    if($installClassicShell -eq "true")
    {
        # Download Classic Shell because I can't live without it
        $remoteUriClassicShell = "$workStorgeAccount/ClassicShellSetup_4_1_0.exe"
        $fileNameClassicShell = "$setupDir\ClassicShellSetup_4_1_0.exe"
        $webClientClassicShell = new-object System.Net.WebClient
        $webClientClassicShell.DownloadFile($remoteUriClassicShell, $fileNameClassicShell)
    
        Start-Process "$setupDir\ClassicShellSetup_4_1_0.exe" -ArgumentList('/qn') -Wait
    }

    # Logic to install BizTalk 2013 CU2 
    # The exe below must exist in the storage account
    if($installCU2 -eq "true")
    {
        mkdir "$setupDir\BizTalk2013CU2" 
        
        # Download BizTalk 2013 Cu2
        $remoteUriCU2 = "$workStorgeAccount/BTS2013-RTM-KB2892599-ENU.exe"
        $fileNameCU2 = "$setupDir\BizTalk2013CU2\BTS2013-RTM-KB2892599-ENU.exe"
        $webClientCU2 = new-object System.Net.WebClient
        $webClientCU2.DownloadFile($remoteUriCU2, $fileNameCU2)

        Start-Process "$setupDir\BizTalk2013CU2\BTS2013-RTM-KB2892599-ENU.exe" -ArgumentList('/quiet') -Wait
    }

    # Logic to install a working version of the BizTalk Provisioning Tools and setup Auto-Configure
    # The provisioning files can be copied from a BizTalk 2013 Development VM on Windows Azure
    # They are located at C:\BizTalk_Provisioning\
    # All 5 files will be needed
    # All files below must exist in the storage account at the root level
    if($installBizTalkProv -eq "true")
    {
        mkdir "$setupDir\BizTalk.Provisioning.Client" 
        
        # Download Needed Files for BizTalk Multi-Server Configuration
        $remoteUriConfig = "$workStorgeAccount/multinodeconfigDemo_DomainHosts.xml"
        $fileNameConfig = "$setupDir\multinodeconfigDemo_o.xml"
        $webClientConfig = new-object System.Net.WebClient
        $webClientConfig.DownloadFile($remoteUriConfig, $fileNameConfig)   

        # Download Needed Files for Running PowerShell
        $remoteUriHelper = "$workStorgeAccount/StartPowershell.exe"
        $fileNameHelper = "$setupDir\StartPowershell.exe"
        $webClientHelper = new-object System.Net.WebClient
        $webClientHelper.DownloadFile($remoteUriHelper, $fileNameHelper) 

        # Download Needed Files for PowerShell
        $remoteUriPowerShell = "$workStorgeAccount/RunLocalClient.ps1"
        $fileNamePowerShell = "$setupDir\RunLocalClient_o.ps1"
        $webClientPowerShell = new-object System.Net.WebClient
        $webClientPowerShell.DownloadFile($remoteUriPowerShell, $fileNamePowerShell)

        # Download Needed Files for Task
        $remoteUriRDHelper = "$workStorgeAccount/RunBizTalkTask_Domain.xml"
        $fileNameRDHelper = "$setupDir\RunBizTalkTask_o.xml"
        $webClientRDHelper = new-object System.Net.WebClient
        $webClientRDHelper.DownloadFile($remoteUriRDHelper, $fileNameRDHelper) 

        # Download BizTalk Provisioning Tool updates
        $remoteUriF1 = "$workStorgeAccount/Microsoft.Cloud.BizTalk.Provisioning.Client.exe"
        $fileNameF1 = "$setupDir\BizTalk.Provisioning.Client\Microsoft.Cloud.BizTalk.Provisioning.Client.exe"
        $webClientF1 = new-object System.Net.WebClient
        $webClientF1.DownloadFile($remoteUriF1, $fileNameF1) 

        # Download BizTalk Provisioning Tool updates
        $remoteUriF2 = "$workStorgeAccount/Microsoft.Cloud.BizTalk.Provisioning.Client.exe.config"
        $fileNameF2 = "$setupDir\BizTalk.Provisioning.Client\Microsoft.Cloud.BizTalk.Provisioning.Client.exe.config"
        $webClientF2 = new-object System.Net.WebClient
        $webClientF2.DownloadFile($remoteUriF2, $fileNameF2) 

        # Download BizTalk Provisioning Tool updates
        $remoteUriF3 = "$workStorgeAccount/Microsoft.Cloud.BizTalk.Provisioning.Common.dll"
        $fileNameF3 = "$setupDir\BizTalk.Provisioning.Client\Microsoft.Cloud.BizTalk.Provisioning.Common.dll"
        $webClientF3 = new-object System.Net.WebClient
        $webClientF3.DownloadFile($remoteUriF3, $fileNameF3) 

        # Download BizTalk Provisioning Tool updates
        $remoteUriF4 = "$workStorgeAccount/Microsoft.Cloud.BizTalk.Provisioning.LocalService.exe"
        $fileNameF4 = "$setupDir\BizTalk.Provisioning.Client\Microsoft.Cloud.BizTalk.Provisioning.LocalService.exe"
        $webClientF4 = new-object System.Net.WebClient
        $webClientF4.DownloadFile($remoteUriF4, $fileNameF4) 

        # Download BizTalk Provisioning Tool updates
        $remoteUriF5 = "$workStorgeAccount/Microsoft.Cloud.BizTalk.Provisioning.LocalService.exe.config"
        $fileNameF5 = "$setupDir\BizTalk.Provisioning.Client\Microsoft.Cloud.BizTalk.Provisioning.LocalService.exe.config"
        $webClientF5 = new-object System.Net.WebClient
        $webClientF5.DownloadFile($remoteUriF5, $fileNameF5) 

        # Update Powershell script
        $configFilePS = Get-Content("$setupDir\RunLocalClient_o.ps1")
        $configFilePS = $configFilePS.Replace("SETUPDIR", $setupDir);
        $configFilePS | out-file "$setupDir\RunLocalClient.ps1" -Encoding utf8
    
        # Update wtih computer and user information
        $configFileTask = Get-Content("$setupDir\RunBizTalkTask_o.xml")
        $configFileTask = $configFileTask.Replace("COMPUTERNAME", $domainNamePreFix);
        $configFileTask = $configFileTask.Replace("USERACCOUNT", $domainAdminUserName);
        $configFileTask = $configFileTask.Replace("SETUPDIR", $setupDir);
        $configFileTask | out-File "$setupDir\RunBizTalkTask.xml" -Encoding ascii
    
        # Update wtih computer and user information
        $configFile = Get-Content("$setupDir\multinodeconfigDemo_o.xml")
        $configFile = $configFile.Replace("HOSTNAME1", $hostName1);
        $configFile = $configFile.Replace("HOSTNAME2", $hostName2);
        $configFile = $configFile.Replace("HOSTNAME3", $hostName3);
        $configFile = $configFile.Replace("HOSTNAME4", $hostName4);
        $configFile = $configFile.Replace("BTS1COMPUTERNAME", "$vmnameBTS01.$domainName");
        $configFile = $configFile.Replace("BTS2COMPUTERNAME", "$vmnameBTS02.$domainName");
        $configFile = $configFile.Replace("SQLCOMPUTERNAME", "$vmnameSQL01.$domainName");
        $configFile = $configFile.Replace("USERACCOUNT", "$domainNamePreFix\$domainAdminUserName");
        $configFile = $configFile.Replace("USERPASSWORD", $password);
        $configFile = $configFile.Replace("DOMAINPREFIX", $domainNamePreFix);
        $configFile | out-file "$setupDir\BizTalk.Provisioning.Client\multinodeconfigDemo.xml" -Encoding utf8

        # Install the task to run at logon
        iex "C:\Windows\System32\schtasks.exe /Create /XML:$setupDir\RunBizTalkTask.xml /TN:ConfigBizTalk"
    }
} -ArgumentList $vmnameBTS01, $vmnameBTS02, $vmnameSQL01, $domainNamePreFix, $domainName, $domainAdminUserName, $adminUserName, $password, $hostName1, $hostName2, $hostName3, $hostName4, $setupDir, $workStorgeAccount, $installCU2, $installClassicShell, $installBizTalkProv

"End - Command setup on BTS01"
