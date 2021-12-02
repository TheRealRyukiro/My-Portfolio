clear
while($true){
    # This is to remotely reboot the servers so that you don't have to tediously log into each one & reboot it. 
    # Just run this type the server name and your credentials & it'll restart
    $server = Read-Host "Enter Terminal Server to reboot"
    Restart-Computer -Force -ComputerName $server -Wait -For PowerShell -Timeout 300 -Delay 2 -Credential "apnordunb"
    Write-Host "$server reboot complete! log in to make sure it's functional"
}
