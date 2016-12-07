$commandFolder = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$artifactFolder = $("$commandFolder\..\content")

Write-Host "Platform uninstalled"