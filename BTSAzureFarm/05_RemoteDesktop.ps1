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

"Start - Setup variables"

Set-AzureSubscription -SubscriptionName $subscriptionName -CurrentStorageAccount $defaultStorageAccount -ErrorAction SilentlyContinue
Select-AzureSubscription -SubscriptionName $subscriptionName

# Set path
if($MyInvocation.MyCommand.Path -eq $null) { $pathName = $pathForIDERun } else {$pathName = Split-Path $MyInvocation.MyCommand.Path -ErrorAction SilentlyContinue}

# Make Director
if(!(Test-Path -Path "$pathName\RemoteDesktop" )){
    New-Item -ItemType directory -Path "$pathName\RemoteDesktop"
}

"End - Setup variables"
"Start - Generate Remote Desktop Files"

# Get the RDP files
Get-AzureRemoteDesktopFile -ServiceName $vmnamePDC -Name $vmnamePDC -LocalPath "$pathName\RemoteDesktop\$vmnamePDC.rdp"
Get-AzureRemoteDesktopFile -ServiceName $vmnameSQL01 -Name $vmnameSQL01 -LocalPath "$pathName\RemoteDesktop\$vmnameSQL01.rdp"
Get-AzureRemoteDesktopFile -ServiceName $vmnameBTS01 -Name $vmnameBTS01 -LocalPath "$pathName\RemoteDesktop\$vmnameBTS01.rdp"
Get-AzureRemoteDesktopFile -ServiceName $vmnameBTS02 -Name $vmnameBTS02 -LocalPath "$pathName\RemoteDesktop\$vmnameBTS02.rdp"

"End - Generate Remote Desktop Files"
