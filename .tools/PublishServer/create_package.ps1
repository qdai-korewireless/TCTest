Param(
     [string]$sourcePackageFolder = ""
    )

$nuspecTemplate = "util\Kore-BGC.nuspec_template"
$envName = ""
$version = ""

#-----------------------------
Function PrintScriptHeader
{
    Write-Host
    Write-Host
    Write-Host "===================================================="
    Write-Host
    Write-Host "Proximus Nuget Package Creation Script"
    Write-Host
    Write-Host "===================================================="
    Write-Host
}


#-----------------------------
Function PrintUsage
{
    Write-Host
    Write-Host "proper usage is:"
    Write-Host
    Write-Host "  create_package.ps1 <sourcePackageFolder>"
    Write-Host
    Write-Host "       <sourcePackageFolder>  Specifies the name of the source package folder"
    Write-Host "                              (name of folder must start with `"KORE-*-<ENV>`")"
    Write-Host
}


#-----------------------------
Function ValidateFolderName ($folder, $envName)
{
    $error = 0
    if ($folder.CompareTo("") -Eq 0)
    {
        Write-Host "ERROR, Source Package folder name must be specified" -foregroundcolor "Red"
        $error = 1
    }
    elseif (-Not (Test-Path ($folder)))
    {
        Write-Host "ERROR, Source Folder '$folder' was not found" -foregroundcolor "Red"
        $error = 1
    }
    else
    {
        if ($folder -like "Kore-*")
        {
            $envName.Value = $folder.Substring(9)
        }
        else
        {
            Write-Host "ERROR, Package Folder has bad Format" -foregroundcolor "Red"
            $error = 1
        }
    }
        
    return $error
}

#-----------------------------
Function PrintPkgStructure
{
    Write-Host "The Proximus package should be in a folder named `"$sourcePackageFolder`""
    Write-Host "and should have the following structure:"
    Write-Host
    Write-Host "  $sourcePackageFolder"
    Write-Host "     \KORE_Platform_Belgacom_x.x.x.x\"
    Write-Host "     \KORE_Database_Belgacom_x.x.x.x\"
    Write-Host "     \KORE_Reports_Belgacom_x.x.x.x\"
    Write-Host "     \<MOP title>.docx"
    Write-Host
}

#-----------------------------
Function SetPkgVersion ($folder, $packageVersion)
{

    $enterCustomVersion = 0
    $error = 0
    
    $platformInstaller = $folder + "\KORE_Platform*"
    $databaseInstaller = $folder + "\KORE_Database*"
    $reportsInstaller = $folder + "\KORE_Reports*"
    
    if (Test-Path($platformInstaller))
    {
        $installerFileName = @(Get-ChildItem $platformInstaller)
        $installerFileCount = $installerFileName.Count
    }
    elseif (Test-Path($databaseInstaller))
    {
        $installerFileName = @(Get-ChildItem $databaseInstaller)
        $installerFileCount = $installerFileName.Count
    }
    elseif (Test-Path($reportsInstaller))
    {
        $installerFileName = @(Get-ChildItem $reportsInstaller)
        $installerFileCount = $installerFileName.Count
    }
    else
    {
        Write-Host "No installer folders were found, so version number must be provided manually"
        $installerFileCount = 0
    }

    
    if ($installerFileCount -eq 1)
    {
        $baseName = (Get-Item $installerFileName).BaseName
        $installerVersion = $baseName -replace ".*_"
        
        Write-Host "Installer detected:" $baseName
        Write-Host
        $prompt = Read-Host "Do you want to use detected version ($installerVersion) for the package? [y/n]"

        if ($prompt -eq 'y')
        {  
            $packageVersion.Value = $installerVersion
        }
        else
        {
            $enterCustomVersion = 1            
        }
    }
    elseif ($installerFileCount -gt 1)
    {
        Write-Host "Error, Multiple Installers detected" -foregroundcolor "Red"
        $error = 1
    }
    
    
    if (($enterCustomVersion -eq 1) -Or ($installerFileCount -eq 0))
    {
        Write-Host
        $packageVersion.Value = Read-Host "Enter a version number for the package (x.x.x.x)"        
    }
    
    return ($error)
}


#-----------------------------
Function CreatePkg ($folder, $envName, $version)
{
    $envName = $envName.ToUpper()
    $folder = $folder.ToUpper()
    $error = 0
    
    md ".\util\temp\" -Force
    $nuspecFileName = ".\util\temp\" + $folder + ".nuspec"
    Copy-Item $nuspecTemplate -Destination $nuspecFileName -Force
    
    if (Test-Path $nuspecFileName) {    
        $content = Get-Content ($nuspecFileName)
        $content = $content -replace "PKG_NAME_TOKEN", "$folder"
        $content = $content -replace "ENV_NAME_TOKEN", "$envName"
        $content = $content -replace "PKG_FOLDER_TOKEN", "$folder"
        
        $content | set-Content ($nuspecFileName)
        
        Write-Host "sourcePackageFolder: " $folder
        Write-Host "envName: " $envName
        Write-Host "packageVersion: " $version
        Write-Host "nuspecFileName: " $nuspecFileName
        
        .\util\choco.exe pack $nuspecFileName -Version $version        
    }
    else
    {
        $error = 1
        Write-Host "Error, nuspec file can't be found" -foregroundcolor "Red"
    }
    
    return ($error)
}

#-----------------------------
#-----------------------------
#-----------------------------

$sourcePackageFolder = $sourcePackageFolder.TrimStart(".\")
$sourcePackageFolder = $sourcePackageFolder.ToUpper()

PrintScriptHeader

$returnError = ValidateFolderName $sourcePackageFolder ([Ref] $envName)
if ($returnError)
{
    PrintUsage
    return
}

PrintPkgStructure


$returnError = SetPkgVersion $sourcePackageFolder ([Ref] $version)
if ($returnError)
{
    PrintUsage
    return
}

CreatePkg $sourcePackageFolder $envName $version