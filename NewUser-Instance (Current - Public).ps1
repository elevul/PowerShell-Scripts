# Creating new AD User
# This script assumes you have already installed the ActiveDirectory, MSOnline, and ExchangeOnlineManagement modules.
# Written by Spartan, optimized by elevul
# Warning: Still in Beta, hasn't been tested
# -------------------------------------------------------------------------------------------------------------------
#Setting requirements
#Requires -RunAsAdministrator
#Requires -Version 5.1
#Requires -PSEdition Desktop
#Requires -Modules ActiveDirectory
#Requires -Modules MSOnline
#Requires -Modules ExchangeOnlineManagement

#Importing the required modules
Import-Module ActiveDirectory
Import-Module MSOnline
Import-Module ExchangeOnlineManagement

#Preparing variables
$date = Get-Date -Format "MM-dd-yyyy-HH-mm"

#Starting transcript
Start-Transcript -Path "C:\NewUser-$date.log" -Append

Write-Warning "THIS SCRIPT IS FOR CREATIONG OF A NEW USER. ENSURE THE DATA YOU ENTER IS ACCURATE. BY UTILIZING THIS SCRIPT, YOU TAKE FULL RESPONSIBILITY TO ENSURE ACCURACY OF THE NEW USER'S ATTRIBUTES."

[string]$usercheck = Read-Host -Prompt "Enter the intended username of the new user"

try {
    #Checking if the user exists and if it does indicate that the user exists and quit. If not, fail to the catch block.
    $user = Get-ADUser $usercheck -ErrorAction Stop
    Write-Warning "$usercheck already exists. No action required"
}
catch {
    #Asking for the user to use as template and preparing the template
    $template = Read-Host -Prompt "Enter the sAM of the user to mirror"
    $templateaccount = Get-ADUser -Identity $template -Properties EmailAddress, DistinguishedName, UserPrincipalName, Country, City, Company, Description, Department, HomeDrive, HomeDirectory, Manager, Office, PostalCode, StreetAddress, State, Title
    
    #Gathering additional information from the template
    $newuserou = ($templateaccount.DistinguishedName -split ",", 2)[1]
    $newuserupn = ($templateaccount.UserPrincipalName -split "@", 2)[1]

    #Preparing password
    Add-Type -AssemblyName 'System.Web'
    $unsecurepassword = [System.Web.Security.Membership]::GeneratePassword(12, 1)
    $securePassword = ConvertTo-SecureString -String $unsecurepassword -AsPlainText -Force

    #Asking for additional information and preparing
    $givenname = Read-Host -Prompt "Enter the first name of the new user (e.g. John)"    
    $surname = Read-Host -Prompt "Enter the last name of the new user (e.g. Smith)"
    $id = Read-Host -Prompt "Enter the employee ID of the new user (e.g. 0123)"
    $name = $givenname + " " + $surname
    $email = "$givenname.$surname@$newuserupn"

    #Preparing properties list
    $properties = @{
        Instance              = $templateaccount
        Name                  = $name
        Path                  = $newuserou
        SamAccountName        = $usercheck
        DisplayName           = $name
        GivenName             = $givenname
        Surname               = $surname
        AccountPassword       = $securePassword
        Description           = $description
        UserPrincipalName     = $email
        EmailAddress          = $email
        EmployeeID            = $id
        ChangePasswordAtLogon = $false
        Enabled               = $true
    }
    
    #Creating AD user
    New-ADUser  @properties
    
    #Adding AD groups template user is member of to the membership of the new user
    Get-ADUser -Identity $templateaccount -Properties * | Select-Object Memberof -ExpandProperty Memberof | Add-ADGroupMember -Members $usercheck -Confirm
    
    #Waiting for sync
    Write-Host -ForegroundColor Cyan "Waiting 30 minutes for Domain Controllers and Azure AD Connect to sync..."
    Start-Sleep -Seconds 1860
    
    #Setting some configurations in the cloud
    Set-MsolUser -UserPrincipalName "$email" -UsageLocation US    
    Set-MsolUser -UserPrincipalName "$email" -BlockCredential $false
    
    #Getting the license from the template user and assigning to new user.
    ##Warning: This hasn't been verified with users that have more than one license! To be checked and adapted.
    $templateemail = $templateaccount | Select-Object -ExpandProperty EmailAddress
    $templatelicense = Get-MsolUser -UserPrincipalName $templateemail | Select-Object -ExpandProperty Licenses | Select-Object -ExpandProperty AccountSkuId
    Set-MsolUserLicense -UserPrincipalName "$email" -AddLicenses $templatelicense
    
    #Waiting for settings to be applied
    Start-Sleep -Seconds 10
}
finally {
    #Showing end results regardless of outcome
    $user = Get-ADUser $usercheck -ErrorAction Stop
    $existinguser = Get-ADUser -Identity "$usercheck" -Properties *
    $existinguser
    $existinguseremail = $existinguser.EmailAddress
    Get-MsolUser -UserPrincipalName "$existinguseremail" | Format-List UserPrincipalName, DisplayName, isLicensed, Licenses
}

Stop-Transcript