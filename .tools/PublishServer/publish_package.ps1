Param(
    [string]$pkgName = "",
    [string]$destination = ""
)

#-----------------------------
function FileTransferProgress
{
    param($e)
 
    # New line for every new file
    if (($script:lastFileName -ne $Null) -and
        ($script:lastFileName -ne $e.FileName))
    {
        Write-Host
    }
 
    # Print transfer progress
    Write-Host -NoNewline ("`r{0} ({1:P0})" -f $e.FileName, $e.FileProgress)
 
    # Remember a name of the last file reported
    $script:lastFileName = $e.FileName
}

#-----------------------------
Function sftpTransfer ($fileNameToDeliver)
{
    # ref. http://winscp.net/eng/docs/library#powershell
    try
    {
        # Load WinSCP .NET assembly
        #[Reflection.Assembly]::LoadFrom(".\WinSCPnet.dll") | Out-Null
        Add-Type -Path ".\util\WinSCPnet.dll"
     
        # Setup session options
        $sessionOptions = New-Object WinSCP.SessionOptions
        $sessionOptions.Protocol = [WinSCP.Protocol]::Sftp
        $sessionOptions.HostName = "mft.belgacom.be"
        $sessionOptions.PortNumber = "22000"
        $sessionOptions.UserName = "id970459"
        $sessionOptions.Password = "3m7ECXwvEh"
        $sessionOptions.SshHostKeyFingerprint = "ssh-rsa 2048 65:0d:10:27:66:9d:0e:23:22:29:fb:f7:55:dc:2e:98"
        
        #for testing
        #$sessionOptions.HostName = "172.30.100.2"
        #$sessionOptions.PortNumber = "22"
        #$sessionOptions.UserName = "tester"
        #$sessionOptions.Password = "password"
        #$sessionOptions.SshHostKeyFingerprint = "ssh-rsa 2048 94:58:25:81:32:80:37:d8:f3:ab:12:ce:52:c1:9b:bd"

        $session = New-Object WinSCP.Session

        try
        {
            # Continuously report progress of transfer
            $session.add_FileTransferProgress( { FileTransferProgress($_) } )
        
            # Connect
            $session.Open($sessionOptions)
             
            # Upload files
            $transferOptions = New-Object WinSCP.TransferOptions
            $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
            $transferOptions.ResumeSupport.State = [WinSCP.TransferResumeSupportState]::Off
     
            $transferResult = $session.PutFiles("..\$fileNameToDeliver", "/outgoing/MTMK/", $FALSE, $transferOptions)
     
            # Throw on any error
            $transferResult.Check()
     
            # Print results
            Write-Host
            foreach ($transfer in $transferResult.Transfers)
            {
                Write-Host "Your package was pushed."
            }
        }
        finally
        {
            # Disconnect, clean up
            $session.Dispose()
        }
     
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
        exit 1
    }
}
#----------------------

Function printUsage
{
    Write-Host "ERROR, Package name must be specified! Please try again"  -foregroundcolor "Red"
    Write-Host
    Write-Host "proper usage is:"
    Write-Host ""
    Write-Host "  publish_package.ps1 <packageFileName>"
    Write-Host ""
    exit 0
}
#----------------------

Write-Host ""
Write-Host ""
Write-Host "===================================================="
Write-Host ""
Write-Host "Proximus Publish Server Script"
Write-Host ""
Write-Host "===================================================="

$done = $false
while ($done -Eq $false)
{
    Write-Host ""
    Write-Host "Select the Destination to publish to:"
    Write-Host " 1: BGC (also publishes to WPG_MIRROR)"
    Write-Host " 2: WPG_TEST"
    Write-Host " 3: WPG_MIRROR"

    $selection = Read-Host
    $done = $true
    if ($selection -Eq 1) 
    {
        $destination = "BGC"
    }
    elseif ($selection -Eq 2) 
    {
        $destination = "WPG_TEST"
    }
    elseif ($selection -Eq 3) 
    {
        $destination = "WPG_MIRROR"
    }
    else
    {
        $done = $false
        Write-Host "Invalid Selection"
        Write-Host
    }
}


Write-Host ""
Write-Host "Ready to transfer nuget package to Publish Server:"
Write-Host "  Package Name:" $pkgName
Write-Host "  Destination:" $destination
Write-Host ""

if ($pkgName.CompareTo("") -Eq 0)
{
    printUsage
    return
}

if (!($pkgName.EndsWith(".nupkg")))
{
    Write-Host "ERROR, Package name must end with *.nupkg" -foregroundcolor "Red"
    Write-Host ""
    return
}

$prompt = Read-Host "Do you want to continue and publish the package? [y/n] and [ENTER]"
Write-Host

if ($prompt -ne 'y')
{  
    Write-Host ""
    Write-Host "ERROR, Package transfer was cancelled" -foregroundcolor "Red"
    Write-Host ""
    return
}

if (-Not (Test-Path ($pkgName)))
{
    Write-Host ""
    Write-Host "ERROR, Package Name '$pkgName' was not found" -foregroundcolor "Red"
    Write-Host ""
    return
}

if ($destination.CompareTo("BGC") -Eq 0)
{
    Write-Host "Starting SFTP file transfer to BGC Publish Server..."
    sftpTransfer $pkgName
    
    Write-Host ""
    Write-Host "Starting nuget push to BGC Publish Server Winnipeg Mirror..."
    .\util\nuget.exe push $pkgName None -Source http://172.30.100.99:6100
}

elseif ($destination.CompareTo("WPG_MIRROR") -Eq 0)
{
    Write-Host "Starting nuget push to BGC Publish Server Winnipeg Mirror..."
    .\util\nuget.exe push $pkgName None -Source http://172.30.100.99:6100
}

elseif ($destination.CompareTo("WPG_TEST") -Eq 0)
{
    Write-Host "Starting nuget push to WPG Test Publish Server..."
    .\util\nuget.exe push $pkgName None -Source http://172.30.100.99:6000
}

else
{
    Write-Host ""
    Write-Host "ERROR, '$destination' is not a valid destination" -foregroundcolor "Red"
    Write-Host ""
    printUsage
    return
}

Write-Host ""