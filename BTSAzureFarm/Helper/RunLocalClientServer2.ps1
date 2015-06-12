New-EventLog –LogName Application –Source 'BizTalkGurus' -ErrorAction SilentlyContinue

#Write-EventLog -LogName Application -Source 'BizTalkGurus' -Message 'Installing Classic Shell' -EventId 0 -ErrorAction SilentlyContinue

# Install Classic Shell
#Start-Process "SETUPDIR\ClassicShellSetup_4_1_0.exe" -ArgumentList('/qn') -Wait

#Write-EventLog -LogName Application -Source 'BizTalkGurus' -Message 'Installing BizTalk 2013 CU2' -EventId 0 -ErrorAction SilentlyContinue

# Install BizTalk 2013 CU2
#Start-Process "SETUPDIR\BizTalk2013CU2\BTS2013-RTM-KB2892599-ENU.exe" -ArgumentList('/quiet') -Wait

Write-EventLog -LogName Application -Source 'BizTalkGurus' -Message 'Starting Local Service' -EventId 0 -ErrorAction SilentlyContinue

# Start the Local Client
Start-Process SETUPDIR\BizTalk.Provisioning.Client\Microsoft.Cloud.BizTalk.Provisioning.LocalService.exe -Wait
