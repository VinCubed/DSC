$counter=1



$inputCSV=Get-content -Path "$HOME/List.csv"
$inputCSV
connect-azaccount



foreach($machine in $inputCSV){



$vm=$machine.Split(";")[0]
$Subs=$machine.Split(";")[1]
$rsg=$machine.Split(";")[2]



Write-Host "Setting Context to Subscription $Subs" -ForegroundColor Green



Write-Host "Starting Job for getting logs from $vm from resource group $rsg" -ForegroundColor Green



Set-AzContext -SubscriptionId $subs
Invoke-AzVMRunCommand -ResourceGroupName $rsg -VMName $vm -CommandId 'RunShellScript' -ScriptPath "$HOME/LinuxDSC.sh" -asjob



Write-Host "Machines elapsed so far $counter"
$counter++



}