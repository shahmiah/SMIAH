<#
Written by: Ram Pandy & Shah Miah
Email: a-rapan@microsoft.com, shmiah@microsoft.com

Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. 
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. 
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that. You agree: 
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, 
that arise or result from the use or distribution of the Sample Code


This script contains configuration parameters/variable used throughout the entire process.  Changes should only be needed in this script unless change in 
functionality in which case relevant script block may need to be changed.  

Look for the items at top marked as “Update”.  Only 3 values are required to be changed.  

Change Log:
1.0 (30/04/2015) - Initial release
#>

# UPDATE - SMTP Details
$smtpServerName = "<SMTP Server name or IP>"    # UPDATE - with actual SMTP Server Name. 
$msgFrom = "biztalkTest@gstt.nhs.uk"            # UPDATE - as required based on environment working on.
#Add more recipients
$msgTo=""                                       # UPDATE - as required based on environment working on/support groups to which emails is to be sent.
$msgSubject = "Reg: 115031912537185 Tasklist from sv-pr-tie-CL02"


$EventSource = 'PortUsageAlerts'                       # OPTIONAL UPDATE
$stateList = "LISTENING", "TIME_WAIT", "ESTABLISHED"   # OPTIONAL UPDATE, Change if adding/removing port state for monitoring.
$infoCount = 7000                                      # OPTIONAL UPDATE, if total port count is below this amount information is logged
$warningCount = 10000                                  # OPTIONAL UPDATE, if total port count is below this amount but and more then infoCount then then warning  is logged, otherwise errors are logged.

$pathForIDERun = "C:\Temp\scripts\PortUsageAlerts"     # This needs to be set if running from and IDE otherwise the script will determine the correct path
