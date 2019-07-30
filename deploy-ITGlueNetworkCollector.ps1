# .NET 4.5.2 ist notwendig
# > offline Installer unter https://support.microsoft.com/de-de/help/2901907/microsoft-net-framework-4-5-2-offline-installer-for-windows-server-201
# https://kb.itglue.com/hc/en-us/articles/360026301251-Guide-to-successful-Network-Glue-deployment


# Component needs parameters
# ITGLUECOLLECTORKEY


$itglueCollectorkey     = $env:ITGLUECOLLECTORKEY
$itglueNetworkcollector = "NetworkGlueCollector.msi"

function Main {
    Start-MSIInstall $itglueNetworkcollector
    Start-NetworkGlue $itglueCollectorkey
}

function Start-MSIInstall {
    param (
        $filename = $args[0]
    )
 
    Write-Host $filename
    $DataStamp = get-date -Format yyyyMMddTHHmmss
    $logFile = '{0}-{1}.log' -f $filename,$DataStamp
    Write-Host $logFile
    $MSIArguments = @(
        "/i"
        ('"{0}"' -f $filename)
        "/qn"
        "/norestart"
        "/L*v"
        $logFile
    )
    Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow 

    $location = Get-Location
    Write-Host $location.Path
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