# Creating new AD User
# This script assumes you have already installed the ActiveDirectory, MSOnline, and ExchangeOnlineManagement modules.
# -------------------------------------------------------------------------------------------------------------------

$date = Get-Date -Format "MM-dd-yyyy-HH-mm"

Start-Transcript -Path "C:\NewUser-$date.log" -Append

Import-Module ActiveDirectory

Import-Module MSOnline

Import-Module ExchangeOnlineManagement

Write-Warning "THIS SCRIPT IS FOR CREATIONG OF A NEW USER. ENSURE THE DATA YOU ENTER IS ACCURATE. BY UTILIZING THIS SCRIPT, YOU TAKE FULL RESPONSIBILITY TO ENSURE ACCURACY OF THE NEW USER'S ATTRIBUTES."

$usercheck = Read-Host -Prompt "Enter the intended username of the new user"

$name = "$usercheck"
$user = $(try {Get-ADUser $name} catch {$null})
If ($user -ne $Null) {
"!!! USERNAME ALREADY EXISTS. DO NOT CONTINUE !!!"
} Else
 {
"Username not found in AD. Proceed with creation."}

$template = Read-Host -Prompt "Enter the sAM of the user to mirror"

$templateaccount = Get-ADUser -Identity $template -Properties Country,City,Company,Description,Department,HomeDrive,HomeDirectory,Manager,Office,PostalCode,StreetAddress,State,Title

$templateaccount.UserPrincipalName = $null

$name = Read-Host -Prompt "Enter the first and last name of the new user (e.g. John Smith)"

$givenname = Read-Host -Prompt "Enter the first name of the new user (e.g. John)"

$surname = Read-Host -Prompt "Enter the last name of the new user (e.g. Smith)"

$sam = $usercheck

$email = "$givenname.$surname@domain.com"

$id = Read-Host -Prompt "Enter the employee ID of the new user (e.g. 0123)"

$ou = Read-Host -Prompt "Enter the DN of the OU to create the new user in (e.g. OU=USERS,OU=CORP,DC=corp,DC=contoso,DC=com)"

New-ADUser -Instance $templateaccount -Name "$name" -GivenName "$givenname" -Surname "$surname" -SamAccountName "$sam" -DisplayName "$name" -EmployeeID "$id" -Path "$ou" -EmailAddress "$email" -UserPrincipalName "$email" -AccountPassword (Read-Host -AsSecureString "Input initial temporary Password") -Enabled $true -ChangePasswordAtLogon $true

Get-ADUser -Identity $templateaccount -Properties * | Select-Object Memberof -ExpandProperty Memberof | Add-ADGroupMember -Members "$sam" -Confirm

Write-Host -ForegroundColor Cyan "Waiting 30 minutes for Domain Controllers and Azure AD Connect to sync..."

Start-Sleep -Seconds 1860

Set-MsolUser -UserPrincipalName "$email" -UsageLocation US

Set-MsolUser -UserPrincipalName "$email" -BlockCredential $false

Get-MsolAccountSku | Format-List AccountSkuId,ActiveUnits,ConsumedUnits

Set-MsolUserLicense -UserPrincipalName "$email" -AddLicenses (Read-Host -Prompt "Enter licenses to add by exact name listed above (...STANDARDPACK = E1, ENTERPRISEPACK = E3)")

Start-Sleep -Seconds 10

Get-ADUser -Identity "$sam" -Properties *

Get-MsolUser -UserPrincipalName "$email" | Format-List UserPrincipalName,DisplayName,isLicensed,Licenses

Stop-Transcript