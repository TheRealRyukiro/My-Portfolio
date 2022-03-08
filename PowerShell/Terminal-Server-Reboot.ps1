Clear-Host


while($true){
    $server = Read-Host "Enter Terminal Server to reboot"
    Restart-Computer -Force -ComputerName $server -Wait -For PowerShell -Timeout 300 -Delay 2 -Credential "USERNAME"
    Write-Host "$server reboot complete! log in to make sure it's functional"
}