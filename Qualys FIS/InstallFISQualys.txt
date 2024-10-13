if(!(test-path C:\Packages))
{
    mkdir C:\Packages
}

# Download FIS Qualys installer from SA

$RepoURI = "https://useddevstssta05.blob.core.windows.net"
$RepoSAS = "?sv=2021-06-08&ss=b&srt=co&sp=r&se=2023-08-16T00:00:54Z&st=2022-08-10T13:48:54Z&spr=https&sig=aGHD7uwvu8HvJCDcQ07Qhfd07daxuA%2BsljxXiaUwO%2Fs%3D"

$BlobUri = "$RepoURI/windows/QualysCloudAgent-FIS.exe"
$OutputPath = 'C:\Packages\QualysCloudAgent.exe'
$FullUri = "$BlobUri$RepoSas"

Invoke-WebRequest -useBasicParsing -Uri $FullUri -OutFile $OutputPath

# Download Qualys cert installer from SA

$BlobUri = "$RepoURI/windows/FIS_DEFRNVAZQUAGW01_certificate_WIN.msi"
$OutputPath = 'C:\Packages\FIS_DEFRNVAZQUAGW01_certificate_WIN.msi'
$FullUri = "$BlobUri$RepoSas"

Invoke-WebRequest -useBasicParsing -Uri $FullUri -OutFile $OutputPath

$RemoteArgument1 = Get-Content 'C:\Packages\FIS_DEFRNVAZQUAGW01_certificate_WIN.msi' -Raw

Invoke-WebRequest -useBasicParsing -Uri $FullUri -OutFile $OutputPath

# Download Qualys activation changer from SA

$BlobUri = "$RepoURI/windows/QualysAgentActivation.exe"
$OutputPath = 'C:\Packages\QualysAgentActivation.exe'
$FullUri = "$BlobUri$RepoSas"

Invoke-WebRequest -useBasicParsing -Uri $FullUri -OutFile $OutputPath

$InvokeOutput = @()
$out = @()

    $hostname = hostname
    $RemoteArgument2 = $RemoteArgument1

    write-host "Checking if Qualys is installed already or not on $hostname"

    $x86 = ((Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall") |
                Where-Object { $_.GetValue( "DisplayName" ) -like "Qualys Cloud Security Agent" } ).Length -gt 0;
    
    $x64 = ((Get-ChildItem "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall") |
                Where-Object { $_.GetValue( "DisplayName" ) -like "Qualys Cloud Security Agent" } ).Length -gt 0;


    If($x86 -eq "True" -or $x64 -eq "True") {

   ## Changing activation ID

    write-host "Changing Qualys Activation ID"
    cmd.exe /c "C:\Packages\QualysAgentActivation.exe ActivationId={c1f90f4f-6a99-4c84-bd5b-e8c0f2ed57f5}" | Out-Null
    Write-Host "Qualys Activation ID has been changed on $hostname"

    }
    else
    {

    ## Installing Qualys Agent ##

    write-host "Installing qualys"
    cmd.exe /c "C:\Packages\QualysCloudAgent.exe CustomerId={ba0abb1e-6647-8c5d-e040-10ac6b047499} ActivationId={c1f90f4f-6a99-4c84-bd5b-e8c0f2ed57f5} WebServiceUri=https://qagpublic.qg1.apps.qualys.com/CloudAgent/" | Out-Null
    Write-Host "Qualys has been installed on $hostname"
    }


    Start-Process msiexec.exe -ArgumentList '/I C:\Packages\FIS_DEFRNVAZQUAGW01_certificate_WIN.msi /quiet /Liome+! C:\Packages\FIS_DEFRNVAZQUAGW01_certificate_WIN.msi.log' -Wait
    if ((cat 'C:\Packages\FIS_DEFRNVAZQUAGW01_certificate_WIN.msi.log') -like "*Installation completed successfully*") 
        {
            $CertificateInstall = "Success"
        } 
    else 
        {
            $CertificateInstall = "Failed"
                    
        }

    #Configure Proxy

    write-host "Configuring the agent proxy"

    Copy-Item -Path "C:\Program Files\Qualys\QualysAgent\QualysProxy.exe" -Destination "C:\Packages\" -Force

    cmd.exe /c "C:\Packages\QualysProxy.exe /d" | Out-Null
    cmd.exe /c "C:\Packages\QualysProxy.exe /u 10.151.177.40:8080" | Out-Null ## Proxy need to update based on details

    Restart-Service -Name QualysAgent | Out-Null

    $service = Get-Service -Name QualysAgent
    $serviceStatus = $service.Status

    $VersionCheck = (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall") | Where-Object { $_.GetValue( "DisplayName" ) -like "Qualys Cloud Security Agent" }

    $QualysVersion = $VersionCheck.GetValue('DisplayVersion')

    $USPILVAZQUAGW01 = (test-NetConnection -ComputerName 10.145.250.40 -Port 8080 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).TcpTestSucceeded
    $DEFRNVAZQUAGW01 = (test-NetConnection -ComputerName 10.151.177.40 -Port 8080 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).TcpTestSucceeded
    $SGSINVAZQUAGW01 = (test-NetConnection -ComputerName 10.146.185.150 -Port 8080 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).TcpTestSucceeded
                    
    $CertThumbprint = (Get-ChildItem -path cert:\LocalMachine\ -Recurse | ? {$_.DnsNameList -like "*qgs.proxy*"}).thumbprint

    $GatewayURL = (Get-ItemProperty -Path HKLM:\SOFTWARE\Qualys\Proxy -ErrorAction SilentlyContinue).url
    $GatewayURLisCorrect = if ($GatewayURL -eq "10.145.250.40:8080" -or $GatewayURL -eq "10.151.177.40:8080" -or $GatewayURL -eq "10.146.185.150:8080") {$true} else {$false}

    $ServiceOutput = @()

    $ServiceOutput = New-Object psobject -property @{
                ServerName = $hostname
                QualysStatus = $serviceStatus
                QualysVersion = $QualysVersion
                CertThumbprint = $CertThumbprint
                USPILVAZQUAGW01 = $USPILVAZQUAGW01
                DEFRNVAZQUAGW01 = $DEFRNVAZQUAGW01
                SGSINVAZQUAGW01 = $SGSINVAZQUAGW01
                GatewayURL = $GatewayURL
                GatewayURLisCorrect = $GatewayURLisCorrect
                }
    $ServiceOutput


    if ($InvokeOutput) {
                
        $InvokeOutput
            
    } 
    else {
              
    "" | select @{n='ServerName';e={$computer}},USPILVAZQUAGW01, DEFRNVAZQUAGW01, SGSINVAZQUAGW01, CertThumbprint, GatewayURL, GatewayURLisCorrect, QualysVersion, @{n='QualysStatus';e={"Failed to connect"}}
    Write-Host "$computer - Failed to connect"
            
    }


Write-Output "Qualys Installed"
$service=Get-service QualysAgent -ErrorAction SilentlyContinue
Write-Output $service
