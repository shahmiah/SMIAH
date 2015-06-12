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


$info = new-object system.text.stringbuilder 
$total_port_count =0

$currentTime = get-date -uformat '%Y.%m.%d_%H_%M_%S'

$info.AppendLine("Script ran at : " + $currentTime)

$OSInfo = Get-WmiObject -class Win32_OperatingSystem

$info.AppendLine("Machine info : " + $OSInfo.Caption + " " + $OSInfo.OSArchitecture + " " + $OSInfo.Version)

$info.AppendLine("`nPorts and states:")


foreach($s in $stateList)

{

    $c = netstat -aonp TCP | select-string $s

    if($c.count -le 0)

    {
        $info.AppendLine("0`t" + " ports in state " + $s)
    }

    else

    {
        $info.AppendLine($c.count.ToString() + "`t" + " ports in state " + $s)
    }  

    $total_port_count =$total_port_count+$c.count
}

$info.ToString()

If($total_port_count -lt $infoCount)
{
    write_to_event_log $info.ToString() "Information"
}

If($total_port_count -gt $infoCount -and $total_port_count -lt $warningCount)
{
    write_to_event_log $info.ToString() "Warning"
}

if($total_port_count -gt $warningCount)
{
    write_to_event_log $info.ToString() "Error"
    Try{
        send_email($info.ToString())
    }
    Catch{
        [System.Exception]
        write_to_event_log "Failure insending email message:"+$error "Error"
    }
}