# The purpose is to take a CSV file of names & disable each user.
# Just put the location of the CSV & it'll disable every user in the "samAccountName" column of the csv
Import-Module ActiveDirectory
clear
$fileLocation = Read-Host "full path of csv"
Import-CSV $fileLocation | ForEach-Object {
  $samAccountName = $_."samAccountName"
  Get-ADUser -Identity $samAccountName | Disable-ADAccount
}
