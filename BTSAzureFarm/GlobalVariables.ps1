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


# UPDATE - BASE Name
$baseVMName = 'gsttdev'                        # UPDATE - Must be Globally Unique. This value must be 8 characters or less and all lower case. I usually use initials and numbers.

# UPDATE - Subscription Details 
$subscriptionName = 'UKAzure-shmiah'       # UPDATE - From publishing file
$basePathToScripts = 'C:\Users\shmiah\Documents\GitHub\SMIAH\BTSAzureFarm'    # OPTIONAL UPDATE - this is used if you run the scripts through an IDE not a Command Windows

# Default Storage account
$defaultStorageAccount = $baseVMName + "store"

# Affinity Group Details -deperecated use location instead
$locationDC = 'West Europe'                         # From Get-AzureLocation

# VM Details
$adminUserName = 'ladmin'                       
$password = 'B1ztalk01'                        
$sizePDC = 'Medium'                             
$sizeSQL = 'Medium'                            
$sizeBTS = 'Medium'                             

$virtualNetwork = "$baseVMName-vnet"            
$subNetName = 'App'                             
$virtualNetworkConfig = "$pathName\Configs"     
$virtualNetworkDNSName = 'Google'               
$virtualNetworkDNSIP = '8.8.8.8'                

# Domain Details
$domainName = 'corp.smiah.com'
$domainNamePreFix = 'corp'
$domainAdminUserName = 'dadmin'

# DNS Details
$dnsName = 'SMIAHDNS'
$dnsLoopBackIP = '127.0.0.1'
$dnsIP = '10.0.0.4'  # This is the IP of the PDC. 

# Host Names of the 2 hosts auto-created by the deployment process
# To add more hosts the MultiConfig file in the storage account needs to be changed
$hostName1 = 'TrackingHost'                    
$hostName2 = 'ReceiveHost'                     
$hostName3 = 'SendHost'                        
$hostName4 = 'ProcessingHost'                  

# Image Names from Get-AzureVMImage
$imageWindows = 'bd507d3a70934695bc2128e3e5a255ba__RightImage-Windows-2012-x64-v13.5'
$imageSQLEnt = 'fb83b3509582419d99629ce476bcb5c8__Microsoft-SQL-Server-2008R2SP2-Enterprise-CY13SU04-SQL2008-SP2-10.50.4021.0'
$imageSQL12Ent = 'fb83b3509582419d99629ce476bcb5c8__SQL-Server-2012-SP1-11.0.3430.0-Enterprise-ENU-Win2012-cy14su05'
$imageBTSEnt = '2cdc6229df6344129ee553dd3499f0d3__BizTalk-Server-2013-Enterprise'

# Set all the VM Name
$vmnamePDC = "$baseVMName-pdc"
$vmnameSQL01 = "$baseVMName-sql01"
$vmnameBTS01 = "$baseVMName-bts01"
$vmnameBTS02 = "$baseVMName-bts02"


# This needs to be set if running from and IDE otherwise the script will determine the correct path
$pathForIDERun = "C:\Users\shmiah\Documents\GitHub\SMIAH\BTSAzureFarm"
if($MyInvocation.MyCommand.Path -eq $null) { $pathName = $pathForIDERun } else {$pathName = Split-Path $MyInvocation.MyCommand.Path -ErrorAction SilentlyContinue}
"Script Path is " + $pathName


Set-AzureSubscription -SubscriptionName $subscriptionName -CurrentStorageAccount $defaultStorageAccount -ErrorAction SilentlyContinue
Select-AzureSubscription -SubscriptionName $subscriptionName


# From http://michaelwasham.com/2013/04/16/windows-azure-powershell-updates-for-iaas-ga/
# Updated with http://gallery.technet.microsoft.com/scriptcenter/Configures-Secure-Remote-b137f2fe
# To Automate Remote Powershell
function InstallWinRMCert($serviceName, $vmname)
{	
    Write-Host "Installing WinRM Certificate for remote access: $serviceName $vmname"
	$WinRMCert = (Get-AzureVM -ServiceName $serviceName -Name $vmname | select -ExpandProperty vm).DefaultWinRMCertificateThumbprint
	$AzureX509cert = Get-AzureCertificate -ServiceName $serviceName -Thumbprint $WinRMCert -ThumbprintAlgorithm sha1

	$certTempFile = [IO.Path]::GetTempFileName()
	$AzureX509cert.Data | Out-File $certTempFile

	# Target The Cert That Needs To Be Imported
	$CertToImport = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $certTempFile

	$store = New-Object System.Security.Cryptography.X509Certificates.X509Store "Root", "LocalMachine"
	$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
	$store.Add($CertToImport)
	$store.Close()
	
	Remove-Item $certTempFile
}
