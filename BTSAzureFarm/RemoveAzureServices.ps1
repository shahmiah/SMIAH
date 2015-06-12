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
$pathForIDERun = ""

if($MyInvocation.MyCommand.Path -eq $null) { $pathName = $pathForIDERun } else {$pathName = Split-Path $MyInvocation.MyCommand.Path -ErrorAction SilentlyContinue}
"Script Path is " + $pathName

. $pathName\variables.ps1

Set-AzureSubscription -SubscriptionName $subscriptionName
Select-AzureSubscription -SubscriptionName $subscriptionName

Remove-AzureService -ServiceName $vmnameBTS02 -DeleteAll -Force -ErrorAction SilentlyContinue
Remove-AzureService -ServiceName $vmnameBTS01 -DeleteAll -Force -ErrorAction SilentlyContinue
Remove-AzureService -ServiceName $vmnameSQL01 -DeleteAll -Force -ErrorAction SilentlyContinue
Remove-AzureService -ServiceName $vmnamePDC -DeleteAll -Force -ErrorAction SilentlyContinue

# Remove the Storage Account
$hasStorageAccount = Get-AzureStorageAccount | Where-Object {$_.StorageAccountName.contains("$defaultStorageAccount")}

# Remove the storage account
do {
    "Waiting to try to remove the storage account"
    Start-Sleep -s 30
    Remove-AzureStorageAccount -StorageAccountName $defaultStorageAccount -ErrorAction SilentlyContinue
    $hasStorageAccount = Get-AzureStorageAccount | Where-Object {$_.StorageAccountName.contains("$defaultStorageAccount")}
} while($hasStorageAccount)

# Remote the Virtual Network
Remove-AzureVNetConfig -ErrorAction Continue

# Give is a few seconds
Start-Sleep -s 60

# Remove the Affinity Group
Remove-AzureAffinityGroup -Name $affinityGroup -ErrorAction Continue

# Remove Director with RDP files
if(Test-Path -Path "$pathName\RemoteDesktop"){
    Remove-Item "$pathName\RemoteDesktop" -Force -Recurse 
}

#Get-AzureVM -ServiceName $vmnamePDC -Name $vmnamePDC | Get-AzureStaticVNetIP
#Get-AzureVM -ServiceName $vmnamePDC -Name $vmnamePDC | Get-AzureStaticVNetIP
#Test-AzureStaticVNetIP -VNetName $virtualNetwork -IPAddress 10.0.0.4