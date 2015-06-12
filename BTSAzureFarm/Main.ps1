<#
Written by: Shah Miah
Email: shmiah@microsoft.com

Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. 
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. 
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that. You agree: 
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, 
that arise or result from the use or distribution of the Sample Code



1.0 (30/04/2015) - Initial release
#>

# This needs to be set if running from and IDE otherwise the script will determine the correct path
$pathForIDERun = "C:\Users\shmiah\Documents\GitHub\SMIAH\BTSAzureFarm"

cls

$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") 

if(($IsAdmin) -eq $false)
{
    Write-Error "Must run elevated PowerShell to install WinRM certificates used for Remote PowerShell."
	return
}

$startTime = get-date
"$startTime"

if($MyInvocation.MyCommand.Path -eq $null) { $pathName = $pathForIDERun } else {$pathName = Split-Path $MyInvocation.MyCommand.Path -ErrorAction SilentlyContinue}
"Script Path is " + $pathName

Set-AzureSubscription -SubscriptionName $subscriptionName -CurrentStorageAccount $defaultStorageAccount -ErrorAction SilentlyContinue
Select-AzureSubscription -SubscriptionName $subscriptionName

.$pathName\GlobalVariables.ps1
.$pathName\CreateAzureServices.ps1

#CreateStorageAccount
#CreateVNETS
#CreateVMDC
#createVM -vmName $vmnameSQL01  -vmSize $sizeSQL -imageType $imageSQLEnt -ipAddress "10.0.0.5"
createVM -vmName $vmnameBTS01  -vmSize $sizeBTS -imageType $imageBTSEnt -ipAddress "10.0.0.6"
createVM -vmName $vmnameBTS02  -vmSize $sizeBTS -imageType $imageBTSEnt -ipAddress "10.0.0.7"

"Sleeping for 3 min to let things in Azure IaaS settle"
Start-Sleep -s 180
. $pathName\03_Configure_Servers_RemoteProp.ps1


"Sleeping for 60 seconds to let things in Azure IaaS settle"
Start-Sleep -s 60

# Only needed if Auto Configure is enabled
# To enable Auto Configure the updated BizTalk Provisioning tools are needed from a Azure BizTalk 2013 Dev VM
if($installBizTalkProv -eq "true")
{
    "Start - Configure servers" # This script will try to configure BizTalk using the settings provided.  
    . $pathName\04_Configure_Servers_LaunchRDP.ps1
    "Endt - Configure servers"
}

"Start - Get RDP Files"
. $pathName\05_RemoteDesktop.ps1
"Endt - Get RDP Files"

$endTime = get-date
"Script run time " + ($endTime - $startTime)
"You can login to each server with the Domain Admin account: $domainNamePreFix\$domainAdminUserName and Password: $password"