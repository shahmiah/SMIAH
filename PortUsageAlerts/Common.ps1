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


Change Log:
1.0 (30/04/2015) - Initial release
#>


function write_to_event_log{
param([string]$content_to_write, [string]$entry_type)

if (!(test-path HKLM:\SYSTEM\CurrentControlSet\Services\Eventlog\Application\$EventSource )){
    new-eventlog -Logname Application -source $EventSource -ErrorAction SilentlyContinue
    } 
        Write-Eventlog -Logname Application -Message $content_to_write -Source $EventSource -id 2222 -entrytype $entry_type -category 0 

<# 
    if($entry_type -eq "Information")
    {
        Write-Eventlog -Logname Application -Message $content_to_write -Source EventSource -id 2222 -entrytype Information -category 0 
    }

    if($entry_type -eq "Warning")
    {
        Write-Eventlog -Logname Application -Message $content_to_write -Source EventSource -id 3333 -entrytype Warning -category 0 
    }

    elseif($entry_type -eq "Error")
    {
        Write-Eventlog -Logname Application -Message $content_to_write -Source EventSource -id 4444 -entrytype Error -category 0 
    }

#>    
}
