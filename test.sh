Connect-AzAccount
$azvm = Get-AzVM -Name ACEMNLPXORAP03
echo $azvm.ResourceGroupName
