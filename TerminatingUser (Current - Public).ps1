# This script assumes you have already installed/connected to the ActiveDirectory, MSOnline, and ExchangeOnlineManagement modules.
# --------------------------------------------------------------------------------------------------------------------------------

$date = Get-Date -Format "MM-dd-yyyy-HH-mm"

$descdate = Get-Date -Format "MMddyy-HHmm"

$user = Read-Host -Prompt "Enter the sAM of user being terminated"

$cu = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

Start-Transcript -Path "C:\Disable-Account-$user-$date.log" -Append

Import-Module ActiveDirectory

Import-Module MSOnline

Import-Module ExchangeOnlineManagement

Write-Warning "THIS SCRIPT WILL COMPLETELY TERMINATE AND DISABLE THE USER ENTERED BELOW. BY EXECUTING THIS SCRIPT, YOU TAKE FULL RESPONSIBILITY OF VERIFYING THE CORRECT USER IS BEING TERMINATED."

Disable-ADAccount -Identity $user -Confirm

function Get-RandomCharacters($length, $characters) {
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    $private:ofs=""
    return [String]$characters[$random]
}

function Scramble-String([string]$inputString){
    $characterArray = $inputString.ToCharArray()
    $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length
    $outputString = -join $scrambledStringArray
    return $outputString
}

$password = Get-RandomCharacters -length 8 -characters 'abcdefghiklmnoprstuvwxyz'
$password += Get-RandomCharacters -length 2 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
$password += Get-RandomCharacters -length 2 -characters '1234567890'
$password += Get-RandomCharacters -length 2 -characters '!"§$%&/()=?}][{@#*+'

$password = Scramble-String $password

Set-ADAccountPassword -Identity $user -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $password -Force) -Confirm

Set-ADUser -Identity $user -Description "Terminated $descdate - $cu"

Get-ADUser -Identity $user -Properties MemberOf | ForEach-Object {
  $_.MemberOf | Remove-ADGroupMember -Members $_.DistinguishedName -Confirm:$false
}

$upn = (Get-ADUser -Identity $user -Properties *).UserPrincipalName

$DistributionGroups = Get-Distributiongroup -ResultSize Unlimited

$UserDisplayName = (Get-Mailbox $user).name

ForEach ($Group in $DistributionGroups)
{
if ((Get-DistributionGroupMember $Group.Name | Select-Object -Expand Name) -contains $UserDisplayName)
{
Remove-DistributionGroupMember -Identity "$Group" -Member "$UserDisplayName" -Confirm:$true
}
}

Set-MsolUser -UserPrincipalName $upn -BlockCredential $true

(Get-MsolUser -UserPrincipalName $upn).licenses.AccountSkuId |
ForEach-Object{
    Set-MsolUserLicense -UserPrincipalName $upn -RemoveLicenses $_
}

Write-Host -ForegroundColor Yellow "Waiting..."

Start-Sleep -Seconds 60

Get-ADUser -Identity $user -Properties *

Stop-Transcript