# Description: Quick Re-Enable of existing AD User
# Date Started: 04/14/2021
# This script assumes you have already installed and connected to MSOnline and ActiveDirectory Modules

Import-Module ActiveDirectory

Import-Module MSOnline

$date = Get-Date -Format "MM-dd-yyyy-HH-mm"

$user = Read-Host -Prompt "Enter the username of the user being re-enabled"

Start-Transcript -Path "C:\Users\jeff.johnson\OneDrive - US Radiology Specialists Inc\Windows PS Logs\ReEnable-Account-$user-$date.log" -Append

Get-ADUser -Identity $user -Properties *

$mirroruser = Read-Host -Prompt "Enter the username of the user to mirror"

$E1 = "reseller-account:STANDARDPACK"

$E3 = "reseller-account:ENTERPRISEPACK"

Enable-ADAccount -Identity $user -Confirm

Unlock-ADAccount -Identity $user -Confirm

Set-ADAccountPassword -Identity $user -Reset -Confirm

Set-ADUser -Identity $user -Description (Read-Host -Prompt "Enter the description of the user being re-enabled") -Confirm

Get-ADUser -Identity $mirroruser -Properties * | Select-Object Memberof -ExpandProperty Memberof | Add-ADGroupMember -Members $user -Confirm

Set-ADUser -Identity $user -ChangePasswordAtLogon $true -Confirm

Set-MsolUser -UserPrincipalName "$user@usradiology.com" -UsageLocation US

Set-MsolUser -UserPrincipalName "$user@usradiology.com" -BlockCredential $false

Get-MsolAccountSku | fl AccountSkuId,ActiveUnits,ConsumedUnits

Set-MsolUserLicense -UserPrincipalName "$user@usradiology.com" -AddLicenses (Read-Host -Prompt "Enter 365 license to add by variable name (E1, E3)")

Get-MsolUser -UserPrincipalName "$user@usradiology.com"

Stop-Transcript