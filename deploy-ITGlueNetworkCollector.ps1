

# Glue Networking need installed .NET 4.5.2

# > offline Installer unter https://support.microsoft.com/de-de/help/2901907/microsoft-net-framework-4-5-2-offline-installer-for-windows-server-201
# https://kb.itglue.com/hc/en-us/articles/360026301251-Guide-to-successful-Network-Glue-deployment

# Installer NetworkGlue...
# https://s3.amazonaws.com/networkdetective/download/NetworkGlueCollector.msi

# 2019/31/07 Added check of logfile and automated installation .NET452 if required
# 2019/31/07 Changed download of MSI - no directly through powershell, not anymore with the datto rmm component

# Component needs parameters
# ITGLUECOLLECTORKEY


$itglueCollectorkey     = $env:ITGLUECOLLECTORKEY
$itglueNetworkcollector = "NetworkGlueCollector.msi"

New-Variable -Name binpath -Option AllScope 

function Main {
    Start-MSIInstall $itglueNetworkcollector
    Start-NetworkGlue $itglueCollectorkey
}

function Start-MSIInstall {
    param (
        $filename = $args[0]
    )
 

Get-GlueNetworkInstaller
write-host $binpath
    Write-Host $filename
    $DataStamp = get-date -Format yyyyMMddTHHmmss
    $logFile = '{0}-{1}.log' -f $filename,$DataStamp
    Write-Host $logFile
    $MSIArguments = @(
        "/i"
        ('"{0}"' -f $binpath)
        "/qn"
        "/norestart"
        "/L*v"
        $logFile
    )
    Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow
#$logfile = "NetworkGlueCollector.msi.log"
    checkLogfile

# test test test branch
    $location = Get-Location
    Write-Host $location.Path
}


function checkLogfile {
    param (
        
    )
    write-host $logFile
    
    $lines = Get-Content -Path $logFile

    foreach ($line in $lines) {
        if($line -like "*failed*" -OR $line -like "*error*" -OR $line -like "*requires*") {
            Write-Host $line
            if($line -like "*requires .NET Framework 4.5.2*") {
                Write-Host "Installing .NET452 without any reboot ..."
                Install-NET452
                Write-Host "You've to do a reboot on that machine."
            }
        }
    }

}



function Get-GlueNetworkInstaller {

    $SourceURI = "https://s3.amazonaws.com/networkdetective/download/NetworkGlueCollector.msi"
    $FileName = $SourceURI.Split('/')[-1]
    $BinPath = Join-Path $env:SystemRoot -ChildPath "Temp\$FileName"

    if (!(Test-Path $BinPath))
    {
        Invoke-Webrequest -Uri $SourceURI -OutFile $BinPath
    }
    Write-Host $FileName
    Write-Host $BinPath


}


function Install-NET452 {
    Configuration Net452Install
{
    node "localhost"
    {
 
        LocalConfigurationManager
        {
            # RebootNodeIfNeeded = $true
            RebootNodeIfNeeded = $false
        }
 
        Script Install_Net_4.5.2
        {
            SetScript = {
                $SourceURI = "https://download.microsoft.com/download/B/4/1/B4119C11-0423-477B-80EE-7A474314B347/NDP452-KB2901954-Web.exe"
                $FileName = $SourceURI.Split('/')[-1]
                $BinPath = Join-Path $env:SystemRoot -ChildPath "Temp\$FileName"
 
                if (!(Test-Path $BinPath))
                {
                    Invoke-Webrequest -Uri $SourceURI -OutFile $BinPath
                }
 
                write-verbose "Installing .Net 4.5.2 from $BinPath"
                write-verbose "Executing $binpath /q /norestart"
                Sleep 5
                Start-Process -FilePath $BinPath -ArgumentList "/q /norestart" -Wait -NoNewWindow           
                Sleep 5
                Write-Verbose "Setting DSCMachineStatus to reboot server after DSC run is completed"
                $global:DSCMachineStatus = 1
            }
 
            TestScript = {
                [int]$NetBuildVersion = 379893
 
                if (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' | %{$_ -match 'Release'})
                {
                    [int]$CurrentRelease = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release
                    if ($CurrentRelease -lt $NetBuildVersion)
                    {
                        Write-Verbose "Current .Net build version is less than 4.5.2 ($CurrentRelease)"
                        return $false
                    }
                    else
                    {
                        Write-Verbose "Current .Net build version is the same as or higher than 4.5.2 ($CurrentRelease)"
                        return $true
                    }
                }
                else
                {
                    Write-Verbose ".Net build version not recognised"
                    return $false
                }
            }
 
            GetScript = {
                if (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' | %{$_ -match 'Release'})
                {
                    $NetBuildVersion =  (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release
                    return $NetBuildVersion
                }
                else
                {
                    Write-Verbose ".Net build version not recognised"
                    return ".Net 4.5.2 not found"
                }
            }
        }
    }
}
 
Net452Install -OutputPath $env:SystemDrive:\DSCconfig
Set-DscLocalConfigurationManager -ComputerName localhost -Path $env:SystemDrive\DSCconfig -Verbose
Start-DscConfiguration -ComputerName localhost -Path $env:SystemDrive:\DSCconfig -Verbose -Wait -Force
}


function Start-NetworkGlue {
    param (
        $collectorkey = $args[0]
    )
    $COLLECTORArguments = @(
        "-i $collectorkey"
    )
   Write-Host $COLLECTORArguments
   Start-Process "C:\Program Files (x86)\Network Glue\Collector\bin\register-device.exe" -ArgumentList $COLLECTORArguments
   
    
}


Main