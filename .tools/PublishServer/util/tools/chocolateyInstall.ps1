if (Test-Path D:) 
{
    $DRV="D:"
}
elseif (Test-Path E:)
{
    $DRV="E:"
}
else
{
    throw "ERROR, no valid drive letter was detected"
}

$pkgName = $env:chocolateyPackageName
$pkgFolder = $env:chocolateyPackageFolder
$pkgVer = $env:chocolateyPackageVersion

$packagesLocation = $DRV + "\KoreDeploymentPackages\"
Write-Host "Deployment Package will be copied to:" $packagesLocation

$commandFolder = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$artifactFolder = $("$commandFolder\..\content")

$installerId = $pkgName + "." + $pkgVer
$destinationPath = $packagesLocation + $installerId

Write-Host "Installing" $installerId

if (Test-Path $destinationPath)
{
    Write-Host "Existing copy of installer directory detected"
    Write-Host "Deleting installer directory: $destinationPath"
    Remove-Item $destinationPath -recurse
}

Write-Host "Copying files to installer directory: $destinationPath"
Copy-Item $artifactFolder $destinationPath -recurse



#Invoke-Item $destinationPath