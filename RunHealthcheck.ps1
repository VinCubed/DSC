<#
.SYNOPSIS
   Author: Wiktoria Jedwabny, Paulina Puzio                                        
   E-mail: Wiktoria.Jedwabny@gds.ey.com, Paulina.Puzio@gds.ey.com                       
.DESCRIPTION
    Runs Set-WindowSetting.ps1 script against a CSV list of VMs.
    Creates a report (CSV) with performed change.
.PARAMETER
    None
.INPUTS
    None
.OUTPUTS
    None
.EXAMPLE
    .\Set-WindowSetting.ps1 -VmList c:\temp\vmlist.csv -Output c:\temp\changeReport.txt

.LINK
#>

param
(
    [Parameter(Mandatory)] 
    [string] $VmList,
    [Parameter(Mandatory)] 
    [string] $Output
)

#get vm list file (CSV)
$VmsToCheck = Import-Csv -Delimiter ";" -Path $VmList 
$VmsTotal = $VmsToCheck.Count
$VmsCount = 1
foreach ($vm in $VmsToCheck) {
    #set context if needed
    $CurrentSubscription = (Get-AzSubscription).Id
    $VmSubscription = $vm.'subscriptionId'
    $VmResourceGroup = $vm.'resourceGroupName'
    $VmName = $vm.'vmName'
    if ($VmSubscription -ne $CurrentSubscription) { 
        Set-AzContext -SubscriptionId $VmSubscription
    }

    #get VM OS type and proceed only with Windows VMs
    Write-Output "Current run checking VM $VmsCount/$VmsTotal  SubscriptionId: $($VmSubscription), ResourceGroupName: $($VmResourceGroup), VMName: $($VmName)"
    try {
        #$changedSettingOutput = Invoke-AzVMRunCommand -ResourceGroupName $VmResourceGroup -VMName $VmName -CommandId 'RunPowerShellScript' -ScriptPath '.\settings.ps1' -AsJob
        
        Invoke-AzVMRunCommand -ResourceGroupName $VmResourceGroup -VMName $VmName -CommandId 'RunPowerShellScript' -ScriptPath 'healthCheck-Windows.ps1' -Parameter @{vm = $vmName; subs = $VmSubscription; rsg = $VmResourceGroup} -AsJob
        
        #$ReportTable = [PSCustomObject]@{
        #    VmSubscriptionId    = $VmSubscription
        #    VmResourceGroupName = $VmResourceGroup
        #    VmName              = $VmName
        #    output              = $changedSettingOutput.Value[0].Message
        #}
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        ##Write-Error $ErrorMessage
        #$ReportTable = [PSCustomObject]@{
        #    VmSubscriptionId    = $VmSubscription
        #    VmResourceGroupName = $VmResourceGroup
        #    VmName              = $VmName
        #    output              = $ErrorMessage
        #}         
    }
    #$ReportTable | Export-Csv -Append -NoTypeInformation -Delimiter ";" -Path $Output
    #$ReportTable | Format-List *|  Out-file -FilePath $Output -Append #-NoTypeInformation -Delimiter ";"  
    
    $VmsCount += 1
}

#Grab jobs
Start-Sleep -Seconds 10

Write-output "Jobs running in background: $((Get-Job -state Running).Count)."

if (!(Test-Path $Output)) {
    $seperator="SEP=,"
    $seperator | Out-file -FilePath $Output -Append 
    $header = 'AzureVMName,"Subscription","ResourceGroup","LocalVMName","LocalIP","DNSServerIP","OsVersion","Uptime_days","CB_EMEIA","CB_AMERICAS","CB_APAC","QUALYS","SEP","LIVEUPDATE","CWP","CBService","QualysService","SEPService","CWPIDSService","CWPIPSService"' 
    $header | Out-file -FilePath $Output -Append 
}

$totalJobs = (Get-Job -state Running).Count

do {
    $completedJobs = Get-Job -state Completed
    $failedJobs =  Get-Job -State Failed
    $bkgroundjobs = Get-Job -state Running

    Write-output "Finished since last check jobs: $($completedJobs.Count)."
    $pendingJobs = $totalJob - [int]$completedJobs.Count

    Write-output "Still running jobs: $pendingJobs."

    Write-output "Failed jobs: $($failedJobs.Count)."


    foreach ($job in $completedJobs) {
        $job_id = $job.id 
        $jobOutput = Get-Job -id $job.id | Receive-Job
        get-job -id $job.id | Remove-Job
#        $outputToSave = """" + $VmName + """,""" + $VmSubscription + """,""" + $VmResourceGroup + ""","""
        $outputToSave = $jobOutput.value[0].Message
        #$job_id | Out-file -FilePath $Output -Append #-NoTypeInformation -Delimiter ";"
        $outputToSave | Format-List * |  Out-file -FilePath $Output -Append #-NoTypeInformation -Delimiter ";"
    }
    Start-Sleep -Seconds 60
} while (($pendingJobs -gt 0) -and ($bkgroundjobs -gt 0))
