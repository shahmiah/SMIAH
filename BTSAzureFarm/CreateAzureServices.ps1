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

function CreateAfinityGroup{
 "StartFunction CreateAfinityGroup"
# create if Affinity Group doe not exists
    if(!(Get-AzureAffinityGroup -Name $affinityGroup -ErrorAction SilentlyContinue))
    {
        "Creating Affinity Group $affinityGroup"
        # Create Addinity Group 
        New-AzureAffinityGroup -Name $affinityGroup -Location $dataCenter -ErrorAction Stop
        "Done Creating Affinity Group $affinityGroup"
    }
"EndFunction"
}

function CreateStorageAccount{
    "StartFunction CreateStorageAccount"
# create if storage account does not exists
    if(!(Get-AzureStorageAccount -StorageAccountName $defaultStorageAccount -ErrorAction SilentlyContinue))
    {
        "Creating Storage Account $defaultStorageAccount"
        New-AzureStorageAccount -StorageAccountName $defaultStorageAccount -Label "Development Storage" -Location $locationDC -ErrorAction Stop
        Set-AzureStorageAccount -StorageAccountName $defaultStorageAccount -GeoReplicationEnabled $false -ErrorAction Stop
        "Done Creating Storage Account $defaultStorageAccount"
    }
    
    "End Function"
}

function CreateVNETS{
    "StartFunction CreateVNETS"

    # Check is the subscription already has a VNet 
    $hasVNetAlready = Get-AzureVNetSite

    # Check is the subscription has this specific VNet
    $hasThisVNetAlready = Get-AzureVNetSite | Where-Object {$_.Name.contains("$virtualNetwork")}

    # Cheack if the Virtual Network Exists if not create it
    if(!($hasThisVNetAlready))
    {
        if(!($hasVNetAlready))
        {
            "Creating Virtual Network $virtualNetwork"
            "Config file location $virtualNetworkConfig\NetworkConfig.xml"
            # Update the config file
            $configFile = Get-Content("$virtualNetworkConfig\NetworkConfig.xml")
            $configFile = $configFile.Replace("VNETNAME", $virtualNetwork);
            $configFile = $configFile.Replace("DCLOCATION", $locationDC);
            $configFile = $configFile.Replace("SUBNETNAME", $subNetName);
            $configFile | out-file "$virtualNetworkConfig\NetworkConfig_new.netcfg"
            Set-AzureVNetConfig -ConfigurationPath $virtualNetworkConfig\NetworkConfig_new.netcfg -ErrorAction Stop
            "Done Creating Virtual Network $virtualNetwork"    
        }
        else
        {
            # If a VNet exists, add a new one.  Sure wish PowerShell did this better.
            # From http://blogs.blackmarble.co.uk/blogs/rhepworth/post/2014/03/03/Creating-Azure-Virtual-Networks-using-Powershell-and-XML.aspx
            # Get current config
            $currentVNetConfig = get-AzureVNetConfig
            [xml]$workingVnetConfig = $currentVNetConfig.XMLConfiguration   

            $dnsExists = $workingVnetConfig.GetElementsByTagName("DnsServer") | where {$_.name -eq $virtualNetworkDNSName}
        
            if ($dnsExists.Count -ne 0)
            {    
                "DNS Server $virtualNetworkDNSName already exists"    
            }
            else
            {
                $workingNode = $workingVnetConfig.GetElementsByTagName("Dns") 
            
                $dnsServers = $workingVnetConfig.GetElementsByTagName("DnsServers")
            
                if ($dnsServers.count -eq 0)
                {
                    $newDnsServers = $workingVnetConfig.CreateElement("DnsServers","http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration") 
                    $dnsServers = $workingNode.appendchild($newDnsServers)
                } 
            
                $singleDNS = $workingVnetConfig.GetElementsByTagName("DnsServers")
                $addDNS = $workingVnetConfig.CreateElement("DnsServer","http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration") 
                $addDNS.SetAttribute("name",$virtualNetworkDNSName) 
                $addDNS.SetAttribute("IPAddress",$virtualNetworkDNSIP) 
                $DNS = $singleDNS.appendchild($addDNS)
            }    

            $virtNetCfg = $workingVnetConfig.GetElementsByTagName("VirtualNetworkSites")

            $newNetwork = $workingVnetConfig.CreateElement("VirtualNetworkSite","http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration") 
            $newNetwork.SetAttribute("name",$virtualNetwork) 
            $newNetwork.SetAttribute("location",$locationDC) 
            $Network = $virtNetCfg.appendchild($newNetwork)

            $newAddressSpace = $workingVnetConfig.CreateElement("AddressSpace","http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration") 
            $AddressSpace = $Network.appendchild($newAddressSpace) 
            $newAddressPrefix = $workingVnetConfig.CreateElement("AddressPrefix","http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration") 
            $newAddressPrefix.InnerText="10.0.0.0/8"
            $AddressSpace.appendchild($newAddressPrefix)

            $newSubnets = $workingVnetConfig.CreateElement("Subnets","http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration") 
            $Subnets = $Network.appendchild($newSubnets) 
            $newSubnet = $workingVnetConfig.CreateElement("Subnet","http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration") 
            $newSubnet.SetAttribute("name", $subNetName) 
            $Subnet = $Subnets.appendchild($newSubnet) 
            $newAddressPrefix = $workingVnetConfig.CreateElement("AddressPrefix","http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration")
            $newAddressPrefix.InnerText="10.0.0.0/11"
            $Subnet.appendchild($newAddressPrefix)

            $newItemDNS = $workingVnetConfig.CreateElement("DnsServersRef","http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration") 
            $ItemDNS = $Network.appendchild($newItemDNS) 
            $newItemSingleDNS = $workingVnetConfig.CreateElement("DnsServerRef","http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration") 
            $newItemSingleDNS.SetAttribute("name", $virtualNetworkDNSName) 
            $ItemDNS.appendchild($newItemSingleDNS) 

            $tempFileName = "$virtualNetworkConfig\NetworkConfig_new.netcfg"
            $workingVnetConfig.save($tempFileName)
  
            set-AzureVNetConfig -configurationpath $tempFileName -ErrorAction Stop
        }

    }
    
    "End Function"

}

function CreateVMDC{
    "StartFunction CreateVMDC"
    # User Loopback
    $myDNS = New-AzureDNS -Name $dnsName -IPAddress $dnsLoopBackIP

    $strPassword = ConvertTo-SecureString $password -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential ($domainAdminUserName, $strPassword)

    #VM Configuration
    $MyDC = New-AzureVMConfig -name $vmnamePDC -InstanceSize $sizePDC -ImageName $imageWindows | `
            Add-AzureProvisioningConfig -Windows -AdminUsername $domainAdminUserName -Password $password | `
            Set-AzureSubnet -SubnetNames $subNetName | `
            Set-AzureStaticVNetIP -IPAddress $dnsIP
        
    New-AzureVM -ServiceName $vmnamePDC -Location $locationDC -VMs $MyDC -DnsSettings $myDNS -VNetName $virtualNetwork -WaitForBoot -ErrorAction Stop

    # Get the RemotePS/WinRM Uri to connect to
    $uri = Get-AzureWinRMUri -ServiceName $vmnamePDC -Name $vmnamePDC
 
    # Using generated certs – use helper function to download and install generated cert.
    InstallWinRMCert $vmnamePDC $vmnamePDC
 
    "Start - AD Install"
    Invoke-Command -ConnectionUri $uri.ToString() -Credential $credential -ScriptBlock {
        param($domainName, $password)
        $strPassword = ConvertTo-SecureString $password -AsPlainText -Force
        Install-windowsfeature -name AD-Domain-Services –IncludeManagementTools
        Install-ADDSForest -SkipPreChecks –DomainName $domainName -SafeModeAdministratorPassword $strPassword -Force 
    } -ArgumentList $domainName, $password
    "End - AD Install"

    # Wait for the services to start
    Start-Sleep -s 240

    "Start - User / Domain Group setup"
    Invoke-Command -ConnectionUri $uri.ToString() -Credential $credential -ScriptBlock {
        param($password, $domainAdminUserName)
        $strPassword = ConvertTo-SecureString $password -AsPlainText -Force

        # Wait for ADWS to start just in case
        # Sometimes this gives a thread error
        while ((get-service -Name 'ADWS').Status -ne "Running") {
            "Waiting for ADWS to start ..."
            Start-Sleep -s 15
        }
    
        # These domain groups are hard coded inside the Multi Server Configuration file
        # Changes here will break the auto config process
        New-ADGroup -Name "SSO Administrators" -GroupCategory Security -GroupScope Global -DisplayName "SSO Administrators"
        New-ADGroup -Name "SSO Affiliate Administrators" -GroupCategory Security -GroupScope Global -DisplayName "SSO Affiliate Administrators"
        New-ADGroup -Name "BizTalk Application Users" -GroupCategory Security -GroupScope Global -DisplayName "BizTalk Application Users"
        New-ADGroup -Name "BizTalk Isolated Host Users" -GroupCategory Security -GroupScope Global -DisplayName "BizTalk Isolated Host Users"
        New-ADGroup -Name "BizTalk Server Administrators" -GroupCategory Security -GroupScope Global -DisplayName "BizTalk Server Administrators"
        New-ADGroup -Name "BizTalk Server Operators" -GroupCategory Security -GroupScope Global -DisplayName "BizTalk Server Operators"
        New-ADGroup -Name "BizTalk Server B2B Operators" -GroupCategory Security -GroupScope Global -DisplayName "BizTalk Server B2B Operators"
        New-ADUser -SamAccountName SSOService -AccountPassword $strPassword -name "SSOService" -enabled $true -PasswordNeverExpires $true -CannotChangePassword $true  -ChangePasswordAtLogon $false
        New-ADUser -SamAccountName BTSAppHost -AccountPassword $strPassword -name "BTSAppHost" -enabled $true -PasswordNeverExpires $true -CannotChangePassword $true  -ChangePasswordAtLogon $false
        New-ADUser -SamAccountName BTSIsolatedHost -AccountPassword $strPassword -name "BTSIsolatedHost" -enabled $true -PasswordNeverExpires $true -CannotChangePassword $true  -ChangePasswordAtLogon $false
        New-ADUser -SamAccountName BTSAdmin -AccountPassword $strPassword -name "BTSAdmin" -enabled $true -PasswordNeverExpires $true -CannotChangePassword $true  -ChangePasswordAtLogon $false
        Add-ADPrincipalGroupMembership -Identity "SSOService" -MemberOf "SSO Administrators"
        Add-ADPrincipalGroupMembership -Identity "BizTalk Server Administrators" -MemberOf "SSO Administrators"
        Add-ADPrincipalGroupMembership -Identity "BTSAdmin" -MemberOf "BizTalk Server Administrators"
        Add-ADPrincipalGroupMembership -Identity "BTSAppHost" -MemberOf "BizTalk Application Users"
        Add-ADPrincipalGroupMembership -Identity "BTSIsolatedHost" -MemberOf "BizTalk Isolated Host Users"
        Add-ADPrincipalGroupMembership -Identity $domainAdminUserName -MemberOf "BizTalk Server Administrators"
        Add-ADPrincipalGroupMembership -Identity $domainAdminUserName -MemberOf "SSO Administrators"
        Add-ADPrincipalGroupMembership -Identity $domainAdminUserName -MemberOf "BizTalk Isolated Host Users"
        Add-ADPrincipalGroupMembership -Identity $domainAdminUserName -MemberOf "BizTalk Application Users"
    } -ArgumentList $password, $domainAdminUserName

    #  Azure IaaS sometimes can take longer, delay to handle that
    Start-Sleep -s 60

    "End Function"
}

function CreateVM{
param([string]$vmName, [string]$vmSize, [string]$imageType, [string]$ipAddress)

    "StartFunction CreateVM -" + $vmName + $vmSize

    # Set the DNS IP once the DC is setup and configured
    $myDNS = New-AzureDNS -Name $dnsName -IPAddress $dnsIP

    # SQL 01 VM Configuration
    $MyVM1 = New-AzureVMConfig -name $vmName -InstanceSize $vmSize -ImageName $imageType `
        | Add-AzureProvisioningConfig -WindowsDomain -AdminUsername $adminUserName  -Password $password -Domain $domainNamePreFix -DomainPassword $password -DomainUserName $domainAdminUserName -JoinDomain $domainName `
        | Set-AzureSubnet -SubnetNames $subNetName `
        | Set-AzureStaticVNetIP -IPAddress $ipAddress

        New-AzureVM -ServiceName $vmnamePDC -Location $locationDC -VMs $MyVM1 -DnsSettings $myDNS -VNetName $virtualNetwork -WaitForBoot -ErrorAction Stop
    
    "End Function"
}
