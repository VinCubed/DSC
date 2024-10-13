Connect-AzAccount
$azvm = Get-AzVM -Name AC1DIAC00XMVM01
echo $azvm.ResourceGroupName
