## Script starts here ##

write-host "Script started." -ForegroundColor Green

## Qualys Remote Installation ##

$QualysFilePath = "C:\temp\QualysInstallation"
$QualysOutputFile = "C:\temp\QualysOutput.csv"

$RemoteArgument1 = Get-Content 'C:\temp\QualysInstallation\FIS_DEFRNVAZQUAGW01_certificate_WIN.msi' -Raw

$InvokeOutput = @()
$out = @()

## Please enter target servers name below ##

$computers = @(
"server1"
"server2"
)

$out = ForEach ($computer in $computers)
{

        Copy-Item -ToSession $(New-PSSession -ComputerName $computer) -Path $QualysFilePath -Destination "C:\temp\" -Force -Recurse #-Verbose


        $InvokeOutput = Invoke-Command -ComputerName $computer -ScriptBlock {
        Param($RemoteArgument1)

            ## Checking Qualys Installed or not ##

            $hostname = hostname
            $RemoteArgument2 = $RemoteArgument1

            write-host "Checking qualys installed already or not on $hostname"

            $x86 = ((Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall") |
                        Where-Object { $_.GetValue( "DisplayName" ) -like "Qualys Cloud Security Agent" } ).Length -gt 0;
    
            $x64 = ((Get-ChildItem "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall") |
                        Where-Object { $_.GetValue( "DisplayName" ) -like "Qualys Cloud Security Agent" } ).Length -gt 0;


            If($x86 -eq "True" -or $x64 -eq "True") {

            ## Uninstalling already installed agent ##

            write-host "Removing existing qualys on $hostname"

            Copy-Item -Path "C:\Program Files\Qualys\QualysAgent\Uninstall.exe" -Destination "C:\temp\QualysInstallation\" -Force

            cmd.exe /c "C:\temp\QualysInstallation\Uninstall.exe uninstall=true force=true" | Out-Null ## Need to update path

            write-host "Sleeping for 10 seconds before reinstalling"

            sleep -Seconds 10

            ## Installing Qualys Agent ##

            write-host "Installing qualys"
            cmd.exe /c "C:\temp\QualysInstallation\QualysCloudAgent.exe CustomerId={ba0abb1e-6647-8c5d-e040-10ac6b047499} ActivationId={c1f90f4f-6a99-4c84-bd5b-e8c0f2ed57f5} WebServiceUri=https://qagpublic.qg1.apps.qualys.com/CloudAgent/" | Out-Null
            Write-Host "Qualys has been installed on $hostname"


            }
            else
            {

            ## Installing Qualys Agent ##

            write-host "Installing qualys"
            cmd.exe /c "C:\temp\QualysInstallation\QualysCloudAgent.exe CustomerId={ba0abb1e-6647-8c5d-e040-10ac6b047499} ActivationId={c1f90f4f-6a99-4c84-bd5b-e8c0f2ed57f5} WebServiceUri=https://qagpublic.qg1.apps.qualys.com/CloudAgent/" | Out-Null
            Write-Host "Qualys has been installed on $hostname"
            }


            $RemoteArgument2 | Set-Content -Path C:\temp\QualysInstallation\FIS_DEFRNVAZQUAGW01_certificate_WIN.msi -Force

            Start-Process msiexec.exe -ArgumentList '/I C:\temp\QualysInstallation\FIS_DEFRNVAZQUAGW01_certificate_WIN.msi /quiet /Liome+! C:\temp\QualysInstallation\FIS_DEFRNVAZQUAGW01_certificate_WIN.msi.log' -Wait
            if ((cat 'C:\temp\QualysInstallation\FIS_DEFRNVAZQUAGW01_certificate_WIN.msi.log') -like "*Installation completed successfully*") 
                {
                    $CertificateInstall = "Success"
                } 
            else 
                {
                    $CertificateInstall = "Failed"
                    
                }

            #Configure Proxy

            write-host "Configuring the agent proxy"

            Copy-Item -Path "C:\Program Files\Qualys\QualysAgent\QualysProxy.exe" -Destination "C:\temp\QualysInstallation\" -Force

            cmd.exe /c "C:\temp\QualysInstallation\QualysProxy.exe /d" | Out-Null
            cmd.exe /c "C:\temp\QualysInstallation\QualysProxy.exe /u 10.151.177.40:8080" | Out-Null ## Proxy need to update based on details

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

            } -ArgumentList $RemoteArgument1

            if ($InvokeOutput) {
                
                $InvokeOutput
            
            } 
            else {
              
            "" | select @{n='ServerName';e={$computer}},USPILVAZQUAGW01, DEFRNVAZQUAGW01, SGSINVAZQUAGW01, CertThumbprint, GatewayURL, GatewayURLisCorrect, QualysVersion, @{n='QualysStatus';e={"Failed to connect"}}
            Write-Host "$computer - Failed to connect"
            
            }

}

write-host "Script completed." -ForegroundColor Green

$out | select ServerName, USPILVAZQUAGW01, DEFRNVAZQUAGW01, SGSINVAZQUAGW01, CertThumbprint, GatewayURL, GatewayURLisCorrect, QualysVersion, QualysStatus | Export-csv $QualysOutputFile -notypeInformation

