Param(
    [Parameter(Mandatory=$true)]
    [string]$InstallDir
)

Function Get-ScriptDirectory { Split-Path $MyInvocation.ScriptName }
$down = Join-Path (Get-ScriptDirectory) 'tasks-down.ps1'
& $down

$taskName = "Certbot Renew & Auto-Update Task"

$actionRenew = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -Command "certbot renew"'
$actionPreUpgrade = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -Command ""Copy-Item '$InstallDir\auto-update.ps1' ""`$env:TMP\auto-update.ps1"""""
$actionUpgrade = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -File ""%TMP%\auto-update.ps1"" -InstallDir ""$InstallDir"""
$actionPostUpgrade = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -Command "Remove-Item "$env:TMP\auto-update.ps1" -ErrorAction "Ignore""'

$delay = New-TimeSpan -Hours 12
$triggerAM = New-ScheduledTaskTrigger -Daily -At 12am -RandomDelay $delay
$triggerPM = New-ScheduledTaskTrigger -Daily -At 12pm -RandomDelay $delay
# NB: For now scheduled task is set up under Administrators account because Certbot Installer installs Certbot for all users.
# If in the future we allow the Installer to install Certbot for one specific user, the scheduled task will need to
# switch to this user, since Certbot will be available only for him.
$adminSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
$adminGroupID = $adminSID.Translate([System.Security.Principal.NTAccount]).Value
$principal = New-ScheduledTaskPrincipal -GroupId $adminGroupID -RunLevel Highest
Register-ScheduledTask -Action $actionRenew,$actionPreUpgrade,$actionUpgrade,$actionPostUpgrade -Trigger $triggerAM,$triggerPM -TaskName $taskName -Description "Execute twice a day the 'certbot renew' command, to renew managed certificates if needed." -Principal $principal
