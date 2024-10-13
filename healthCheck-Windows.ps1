################ BEGIN OF THE SCRIPT ################
####Script Created By Guido Ierache - 02/06/2021

 Param(
    [string]$vm,
    [string]$subs,
    [string]$rsg
 )



$CBUrls=@()
$hostname=hostname
$ipconfiguration = Get-NetIPConfiguration
$IPaddress = ($ipconfiguration.IPv4Address | Select-Object -Expand "IPAddress") -join ','
$DNSServer=  ($ipconfiguration.DNSServer | Select-Object -Expand "ServerAddresses") -join ','
$vmTested = New-Object -TypeName PSObject
$uptime=((get-date) - (gcim Win32_OperatingSystem).LastBootUpTime).days
$osversion = $(((gcim Win32_OperatingSystem -ComputerName $server.Name).Name).split('|')[0])
$vmTested| Add-Member -MemberType NoteProperty -Name 'AzureVMName' -Value $vm
$vmTested| Add-Member -MemberType NoteProperty -Name 'Subscription' -Value $subs
$vmTested| Add-Member -MemberType NoteProperty -Name 'ResourceGroup' -Value $rsg
$vmTested| Add-Member -MemberType NoteProperty -Name 'LocalVMName' -Value $hostname.ToString()
$vmTested| Add-Member -MemberType NoteProperty -Name 'LocalIP' -Value $IPaddress.ToString()
$vmTested| Add-Member -MemberType NoteProperty -Name 'DNSServerIP' -Value $DNSServer.ToString()
$vmTested| Add-Member -MemberType NoteProperty -Name 'OsVersion' -Value $osVersion.ToString()
$vmTested| Add-Member -MemberType NoteProperty -Name 'Uptime_days' -Value $uptime
$AgentsUrls=
@"
sensors.smooth-owl.my.cbcloud.de,443,CB_EMEIA
sensors.marvellous-elephant.my.carbonblack.io,443,CB_AMERICAS
sensors.powerful-flamingo.my.cbcloud.sg,443,CB_APAC
qagpublic.qg1.apps.qualys.com,443,QUALYS
sepm.ey.com,443,SEP
liveupdate.symantec.com,80,LIVEUPDATE
scwp.securitycloud.symantec.com,443,CWP
"@

foreach($URL in $AgentsUrls -split "`r`n")
{

    $URLArray=$URL.Split(",")
    $server=$URLArray[0]
    $runningPort=$URLArray[1]
    $zone=$URLArray[2]
    $testing= Test-NetConnection $server -port $runningPort -InformationLevel Detailed -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    if($testing.TcpTestSucceeded -eq $true)
    {
        $vmTested| Add-Member -MemberType NoteProperty -Name $zone -Value 'OK'
    }
    else
    {
        if($testing.NameResolutionSucceeded -eq $false)
        {
            $vmTested| Add-Member -MemberType NoteProperty -Name $zone -Value 'DNS Resolution Issue'
        }
        else
        {
            $vmTested| Add-Member -MemberType NoteProperty -Name $zone -Value 'Port Blocked'
        }
    }
}

$service=get-service CarbonBlack -ErrorAction SilentlyContinue
if($service -ne $null)
{
    $vmTested| Add-Member -MemberType NoteProperty -Name "CBService" -Value $service.Status.ToString()
}
else
{
    $vmTested| Add-Member -MemberType NoteProperty -Name "CBService" -Value "Service Not Found"
}

$service=Get-service QualysAgent -ErrorAction SilentlyContinue
if($service -ne $null)
{
    $vmTested| Add-Member -MemberType NoteProperty -Name "QualysService" -Value $service.Status.ToString()
}
else
{
    $vmTested| Add-Member -MemberType NoteProperty -Name "QualysService" -Value "Service Not Found"
}

$service=Get-service SepMasterService -ErrorAction SilentlyContinue
if($service -ne $null)
{
    $vmTested| Add-Member -MemberType NoteProperty -Name "SEPService" -Value $service.Status.ToString()
}
else
{
    $vmTested| Add-Member -MemberType NoteProperty -Name "SEPService" -Value "Service Not Found"
}

$service=Get-service SISIDSService -ErrorAction SilentlyContinue
if($service -ne $null)
{
    $vmTested| Add-Member -MemberType NoteProperty -Name "CWPIDSService" -Value $service.Status.ToString()
}
else
{
    $vmTested| Add-Member -MemberType NoteProperty -Name "CWPIDSService" -Value "Service Not Found"
}


$service=Get-service SISIPSService -ErrorAction SilentlyContinue
if($service -ne $null)
{
    $vmTested| Add-Member -MemberType NoteProperty -Name "CWPIPSService" -Value $service.Status.ToString()
}
else
{
    $vmTested| Add-Member -MemberType NoteProperty -Name "CWPIPSService" -Value "Service Not Found"
}



$json = $vmTested | ConvertTo-CSV -NoTypeInformation | select-object -skip 1 
Write-Output $json
