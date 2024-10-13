$counter=1

$inputCSV=Get-content -Path .\List.csv
$inputCSV

#EYGS,ff2e6fd9-9e3b-4e97-b5ea-d65f0247b1ca,7MD2028dw!412VhANvnq5x14XI0PRGWZ,5b973f99-77df-4beb-b27d-aa0c70b8482c
#EYDEV,9edd450e-3a49-4711-92b2-7e74947709cb,!20KShD9WtEV314QT0#17xHp1911w6RFyO,4667418b-7015-4ceb-b207-2193896769a8

#connect-azaccount -Tenant 5b973f99-77df-4beb-b27d-aa0c70b8482c -UseDeviceAuthentication
Connect-AzAccount
foreach($machine in $inputCSV){

$vm=$machine.Split(";")[0]
$Subs=$machine.Split(";")[1]
$rsg=$machine.Split(";")[2]

Write-Host "Setting Context to Subscription $Subs" -ForegroundColor Green

Write-Host "Starting Job for getting logs from $vm from resource group $rsg" -ForegroundColor Green

Set-AzContext -SubscriptionId $subs
Invoke-AzVMRunCommand -ResourceGroupName $rsg -VMName $vm -CommandId 'RunPowerShellScript' -ScriptPath .\CBHealthCheck.ps1 -Parameter @{vm = $vm ; subs = $Subs; rsg=$rsg} -asjob

Write-Host "Machines elapsed so far $counter"
$counter++

}

