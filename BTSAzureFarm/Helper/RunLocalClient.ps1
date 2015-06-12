New-EventLog –LogName Application –Source 'BizTalkGurus' -ErrorAction SilentlyContinue

# Write-EventLog -LogName Application -Source 'BizTalkGurus' -Message 'Installing BizTalk 2013 CU2' -EventId 0 -ErrorAction SilentlyContinue

# Install BizTalk 2013 CU2
#Start-Process "SETUPDIR\BizTalk2013CU2\BTS2013-RTM-KB2892599-ENU.exe" -ArgumentList('/quiet') -Wait

Write-EventLog -LogName Application -Source 'BizTalkGurus' -Message 'Starting Local Service' -EventId 0 -ErrorAction SilentlyContinue

start-job -ScriptBlock {
    Start-Process SETUPDIR\BizTalk.Provisioning.Client\Microsoft.Cloud.BizTalk.Provisioning.LocalService.exe -Wait
}

Write-EventLog -LogName Application -Source 'BizTalkGurus' -Message 'Starting Script' -EventId 0 -ErrorAction SilentlyContinue

# Wait a bit to make sure the 2nd Server is already running
Start-Sleep -s 300

Start-Process SETUPDIR\BizTalk.Provisioning.Client\Microsoft.Cloud.BizTalk.Provisioning.Client.exe -ArgumentList("SETUPDIR\BizTalk.Provisioning.Client\multinodeconfigDemo.xml") -Wait

Write-EventLog -LogName Application -Source 'BizTalkGurus' -Message 'Completed Client' -EventId 0 -ErrorAction SilentlyContinue


#####
# Do it twice after a small wait
# Not sure why I need to do this, but it only works if I run it two times in a row
#Start-Sleep -s 300

#Start-Process SETUPDIR\BizTalk.Provisioning.Client\Microsoft.Cloud.BizTalk.Provisioning.Client.exe -ArgumentList("SETUPDIR\BizTalk.Provisioning.Client\multinodeconfigDemo.xml") -Wait

#Write-EventLog -LogName Application -Source 'BizTalkGurus' -Message 'Completed Client' -EventId 0 -ErrorAction SilentlyContinue

Stop-Process -Processname 'Microsoft.Cloud.BizTalk.Provisioning.LocalService' -Force -ErrorAction SilentlyContinue

# Decided to keep the config file in place in case the process needs to be re-run.
# This will contain User Names and Passwords
# Remove-Item SETUPDIR\BizTalk.Provisioning.Client\multinodeconfigDemo.xml -Force -Recurse

Write-EventLog -LogName Application -Source 'BizTalkGurus' -Message 'Stopped Local Service Client' -EventId 0 -ErrorAction SilentlyContinue

# Write the DONE file so this doesn't run again.
"Done" > SETUPDIR\done.txt

# Done with the RDP Session
Logoff

    
