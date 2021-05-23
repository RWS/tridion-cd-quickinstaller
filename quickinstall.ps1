<#
.SYNOPSIS
    This script installs and pre-configures the Tridion Content Delivery Microservices.

.DESCRIPTION
    This script is intended to simplify setup of the Content Delivery Microservices from installation media.
    It may install or uninstall all services in one go or implementer can choose which services will be affected by specifying additional parameters.
    It is possible to enable auto registration for installed services and to manually specify URLs for each service.
    To get services up and running, implementer should edit setenv.ps1 file to provide database credentials for all services before running this script. Alternatively same can be done by editing cd_storage_conf.xml of each installed service after running the script.

.PARAMETER help
    Prints this help.

.PARAMETER sites
    Enables Tridion Sites product installation.

.PARAMETER docs
    Enables Tridion Docs product installation.

.PARAMETER dx
    Enables Tridion DX (Docs & Sites) product installation.

.PARAMETER all
    Enables all services to be installed.

.PARAMETER install
    Installs all enabled services as windows service (The services should already be in target location).

.PARAMETER services-folder
    The folder of layout roles. Default value is ".\..\..\roles"

.PARAMETER target-folder
    The folder where all services will be installed. Default value is "C:\SDL\Tridion"

.PARAMETER environment-file
    The local environment file (default setenv.ps1)

.PARAMETER auto-register
    This flag enables auto registration of installed services.

.PARAMETER remove-services
    If this parameter is set all roles installed in a target-folder will be uninstalled but their home directories will remain.

.PARAMETER clean-target
    It this parameter is set, the target folder will be cleaned.

.PARAMETER enable-cid
    Enables Contextual Image Delivery Service to be installed.

.PARAMETER enable-content
    Enables Content Service to be installed.

.PARAMETER enable-context
    Enables Context Service to be installed.

.PARAMETER enable-deployer
    Enables Deployer Service to be installed.

.PARAMETER enable-deployer-worker
    Enables Deployer Worker Service to be installed.

.PARAMETER enable-deployer-combined
    Enables Deployer Combined Service to be installed.

.PARAMETER enable-discovery
    Enables Discovery Service to be installed.

.PARAMETER enable-iq-index
    Enables IQ Index Service to be installed (Docs / DX only).

.PARAMETER enable-iq-query
    Enables IQ Query Service to be installed (Docs / DX only).

.PARAMETER enable-iq-combined
    Enables IQ Combined Service to be installed (Docs / DX only).

.PARAMETER enable-monitoring
    Enables monitoring role to be installed.

.PARAMETER enable-preview
    Enables Preview Service to be installed (Sites / DX only).

.PARAMETER enable-session
    Enables Session-enabled Content Service to be installed (Sites / DX only).

.PARAMETER enable-ugc-community
    Enables UGC Community Service to be installed.

.PARAMETER enable-ugc-moderation
    Enables UGC Moderation Service to be installed.

.PARAMETER enable-xo-management
    Enables XO Management Service to be installed (Sites / DX only).

.PARAMETER enable-xo-query
    Enables XO Query Service to be installed (Sites / DX only).

.PARAMETER content-url
    Specifies Content Service URL. Default value is http://<localhost_IP>:8081/content.svc

.PARAMETER cid-url
    Specifies Cid Service URL. Default value is http://<localhost_IP>:8088/cid

.PARAMETER context-url
    Specifies Context Service URL. Default value is http://<localhost_IP>:8087/context.svc

.PARAMETER discovery-url
    Specifies Discovery Service URL. Default value is http://<localhost_IP>:8082/discovery.svc

.PARAMETER deployer-url
    Specifies Deployer Service URL. Default value is http://<localhost_IP>:8084/v2

.PARAMETER deployer-worker-url
    Specifies Deployer Worker URL. Default value is http://<localhost_IP>:8089

.PARAMETER elasticsearch-url
    Specifies the Elasticsearch URL. Default value is http://<localhost_IP>:9200

.PARAMETER iq-index-url
    Specifies IQ Index Service URL. Default value is http://<localhost_IP>:8097/index.svc

.PARAMETER iq-query-url
    Specifies IQ Query Service URL. Default value is http://<localhost_IP>:8098/search.svc

.PARAMETER preview-url
    Specifies Preview Service URL. Default value is http://<localhost_IP>:8083/ws/preview.svc

.PARAMETER session-url
    Specifies Session Service URL. Default value is http://<localhost_IP>:8081/content.svc

.PARAMETER token-url
    Specifies Token Service URL. Default value is http://<localhost_IP>:8082/token.svc

.PARAMETER ugc-community-url
    Specifies UGC Community Service URL. Default value is http://<localhost_IP>:8085/community.svc

.PARAMETER ugc-moderation-url
    Specifies UGC Moderation Service URL. Default value is http://<localhost_IP>:8086/moderation.svc

.PARAMETER xo-management-url
    Specifies XO Management Service URL. Default value is http://<localhost_IP>:8093/management.svc

.PARAMETER xo-query-url
    Specifies XO Query Service URL. Default value is http://<localhost_IP>:8094/query.svc

.EXAMPLE
    quickinstall.ps1 -all
    Copies all roles from layout and install as windows services

.EXAMPLE
    quickinstall.ps1 -docs -all -auto-register
    Copies all Tridion Docs product roles and installs them as windows services with auto registration enabled.

.EXAMPLE
    quickinstall.ps1 -all -services-folder "C:\layout\roles"
    Copies all roles from custom location and install them as windows services.

.EXAMPLE
    quickinstall.ps1 -all -install
    Installs all roles already copied to target folder as windows services.

.EXAMPLE
    quickinstall.ps1  -enable-deployer -enable-deployer-worker -enable-content -discovery-url "http://10.0.1.56:8082/discovery.svc"
    Copies deployer, deployer-worker and content roles and installs them as windows services. Sets custom discovery URL for these services.

.EXAMPLE
    quickinstall.ps1 -remove-services
    Stops and removes all installed to target folder roles from windows services.

.EXAMPLE
    quickinstall.ps1 -clean-target
    Removes all roles installed on target location and cleans up target folder.

#>
param (
    [Alias("a")][switch]$all = $false,
    [Alias("h")][switch]$help = $false,
    [Alias("i")][switch]$install = $false,

    [switch]${sites} = $false,
    [switch]${docs} = $false,
    [switch]${dx} = $false,

    [switch]${enable-cid} = $false,
    [switch]${enable-content} = $false,
    [switch]${enable-context} = $false,
    [switch]${enable-deployer} = $false,
    [switch]${enable-deployer-combined} = $false,
    [switch]${enable-deployer-worker} = $false,
    [switch]${enable-discovery} = $false,
    [switch]${enable-iq-combined} = $false,
    [switch]${enable-iq-index} = $false,
    [switch]${enable-iq-query} = $false,
    [switch]${enable-monitoring} = $false,
    [switch]${enable-preview} = $false,
    [switch]${enable-session} = $false,
    [switch]${enable-ugc-community} = $false,
    [switch]${enable-ugc-moderation} = $false,
    [switch]${enable-xo-management} = $false,
    [switch]${enable-xo-query} = $false,

    [switch]${auto-register} = $false,
    [switch]${clean-target} = $false,
    [switch]${remove-services} = $false,

    [Alias("e")][string]${environment-file} = ".\setenv.ps1",
    [Alias("s")][string]${services-folder} = $( Split-Path -parent $PSCommandPath ) + "\..\..\roles",
    [Alias("t")][string]${target-folder} = "C:\SDL\Tridion",

    [string]${cid-url},
    [string]${content-url},
    [string]${context-url},
    [string]${deployer-url},
    [string]${deployer-worker-url},
    [string]${discovery-url},
    [string]${elasticsearch-url},
    [string]${iq-index-url},
    [string]${iq-query-url},
    [string]${preview-url},
    [string]${session-url},
    [string]${token-url},
    [string]${ugc-community-url},
    [string]${ugc-moderation-url},
    [string]${xo-management-url},
    [string]${xo-query-url}
)

##############################################################
##################### Variables declaration part #############
##############################################################

#### Reading variables #####
$delivery_vars = @{ }

$services_order = ('discovery', 'deployer', 'deployer-worker', 'deployer-combined', 'content', 'cid', 'context', 'preview', 'session', 'ugc-community', 'ugc-moderation', 'iq-index', 'iq-query', 'iq-combined', 'xo-management', 'xo-query', 'monitoring')

# Get localhost IP address
$delivery_vars["HOST_IP"] = ((ipconfig | findstr [0-9].\.)[0]).Split()[-1]
Write-Debug ("Host IP: " + $delivery_vars["HOST_IP"])

# Default target service location
$delivery_vars["TARGET_FOLDER"] = ${target-folder}

$sourceFolder = ${services-folder}

$currentFolder = Get-Location
$scriptPath = Split-Path -parent $PSCommandPath


##############################################################
##################### Function declaration part ##############
##############################################################

# Looks for Java
function checkJava {
        $jhome = $env:JAVA_HOME;

        if ($jhome -eq $null -or $jhome -eq [String]::Empty) {
            Write-Host "JAVA_HOME is not available" -ForegroundColor Red
            Exit
        }

        Write-Host "Getting Java version from $jhome"
        $v = (Get-Command java -ErrorAction Ignore | Select-Object -ExpandProperty Version)
        if($v) {
            Write-Host "Java version is $v"
        }
        else {
            Write-Host "Java not found!"
            Exit
        }
}

# Ensure script is launched with Administrator rights
function validateAdminRights {
    $isAdministrator = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
    if ($isAdministrator -eq $False) {
        Write-Host "Please ensure script is launched with Administrator rights" -ForegroundColor Red
        Exit
    }
}

# Ensure that target folder path ends with backslash
function checkTargetPathEnding {
    if (-not $delivery_vars["TARGET_FOLDER"].EndsWith("\")) {
        $delivery_vars["TARGET_FOLDER"] = $delivery_vars["TARGET_FOLDER"] + "\"
    }
}

# Builds URL which is used by Monitoring Service
function getMonitoringUrl {
    param (
        [string]$serviceUrl
    )
    $serviceUrl + "/mappings"
}

# logback config log path should be with slashes
function fixLogFolderPath {
    $delivery_vars["./logs"] = $delivery_vars["./logs"].Replace('\', '/')
}

# Prints detailed help
function printHelp {
    Get-Help $MyInvocation.ScriptName -Detailed
}

# Registers already existing services as a windows services.
function installExistingServices {
    $path = $delivery_vars["TARGET_FOLDER"]
    if (-not(Test-Path $path -PathType Container)) {
        $Host.UI.WriteErrorLine("ERROR: Target folder '" + $path + "' doesn't exist")
        Return
    }
    Write-Host "Starting installation of windows services..." -ForegroundColor Green
    $removeScripts = Get-ChildItem  -Path $path -Recurse "installService.ps1"
    foreach ($service in $services_order) {
        foreach ($removeScript in $removeScripts) {
            if ($removeScript.FullName -like "*\$service\*") {
                $sorted_remove_scripts += @($removeScript.FullName)
            }
        }
    }
    foreach ($removeScript in $sorted_remove_scripts) {
        . $removeScript
    }
    Write-Host "Installation of windows services finished." -ForegroundColor Green
}

# Runs uninstallService script in each of installed in target folder service
function removeExistingServices {
    $path = $delivery_vars["TARGET_FOLDER"]
    Write-Host "Starting removal of Tridion windows services..." -ForegroundColor Green
    if (Test-Path $path -PathType Container) {
        $removeScripts = Get-ChildItem -Path $path -Recurse "uninstallService.ps1"
        foreach ($file in $removeScripts) {
            . $file.FullName
        }
        Write-Host "Removal of windows services finished." -ForegroundColor Green
    } else {
        $Host.UI.WriteErrorLine("ERROR: Folder '" + $path + "' doesn't exist")
        Return
    }
}

# Cleans up target folder.
function cleanupTarget {
    $path = $delivery_vars["TARGET_FOLDER"]
    Write-Host "Cleaning target folder '$path'" -ForegroundColor Green
    if (Test-Path $path -PathType Container) {
        Remove-Item -Path $path -Recurse -Force
    } else {
        $Host.UI.WriteErrorLine("ERROR: Folder '" + $path + "' doesn't exist")
        Return
    }
    Write-Host "Cleaning target folder finished." -ForegroundColor Green
}

# Removes service from windows services and removes service folder
function cleanupService {
    param (
        [string]$serviceSubPath = $( throw "Service name should be specified" )
    )
    $servicePath = $delivery_vars["TARGET_FOLDER"] + $serviceSubPath
    if (Test-Path $servicePath) {
        $uninstallScript = $servicePath + "\bin\uninstallService.ps1"
        if (Test-Path $uninstallScript) {
            Write-Host "Removing existing service..." -ForegroundColor Green
            . $uninstallScript
            Write-Host "Removing existing service finished" -ForegroundColor Green
        }
        Write-Host "Removing service folder..." -ForegroundColor Green
        Remove-Item -Path $servicePath -Recurse -Force -ErrorAction SilentlyContinue
        if (Test-Path $servicePath) {
            $Host.UI.WriteErrorLine("ERROR: Not able to remove folder '" + $servicePath + "'")
        } else {
            Write-Host "Service folder removed" -ForegroundColor Green
        }
    } else {
        Write-Host "No existing service found"
    }
}

# Copies service from source to destination target folder
function copyService {
    param (
        [string]$fromSubPath,
        [string]$serviceSubPath
    )
    $fromPath = $sourceFolder + "\" + $fromSubPath + "\standalone"
    Write-Host "Copying from service folder '$fromPath'" -ForegroundColor Green
    if (-not(Test-Path $fromPath -PathType Container)) {
        $Host.UI.WriteErrorLine("ERROR: Folder '" + $fromPath + "' doesn't exist")
        Exit
    }
    $toPath = $delivery_vars["TARGET_FOLDER"] + $serviceSubPath
    Write-Host "Copying service to target folder '$toPath'" -ForegroundColor Green
    if (-not(Test-Path -Path $toPath -PathType Container)) {
        New-Item -Path $toPath -ItemType directory | Out-Null
    }
    Copy-Item -Recurse -Force -Path "$fromPath\*" -Destination $toPath
    Write-Host "Copying finished" -ForegroundColor Green
}

# Get product from service
function getProduct {
    param (
        [string]$serviceFolder
    )
    if (Test-Path "${serviceFolder}\standalone\PRODUCT") {
        Get-Content -Path "${serviceFolder}\standalone\PRODUCT"
    }
}

# Updates configuration files with values from deliver_vars (senenv.ps1)
function updateConfiguration {
    param (
        [string]$targetSubPath
    )
    Write-Host "Updating configuration files..." -ForegroundColor Green
    $tmpPath = $delivery_vars["TARGET_FOLDER"] + $targetSubPath + "\tmp"
    $configPath = $delivery_vars["TARGET_FOLDER"] + $targetSubPath + "\config"
    #copy files from source to temporary folder
    $configSourcePath = $scriptPath + "\config\" + $serviceName
    #make sure tmpTaph exists
    if (-not(Test-Path -Path $tmpPath -PathType Container)) {
        New-Item -Path $tmpPath -ItemType directory | Out-Null
    }
    if ($docs) {
        $productName = "docs"
    } elseif ($dx) {
        $productName = "dx"
    } else {
        $productName = "sites"
    }

    Get-ChildItem "$configSourcePath" | `
    Where-Object { $_.PSIsContainer -eq $False } | `
    ForEach-Object { Copy-Item -Path $_.Fullname -Destination $tmpPath -Force }

    if (Test-Path "$configSourcePath\$productName") {
        Get-ChildItem "$configSourcePath\$productName" | `
      Where-Object { $_.PSIsContainer -eq $False } | `
      ForEach-Object { Copy-Item -Path $_.Fullname -Destination $tmpPath -Force }
    }

    #update configs in temp folder and copy to destination configuration folder
    foreach ($file in $( Get-ChildItem $tmpPath )) {
        foreach ($value in $delivery_vars.GetEnumerator()) {
            (Get-Content $file.FullName).replace($( $value.Name ), $( $value.Value )) | Set-Content $file.FullName
        }
    }
    #make sure config path exists
    if (-not(Test-Path -Path $configPath -PathType Container)) {
        New-Item -Path $configPath -ItemType directory | Out-Null
    }
    Copy-Item "$tmpPath\*" -Destination $configPath -Force -Recurse
    #remove temp folder
    Remove-Item $tmpPath -Recurse -Force
    Write-Host "Configuration files updated" -ForegroundColor Green
}

# Updates logback.xml with log files path.
function updateLogConfig {
    param (
        [string]$serviceSubPath
    )
    $servicePath = $delivery_vars["TARGET_FOLDER"] + $serviceSubPath
    $configPath = $servicePath + "\config\logback.xml"
    $logFilePath = $delivery_vars["./logs"] + "/" + $serviceSubPath
    if (Test-Path $configPath -PathType Leaf) {
        (Get-Content $configPath).replace("./logs", $logFilePath) | Set-Content $configPath
    } else {
        $Host.UI.WriteErrorLine("ERROR: File logback.xml is not found.")
    }
}

# Installs role as windows service.
function installWindowsService {
    param (
        [string]$serviceSubPath,
        [string]$additionalStartParameters
    )
    $servicePath = $delivery_vars["TARGET_FOLDER"] + $serviceSubPath
    $installServiceScript = $servicePath + "\bin\installService.ps1"
    if (Test-Path $installServiceScript -PathType Leaf) {
        $parameters = ""
        Write-Host "Starting windows service installation..." -ForegroundColor Green
        if (${auto-register}) {
            Write-Host "INFO: Installing service with auto-register flag" -ForegroundColor DarkYellow
            $parameters = "--auto-register"
        }
        & $installServiceScript $parameters $additionalStartParameters
        Write-Host "Installation of windows service finished." -ForegroundColor Green
    }
}

# Installs role
function installService {
    param (
        [string]$fromSubPath,
        [string]$serviceName,
        [string]$additionalStartParameters
    )
    Write-Host ""
    Write-Host "Installation of role '$serviceName' is starting..." -ForegroundColor Green
    if ($install) {
        installWindowsService $serviceName $additionalStartParameters
    } else {
        cleanupService $serviceName
        copyService $fromSubPath $serviceName
        copyExtensions $serviceName
        updateConfiguration $serviceName
        updateLogConfig $serviceName
        installWindowsService $serviceName $additionalStartParameters
    }
    Write-Host "Installation of role '$serviceName' is finished." -ForegroundColor Green
    Write-Host ""
}

# Copy custom extensions like cartridges, etc.
function copyExtensions {
    param (
        [string]$serviceName
    )
    if (($docs -or $dx) -and ($serviceName -eq "content")) {
        Write-Host "Installing ish-cartridge and ugc-cartridge" -ForegroundColor Green
        Copy-Item $sourceFolder\content\ish-cartridge\lib -Destination ${target-folder}\content\services\ish-extension-cartridge\ -Force -Recurse
        Copy-Item $sourceFolder\content\ish-cartridge\config -Destination ${target-folder}\content\ -Force -Recurse
        Copy-Item $sourceFolder\ugc\extension-cartridge\lib -Destination ${target-folder}\content\services\ugc-extension-cartridge\ -Force -Recurse
        Copy-Item $sourceFolder\ugc\extension-cartridge\config -Destination ${target-folder}\content\ -Force -Recurse
    }
    if ($dx -and ($serviceName -eq "session")) {
        Write-Host "Installing ish-cartridge and ugc-cartridge" -ForegroundColor Green
        Copy-Item $sourceFolder\content\ish-cartridge\lib -Destination ${target-folder}\session\services\ish-extension-cartridge\ -Force -Recurse
        Copy-Item $sourceFolder\content\ish-cartridge\config -Destination ${target-folder}\session\ -Force -Recurse
        Copy-Item $sourceFolder\ugc\extension-cartridge\lib -Destination ${target-folder}\session\services\ugc-extension-cartridge\ -Force -Recurse
        Copy-Item $sourceFolder\ugc\extension-cartridge\config -Destination ${target-folder}\session\ -Force -Recurse
    }
}

function getEsStartupParameters {
    param (
        [string]$esScheme,
        [string]$esHost,
        [string]$esPort
    )
    return "'-Des.host = $esHost','-Des.port = $esPort','-Des.scheme = $esScheme','-Des.ingest.host = $esHost','-Des.ingest.port = $esPort','-Des.ingest.scheme = $esScheme'"
}


##############################################################
##################### Main execution part ####################
##############################################################

if ($PSBoundParameters.Count -eq 0 -or $help) {
    printHelp
    Exit
}

# Ensure script is run with Administrator rights
validateAdminRights

try {
    Set-Location $scriptPath
    checkTargetPathEnding
    checkJava

    # Load local environment
    if (Test-Path ${environment-file}) {
        Write-Debug "Environment file: ${environment-file}"
        . ${environment-file}
    }

    # Determine product based on deployer PRODUCT file
    Write-Debug "Services folder: ${sourceFolder}"
    if (${dx}) {
        $deployerPrefix = "deployer-dx"
    } elseif(${docs}) {
        $deployerPrefix = "deployer"
    } else {
        $deployerPrefix = "deployer-sites"
    }
    $productLayout = getProduct("${sourceFolder}\deployer\${deployerPrefix}")
    Write-Debug "Product layout: ${productLayout}"

    if (-not($sites) -and -not($docs) -and -not($dx)) {
        $productID = $productLayout -split ' '
        Set-Variable -Name $productID[1].ToLower() -Value $true
        Write-Host "No product selected, using default of $productLayout"
    }

    if (${sites}) {
        if ($productLayout -ne "Tridion Sites") {
            Write-Host "ERROR: This layout does not contain the correct Tridion Sites artifacts" -ForegroundColor Red
            Exit
        }
        $delivery_vars["NAMESPACE_PREFIX"] = "tcm"
        $delivery_vars["DEPLOYER_SERVICE_CAPABILITY_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":8084/v2"
    } elseif (${docs}) {
        if ($productLayout -ne "Tridion Docs") {
            Write-Host "ERROR: This layout does not contain the correct Tridion Docs artifacts" -ForegroundColor Red
            Exit
        }
        if (${enable-preview}) {
            Write-Host "There is no Preview service for Tridion Docs" -ForegroundColor "yellow"
            ${enable-preview} = ${false}
        }
        if (${enable-session}) {
            Write-Host "There is no Session service for Tridion Docs" -ForegroundColor "yellow"
            ${enable-session} = ${false}
        }
        if (${enable-xo-management} -or ${enable-xo-query}) {
            Write-Host "There are no XO services for Tridion Docs" -ForegroundColor "yellow"
            ${enable-xo-management} = ${false}
            ${enable-xo-query} = ${false}
        }
        if (${enable-monitoring}) {
            Write-Host "There are no monitoring services for Tridion Docs" -ForegroundColor "yellow"
            ${enable-monitoring} = ${false}
        }
        $delivery_vars["NAMESPACE_PREFIX"] = "ish"
        $delivery_vars["DEPLOYER_SERVICE_CAPABILITY_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":8084/v2"
    } elseif (${dx}) {
        if ($productLayout -ne "Tridion DX") {
            Write-Host "ERROR: This layout does not contain the correct Tridion Sites artifacts" -ForegroundColor Red
            Exit
        }
        $delivery_vars["NAMESPACE_PREFIX"] = "tcm"
        $delivery_vars["DEPLOYER_SERVICE_CAPABILITY_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":8084/v2"
    }

    if ($all) {
        ${enable-discovery} = $true
        ${enable-deployer-combined} = $true
        ${enable-cid} = $true
        ${enable-context} = $true
        if (${sites} -or ${dx}) {
            ${enable-preview} = $true
            ${enable-session} = $true
        } else {
            ${enable-content} = $true
        }
        ${enable-ugc-community} = $true
        ${enable-ugc-moderation} = $true
        ${enable-iq-combined} = $true
    }

    if ($install) {
        installExistingServices
    }
    if (${remove-services}) {
        removeExistingServices
    }
    if (${clean-target}) {
        if (-not${remove-services}) {
            removeExistingServices
        }
        cleanupTarget
    }
    if ($install -or ${remove-services} -or ${clean-target}) {
        Exit
    }

    fixLogFolderPath

    if (${deployer-url}) {
        $delivery_vars["DEPLOYER_SERVICE_CAPABILITY_URL"] = ${deployer-url}.TrimEnd("/")
    }

    if (${deployer-worker-url}) {
        $delivery_vars["DEPLOYER_WORKER_URL"] = ${deployer-worker-url}.TrimEnd("/")
    } else {
        $delivery_vars["DEPLOYER_WORKER_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":8089/health"
    }

    if (${discovery-url}) {
        $delivery_vars["DISCOVERY_SERVICE_URL"] = ${discovery-url}.TrimEnd("/")
    } else {
        $delivery_vars["DISCOVERY_SERVICE_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":8082/discovery.svc"
    }

    if (${token-url}) {
        $delivery_vars["TOKEN_SERVICE_CAPABILITY_URL"] = ${token-url}.TrimEnd("/")
    } else {
        $delivery_vars["TOKEN_SERVICE_CAPABILITY_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":8082/token.svc"
    }

    if (${content-url}) {
        $delivery_vars["CONTENT_SERVICE_CAPABILITY_URL"] = ${content-url}.TrimEnd("/")
    } else {
        $delivery_vars["CONTENT_SERVICE_CAPABILITY_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":8081/content.svc"
    }

    if (${cid-url}) {
        $delivery_vars["CID_SERVICE_CAPABILITY_URL"] = ${cid-url}.TrimEnd("/")
    } else {
        $delivery_vars["CID_SERVICE_CAPABILITY_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":8088/cid"
    }

    if (${context-url}) {
        $delivery_vars["CONTEXT_SERVICE_CAPABILITY_URL"] = ${context-url}.TrimEnd("/")
    } else {
        $delivery_vars["CONTEXT_SERVICE_CAPABILITY_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":8087/context.svc"
    }

    if (${preview-url}) {
        $delivery_vars["PREVIEW_SERVICE_CAPABILITY_URL"] = ${preview-url}.TrimEnd("/")
    } else {
        $delivery_vars["PREVIEW_SERVICE_CAPABILITY_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":8083/ws/preview.svc"
    }

    if (${session-url}) {
        $delivery_vars["CONTENT_SERVICE_CAPABILITY_URL"] = ${session-url}.TrimEnd("/")
    } else {
        $delivery_vars["CONTENT_SERVICE_CAPABILITY_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":8081/content.svc"
    }

    if (${ugc-community-url}) {
        $delivery_vars["COMMUNITY_SERVICE_CAPABILITY_URL"] = ${ugc-community-url}.TrimEnd("/")
    } else {
        $delivery_vars["COMMUNITY_SERVICE_CAPABILITY_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":8085/community.svc"
    }

    if (${ugc-moderation-url}) {
        $delivery_vars["MODERATION_SERVICE_CAPABILITY_URL"] = ${ugc-moderation-url}.TrimEnd("/")
    } else {
        $delivery_vars["MODERATION_SERVICE_CAPABILITY_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":8086/moderation.svc"
    }

    if (${iq-index-url}) {
        $delivery_vars["IQ_INDEX_SERVICE_CAPABILITY_URL"] = ${iq-index-url}.TrimEnd("/")
    } else {
        $delivery_vars["IQ_INDEX_SERVICE_CAPABILITY_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":8097/index.svc"
    }

    if (${iq-query-url}) {
        $delivery_vars["IQ_QUERY_SERVICE_CAPABILITY_URL"] = ${iq-query-url}.TrimEnd("/")
    } elseif (${enable-iq-combined}) {
        $delivery_vars["IQ_QUERY_SERVICE_CAPABILITY_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":8097/search.svc"
    } else {
        $delivery_vars["IQ_QUERY_SERVICE_CAPABILITY_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":8098/search.svc"
    }

    if (${xo-management-url}) {
        $delivery_vars["XO_MANAGEMENT_SERVICE_CAPABILITY_URL"] = ${xo-management-url}.TrimEnd("/")
    } else {
        $delivery_vars["XO_MANAGEMENT_SERVICE_CAPABILITY_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":8097/index.svc"
    }
    if (${xo-query-url}) {
        $delivery_vars["XO_QUERY_SERVICE_CAPABILITY_URL"] = ${xo-query-url}.TrimEnd("/")
    } else {
        $delivery_vars["XO_QUERY_SERVICE_CAPABILITY_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":8097/index.svc"
    }
    if (${elasticsearch-url}) {
        $delivery_vars["ELASTICSEARCH_URL"] = ${elasticsearch-url}.TrimEnd("/")
    } else {
        $delivery_vars["ELASTICSEARCH_URL"] = "http://" + $delivery_vars["HOST_IP"] + ":9200"
    }

    $delivery_vars["CONTENT_SERVICE_MONITORING_URL"] = getMonitoringUrl $delivery_vars["CONTENT_SERVICE_CAPABILITY_URL"]
    $delivery_vars["DISCOVERY_SERVICE_MONITORING_URL"] = getMonitoringUrl $delivery_vars["DISCOVERY_SERVICE_URL"]
    $delivery_vars["PREVIEW_SERVICE_MONITORING_URL"] = getMonitoringUrl $delivery_vars["PREVIEW_SERVICE_CAPABILITY_URL"]
    $delivery_vars["DEPLOYER_SERVICE_MONITORING_URL"] = getMonitoringUrl $delivery_vars["DEPLOYER_SERVICE_CAPABILITY_URL"]
    $delivery_vars["COMMUNITY_SERVICE_MONITORING_URL"] = getMonitoringUrl $delivery_vars["COMMUNITY_SERVICE_CAPABILITY_URL"]
    $delivery_vars["MODERATION_SERVICE_MONITORING_URL"] = getMonitoringUrl $delivery_vars["MODERATION_SERVICE_CAPABILITY_URL"]
    $delivery_vars["CONTEXT_SERVICE_MONITORING_URL"] = getMonitoringUrl $delivery_vars["CONTEXT_SERVICE_CAPABILITY_URL"]
    $delivery_vars["CID_SERVICE_MONITORING_URL"] = getMonitoringUrl $delivery_vars["CID_SERVICE_CAPABILITY_URL"]
    $delivery_vars["IQ_INDEX_SERVICE_MONITORING_URL"] = getMonitoringUrl $delivery_vars["IQ_INDEX_SERVICE_CAPABILITY_URL"]
    $delivery_vars["IQ_QUERY_SERVICE_MONITORING_URL"] = getMonitoringUrl $delivery_vars["IQ_QUERY_SERVICE_CAPABILITY_URL"]
    $delivery_vars["XO_MANAGEMENT_SERVICE_MONITORING_URL"] = getMonitoringUrl $delivery_vars["XO_MANAGEMENT_SERVICE_CAPABILITY_URL"]
    $delivery_vars["XO_QUERY_SERVICE_MONITORING_URL"] = getMonitoringUrl $delivery_vars["XO_QUERY_SERVICE_CAPABILITY_URL"]

    foreach ($h in $delivery_vars.GetEnumerator() | Sort-Object -Property name) {
        Write-Debug "$( $h.Name ): $( $h.Value )"
    }

    ${elastic-search-endpoint-uri} = [System.Uri]$delivery_vars["ELASTICSEARCH_URL"]
    ${es-startup-parameters} = $( getEsStartupParameters $( ${elastic-search-endpoint-uri}.Scheme ) $( ${elastic-search-endpoint-uri}.Host ) $( ${elastic-search-endpoint-uri}.Port ) )
    $delivery_vars["ELASTICSEARCH_HOST"] = ${elastic-search-endpoint-uri}.Host

    # Installing all enabled services one by one in following order
    Write-Host ""
    if (${sites}) {
        Write-Host "======================== Tridion Sites is enabled ========================" -ForegroundColor "yellow"
    } elseif (${docs}) {
        Write-Host "======================== Tridion Docs is enabled =========================" -ForegroundColor "yellow"
    } else {
        Write-Host "======================== Tridion DX is enabled ===========================" -ForegroundColor "yellow"
    }

    if (${enable-discovery}) {
        installService "discovery" "discovery"
    }
    if (${enable-deployer}) {
        installService "deployer\${deployerPrefix}" "deployer"
    }
    if (${enable-deployer-worker}) {
        installService "deployer\${deployerPrefix}-worker" "deployer-worker"
    }
    if (${enable-deployer-combined} -and -not(${enable-deployer} -or ${enable-deployer-worker})) {
        installService "deployer\${deployerPrefix}-combined" "deployer-combined"
    }
    if (${enable-content} -and -not${enable-session}) {
        installService "content" "content"
    }
    if (${enable-cid}) {
        installService "cid" "cid"
    }
    if (${enable-context}) {
        installService "context\service" "context"
    }
    if (${enable-preview}) {
        installService "preview" "preview"
    }
    if (${enable-session}) {
        installService "session\service" "session"
    }
    if (${enable-ugc-community}) {
        installService "ugc\service-community" "ugc-community"
    }
    if (${enable-ugc-moderation}) {
        installService "ugc\service-moderation" "ugc-moderation"
    }
    if (${enable-monitoring}) {
        installService "monitoring\agent" "monitoring"
    }
    if (${enable-iq-index}) {
        installService "iq\iq-index" "iq-index" "${es-startup-parameters} -Des.bootstrap.enable=true"
    }
    if (${enable-iq-query}) {
        installService "iq\iq-query" "iq-query" "${es-startup-parameters} -Des.bootstrap.enable=true"
    }
    if (${enable-iq-combined} -and -not(${enable-iq-index} -or ${enable-iq-query})) {
        installService "iq\iq-combined" "iq-combined" "${es-startup-parameters} -Des.bootstrap.enable=true"
    }
    if (${enable-xo-management}) {
        installService "xo\xo-management" "xo-management" ${es-startup-parameters}
    }
    if (${enable-xo-query}) {
        installService "xo\xo-query" "xo-query" ${es-startup-parameters}
    }
}
finally {
    Set-Location $currentFolder
}
