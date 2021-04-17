# This script assumes you have already installed the MSOnline and ActiveDirectory modules.

$date = Get-Date -Format "MM-dd-yyyy-HH-mm"

$descdate = Get-Date -Format "MMddyy"

$user = Read-Host -Prompt "Enter the AD username of user being terminated"

Start-Transcript -Path "‪C:\Users\jeff.johnson\OneDrive - US Radiology Specialists Inc\Windows PS Logs\Disable-Account-$user-$date.log" -Append

Import-Module ActiveDirectory

Import-Module MSOnline

Write-Warning "THIS SCRIPT WILL COMPLETELY TERMINATE AND DISABLE THE USER ENTERED BELOW. BY EXECUTING THIS SCRIPT, YOU TAKE FULL RESPONSIBILITY OF VERIFYING THE CORRECT USER IS BEING TERMINATED."

$cu = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

Disable-ADAccount -Identity $user -Confirm

Get-ADUser -Identity $user -Properties MemberOf | ForEach-Object {
  $_.MemberOf | Remove-ADGroupMember -Members $_.DistinguishedName -Confirm:$false
}

Set-ADAccountPassword -Identity $user -Reset -Confirm

Set-ADUser -Identity $user -Description "Terminated $descdate - $cu"

$upn = Read-Host -Prompt "Enter the UPN of user being terminated"

Set-MsolUser -UserPrincipalName $upn -BlockCredential $true

(get-MsolUser -UserPrincipalName $upn).licenses.AccountSkuId |
foreach{
    Set-MsolUserLicense -UserPrincipalName $upn -RemoveLicenses $_
}

Get-ADUser -Identity $user -Properties *

Stop-Transcript