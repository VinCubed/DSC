Configuration EY_W2K19_Member_CoreAgents
{
 
Param(
    [Parameter(Mandatory)]$SoftwareRepoSASToken,
    [Parameter(Mandatory)]$SoftwareRepoUri,
    [Parameter(Mandatory)]$STSSoftwareRepoSASToken,
    [Parameter(Mandatory)]$STSSoftwareRepoUri,
    [Parameter(Mandatory)]$STSSylinkName,
    [Parameter(Mandatory)]$STSQualysArguments,
    [Parameter(Mandatory)]$STSQualysName,
    [Parameter(Mandatory)]$STSSEPAgentName,
    [Parameter(Mandatory)]$STSCBAgentName,
    [Parameter(Mandatory)]$STSCBDefLocation,
    $PackagesFolder = "C:\Packages\EY",
    $QualysAgent_ProductId = "",
    $QualysAgent_Installer = "QualysCloudAgent.exe",
    $QualysAgent_DestinationPath = "$PackagesFolder\QualysCloudAgent",
    $QualysAgent_Update_Arguments ="PatchInstall=TRUE",
    $QualysCert_Installer="FIS_DEFRNVAZQUAGW01_certificate_WIN.msi",
    $QualysCert_DestinationPath = "$PackagesFolder\QualysCloudAgent",
    $QualysCertInstaller_Arguments="/quiet /Liome+!",
    $CarbonBlackAgent_ProductId = "",
    $CarbonBlackAgent_Installer = "CarbonBlackClientSetup.exe",
    $CarbonBlackAgent_ConfigFile = "sensorsettings.ini",
    $CarbonBlackAgent_DestinationPath = "$PackagesFolder\CarbonBlackAgent",
    $CarbonBlackAgent_Arguments = "/S",
    $installQualysCloudAgent = "Enabled",
    $Download_QualysCloudAgent_DestinationPath = ("{0}\{1}" -f $QualysAgent_DestinationPath, $QualysAgent_Installer),
    $Download_QualysCloudAgent_Uri = ("{0}{1}{2}" -f $STSSoftwareRepoUri, $QualysAgent_Installer, $STSSoftwareRepoSASToken),
    $Download_QualysCloudAgent_MatchSource = $true,
    $installQualysCert = "Enabled",
    $Download_QualysCert_DestinationPath = ("{0}\{1}" -f $QualysCert_DestinationPath, $QualysCert_Installer),
    $Download_QualysCert_Uri=("{0}{1}{2}" -f $STSSoftwareRepoUri, $QualysCert_Installer, $STSSoftwareRepoSASToken),
    $Download_QualysCert_MatchSource = $true,
    $installCarbonBlackAgent = "Enabled",
    $Download_CarbonBlackAgent_DestinationPath = ("{0}\{1}" -f $CarbonBlackAgent_DestinationPath, $CarbonBlackAgent_Installer),
    $Download_CarbonBlackAgent_Uri = ("{0}{1}{2}" -f $STSSoftwareRepoUri, $CarbonBlackAgent_Installer, $STSSoftwareRepoSASToken),
    $Download_CarbonBlackAgent_MatchSource = $true,
    $Download_CarbonBlackConfigFile_DestinationPath = ("{0}\{1}" -f $CarbonBlackAgent_DestinationPath, $CarbonBlackAgent_ConfigFile),
    $Download_CarbonBlackConfigFile_Uri = ("{0}{1}{2}" -f $STSSoftwareRepoUri, $CarbonBlackAgent_ConfigFile, $STSSoftwareRepoSASToken),
    $Download_CarbonBlackConfigFile_MatchSource = $true,
    $ChangeCBConsoleConfig_ManualConfig = $false,
    $DefCBLocation = $STSCBDefLocation,
    $AM_Config="sensorsettings.ini.AM",
    $APAC_Config="sensorsettings.ini.AP",
    $EMEIA_Config="sensorsettings.ini.EM",
    $SEPArchive_Name = "SEP",
    $SEPAgent_ProductId = "",
    $SEPAgent_DestinationPath = "$PackagesFolder\SEP",
    $SEPAgent_Arguments = "",
    $InstallSEP = "Enabled",
    $SEPCAgent_Name = "Symantec Endpoint Protection Cloud",
    $SEPCAgent_ProductId = "",
    $UninstallSEPC = "Enabled",
    $SEPCAgent_Arguments = "",
    $CWPAgent_Name = "Cloud Workload Protection",
    $CWPAgent_ProductId = "",
    $UninstallCWP = "Enabled",
    $CWPAgent_Arguments = "",
    $Download_Sylink_DestinationPath = ("{0}\{1}" -f $SEPAgent_DestinationPath, "sylink.xml"),
    $Download_Sylink_Name = $STSSylinkName,
    $Download_Sylink_Uri = ("{0}{1}{2}" -f $STSSoftwareRepoUri, $Download_Sylink_Name, $STSSoftwareRepoSASToken),
    $Download_SEPArchive_DestinationPath = ("{0}\{1}{2}" -f $SEPAgent_DestinationPath, $SEPArchive_Name,".zip"),
    $Download_SEPArchive_Uri = ("{0}{1}{2}{3}" -f $STSSoftwareRepoUri, $SEPArchive_Name, ".zip", $STSSoftwareRepoSASToken),
    $SEPArchive_DestinationPath = "$PackagesFolder\SEP\Installer",
    $SEPArchive_Installer = "Setup.exe",
    $Download_SEP_MatchSource = $true
)

  Import-DscResource -ModuleName "xPSDesiredStateConfiguration"
  #https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode?view=powershell-7
  
  $QualysAgent = @{
    "Name"            = $STSQualysName
    "ProductId"       = $QualysAgent_ProductId
    "Installer"       = $QualysAgent_Installer
    "DestinationPath" = $QualysAgent_DestinationPath
    "Arguments"       = $STSQualysArguments
  }

  $CarbonBlackAgent = @{
    "Name"            = $STSCBAgentName
    "ProductId"       = $CarbonBlackAgent_ProductId
    "Installer"       = $CarbonBlackAgent_Installer
    "ConfigFile"      = $CarbonBlackAgent_ConfigFile
    "DestinationPath" = $CarbonBlackAgent_DestinationPath
    "Arguments"       = $CarbonBlackAgent_Arguments
  }

  xRemoteFile Download_QualysCloudAgent {
     DestinationPath = $Download_QualysCloudAgent_DestinationPath
     Uri             = $Download_QualysCloudAgent_Uri
     MatchSource     = $Download_QualysCloudAgent_MatchSource
  }

  xRemoteFile Download_QualysCert {
     DestinationPath = $Download_QualysCert_DestinationPath
     Uri             = $Download_QualysCert_Uri
     MatchSource     = $Download_QualysCert_MatchSource
  }

  if($installQualysCloudAgent -eq 'Enabled') {
    xPackage Install_QualysCloudAgent {
      Name          = $STSQualysName
      ProductId     = $QualysAgent_ProductId
      Path          = ("{0}\{1}" -f $QualysAgent_DestinationPath, $QualysAgent_Installer)
      Arguments     = $STSQualysArguments
      DependsOn     = "[xRemoteFile]Download_QualysCloudAgent"
    }


    Script InstallQualysCert {
       GetScript = { }
       TestScript = {$false}
       SetScript = {
          Start-Process -FilePath $("{0}\{1}" -f $using:Download_QualysCert_DestinationPath, $using:QualysCert_Installer) -ArgumentList $using:QualysCertInstaller_Arguments
       }
    }
  }

  xRemoteFile Download_CarbonBlackAgent {
     DestinationPath = $Download_CarbonBlackAgent_DestinationPath
     Uri             = $Download_CarbonBlackAgent_Uri
     MatchSource     = $Download_CarbonBlackAgent_MatchSource
  }

 xScript ChangeCBConsoleConfig {
    GetScript = {@{}}
    TestScript = { $False }
    SetScript = {
      if ( $using:ChangeCBConsoleConfig_ManualConfig -eq $false ) {


# Updated location check to add error trapping -- 06/03/2021 -- VA3
# Code was -         $Location = (Invoke-RestMethod -Headers @{"Metadata"="true"} -URI http://169.254.169.254/metadata/instance?api-version=2017-08-01 -Method get | select -expandproperty Compute | select -expandproperty location)

        Try { 
        $Location = (Invoke-RestMethod -Headers @{"Metadata"="true"} -URI http://169.254.169.254/metadata/instance?api-version=2017-08-01 -Method get | select -expandproperty Compute | select -expandproperty location)
        Write-Verbose -Message ("Calculated Location = $Location")
        }
        Catch {
        $Location = "locfail"
        Write-Verbose -Message ("Error trapped Location = $Location")
        }

        # End location check update -- 06/03/2021

        switch ($Location)
        {
          "eastus" { $Config = $using:AM_Config }
          "eastus2" { $Config = $using:AM_Config }
          "centralus" { $Config = $using:AM_Config }
          "westus" { $Config = $using:AM_Config }
          "westus2" { $Config = $using:AM_Config }
          "westcentralus" { $Config = $using:AM_Config }
          "northcentralus" { $Config = $using:AM_Config }
          "southcentralus" { $Config = $using:AM_Config }
          "canadacentral" { $Config = $using:AM_Config }
          "canadaeast" { $Config = $using:AM_Config }
          "brazilsouth" { $Config = $using:AM_Config }
          "francecentral" { $Config = $using:EMEIA_Config }
          "francesouth" { $Config = $using:EMEIA_Config }
          "uksouth" { $Config = $using:EMEIA_Config }
          "ukwest" { $Config = $using:EMEIA_Config }
          "northeurope" { $Config = $using:EMEIA_Config }
          "westeurope" { $Config = $using:EMEIA_Config }
          "southeastasia" { $Config = $using:APAC_Config }
          "southindia" { $Config = $using:APAC_Config }
          "centralindia" { $Config = $using:APAC_Config }
          "westindia" { $Config = $using:APAC_Config }
          "eastasia" { $Config = $using:APAC_Config }
          "southeastasia" { $Config = $using:APAC_Config }
          "australiaeast" { $Config = $using:APAC_Config }
          "australiasoutheast" { $Config = $using:APAC_Config }
          "japanwest" { $Config = $using:APAC_Config }
          "japaneast" { $Config = $using:APAC_Config }
          "koreacentral" { $Config = $using:APAC_Config }
          "koreasouth" { $Config = $using:APAC_Config }
          "locfail" { $Config = $using:DefCBLocation }
          Default { $Config = $using:DefCBLocation }
        }
      } else {
       $Config = $using:DefCBLocation
      }
    Write-Verbose -Message ("Configuration to use = $Config")
    $Download_CarbonBlackConfigFile_Uri = ("{0}{1}{2}" -f $using:STSSoftwareRepoUri, $Config, $using:STSSoftwareRepoSASToken)
    Write-Verbose -Message ("Configuration URI = $Download_CarbonBlackConfigFile_Uri")
    Invoke-WebRequest -Uri $Download_CarbonBlackConfigFile_Uri -OutFile $using:Download_CarbonBlackConfigFile_DestinationPath

  }
  }

  if($installCarbonBlackAgent -eq 'Enabled') {
    xScript Install_CarbonBlack {
      GetScript = {@{}}
      TestScript = {
          if((Get-ItemProperty -Path "HKLM:\Software\ServerInfo\" -ErrorAction SilentlyContinue | select -expandproperty SBPProduct) -eq "CaaS"){
              $true
          } else {
              $servicePresent=Get-Service -Name carbonblack -ErrorAction SilentlyContinue
              if($servicePresent) {
                  $true
              } else {
                  $false
              }
          }
      }
      SetScript = {
          Start-Process -FilePath $("{0}\{1}" -f $using:CarbonBlackAgent_DestinationPath, $using:CarbonBlackAgent_Installer) -ArgumentList $using:CarbonBlackAgent_Arguments
      }
    }
  }

  xRemoteFile Download_Archive {
     DestinationPath = $Download_SEPArchive_DestinationPath
     Uri             = $Download_SEPArchive_Uri
     MatchSource     = $Download_SEP_MatchSource
  }
  
    Script ExtractSEP {
       GetScript = { }
       TestScript = {$false}
       SetScript = {
                    Expand-Archive -LiteralPath $using:Download_SEPArchive_DestinationPath -DestinationPath $using:SEPArchive_DestinationPath -force
       }
    }


  xRemoteFile Download_Sylink {
     DestinationPath = ("{0}\{1}\{2}" -f $SEPArchive_DestinationPath, $SEPArchive_Name, "sylink.xml")
     Uri             = $Download_Sylink_Uri
     MatchSource     = $Download_SEP_MatchSource
  }

  if ($UninstallCWP -eq 'Enabled') {
    xPackage Uninstall_CWP {
      Name          = $CWPAgent_Name
      ProductId     = $CWPAgent_ProductId
      Ensure        = "Absent"
      Arguments     = $CWPAgent_Arguments
      Path          = ("{0}\{1}\{2}" -f $SEPArchive_DestinationPath, $SEPArchive_Name, $SEPArchive_Installer)
    }
    }

  if ($UninstallSEPC -eq 'Enabled') {
    xPackage Uninstall_SEPC {
      Name          = $SEPCAgent_Name
      ProductId     = $SEPCAgent_ProductId
      Ensure        = "Absent"
      Arguments     = $SEPCAgent_Arguments
      Path          = ("{0}\{1}\{2}" -f $SEPArchive_DestinationPath, $SEPArchive_Name, $SEPArchive_Installer)
    }
    }

  Script FixBrokenSEPAgent {
     GetScript = { }
     TestScript = {
                   Write-Verbose -Message ('In TestScript')
                   $res = $true
                   if (test-path "HKLM:\SOFTWARE\Symantec\Symantec Endpoint Protection\CurrentVersion\Public-Opstate")
                   {
                     $publicOpstate = Get-Item -path "HKLM:\SOFTWARE\Symantec\Symantec Endpoint Protection\CurrentVersion\Public-Opstate"
                     $val = $publicOpstate.GetValue("LastServerIP")
                     Write-Verbose -Message ("LastServerIP = $val")
                     if (($val -eq $Null) -or ($val -eq ""))
                     {
                      $res = $false
                     }
                   }
                   return $res
                   }
     SetScript = { 
                   Write-Verbose -Message ('In SetScript')
                   $cmd = "C:\Program Files (x86)\Symantec\Symantec Endpoint Protection\SMC.exe" 
                   $args = "-importsylink " + $using:SEPArchive_DestinationPath + "\"+ $using:SEPArchive_Name + "\sylink.xml"
                   Write-Verbose -Message ("SEP Command = $cmd $args")
                   Start-Process $cmd -ArgumentList $args
                 }
   }

  if ($InstallSEP -eq 'Enabled') {
    xPackage Install_SEP {
      Name          = $STSSEPAgentName
      ProductId     = $SEPAgent_ProductId
      Ensure        = "Present"
      Path          = ("{0}\{1}\{2}" -f $SEPArchive_DestinationPath, $SEPArchive_Name, $SEPArchive_Installer)
      Arguments     = $SEPAgent_Arguments
      DependsOn     = "[xRemoteFile]Download_Archive"
    }
  }

  xServiceSet CoreInfoSecServices
    {
            Name        = @("CarbonBlack", "SepMasterService", "QualysAgent")
            Ensure      = "Present"
            StartupType = "Automatic"
            State       = "Running"
    }

}