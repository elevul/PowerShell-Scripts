# Creating new AD User
# This script assumes you have already installed the MSOnline and ActiveDirectory modules

$date = Get-Date -Format "MM-dd-yyyy-HH-mm"

Start-Transcript -Path "C:\New-Account-$date.log" -Append

Import-Module ActiveDirectory

Import-Module MSOnline

Write-Warning "THIS SCRIPT IS FOR CREATION OF A NEW USER. PLEASE ENSURE ACCURACY IN EXECUTION AND DATA ENTRY. BY DEFAULT THIS ACCOUNT WILL BE STORED IN THE 'USERS' OU AND WILL NEED TO BE MOVED."

$usercheck = Read-Host -Prompt "Enter the intended username of the user being created"

$name = "$usercheck"
$User = $(try {Get-ADUser $Name} catch {$null})
If ($User -ne $Null) { 
"USERNAME ALREADY EXISTS. DO NOT CONTINUE."
} Else
 {
"User not found in AD. Proceed with creation."}

$name = Read-Host -Prompt "Enter the first and last name of the user being created"

$firstname = Read-Host -Prompt "Enter the first name of the user being created"

$lastname = Read-Host -Prompt "Enter the last name of the user being created"

$description = Read-Host -Prompt "Enter the description/job title of the user being created"

$email = "$firstname.$lastname@simradiology.onmicrosoft.com"

$employeeid = Read-Host -Prompt "Enter the employee ID of the user"

$manager = Read-Host -Prompt "Enter the SAM of the user's manager"

$office = Read-Host -Prompt "Enter the user's work location"

New-ADUser -Name "$name" -DisplayName "$name" -GivenName "$firstname" -Surname "$lastname" -SamAccountName "$usercheck" -UserPrincipalName "$email" -EmailAddress "$email" -Description "$description" -Title "$description" -Manager "$manager" -Office "$office" -AccountPassword(Read-Host -AsSecureString "Input Password") -Enabled $true -ChangePasswordAtLogon $true