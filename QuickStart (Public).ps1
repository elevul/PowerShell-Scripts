# QuickStart

$date = Get-Date -Format "MMddyyyy-HHmm"

Import-Module ActiveDirectory

Connect-MsolService

Connect-ExchangeOnline

$start = "C:\Log-$date.log"

$term = "‪C:\TerminatingUser (Current).ps1"