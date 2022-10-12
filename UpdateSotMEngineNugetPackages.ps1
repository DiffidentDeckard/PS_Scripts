
# Get args
$ArtifactsDirectory = $args[0]
$SteamUsername = $args[1]
$SteamPassword = $args[2]
$ArtifactStagingDirectory = $args[3]

# Store the paths and filenames that we need
$DownloadsDirectory = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
$SteamCmdDownloadUrl = "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip"
$SteamCmd = "SteamCMD"
$EngineCommon = "EngineCommon"
$SentinelsEngine = "SentinelsEngine"
$SotMSteamAppID = 337150

[System.Console]::WriteLine("Artifacts Directory: $ArtifactsDirectory")
[System.Console]::WriteLine("Downloads directory: $DownloadsDirectory")
[System.Console]::WriteLine("$SteamCmd Download URL: $SteamCmdDownloadUrl")

### Downloads SteamCMD, installs it, and then uses it to install Sentinels Of The Multiverse
function InstallSentinelsOfTheMultiverse
{	
	# Clear anything in the downloads directory just to be safe
	[System.Console]::WriteLine("Clearing downloads directory...")
	Get-ChildItem $DownloadsDirectory -Include * -Recurse | Remove-Item
	[System.Console]::WriteLine("Successfully cleared downloads directory")
	
	# Download the steamcmd.zip through a web client
	$scDirectory = "$DownloadsDirectory\$SteamCmd"
	$scZip = "$scDirectory.zip"
	[System.Console]::WriteLine("Downloading $SteamCmd...")
	$webClient = New-Object System.Net.WebClient
	$webClient.DownloadFile($SteamCmdDownloadUrl, $scZip)
	
	# Make sure the SteamCmd.zip was downloaded
	if(!(Test-Path $scZip -PathType Leaf))
	{
		throw [System.IO.FileNotFoundException] "$scZip"
	}
	[System.Console]::WriteLine("Successfully downloaded $SteamCmd")
	
	# Unzip the SteamCmd.zip
	[System.Console]::WriteLine("Extracting files from $scZip...")
	Expand-Archive -Path $scZip -Destination $scDirectory -Force
	
	# Make sure the SteamCmd.zip was unzipped
	$scExe= "$scDirectory\$SteamCmd.exe"
	if(!(Test-Path $scExe -PathType Leaf))
	{
		throw [System.IO.FileNotFoundException] "$scExe"
	}
	[System.Console]::WriteLine("Successfully extracted files from $scZip")
	
	# Run SteamCmd.exe and install Sentinels of the Mutliverse
	[System.Console]::WriteLine("Installing Sentinels of the Multiverse...")
	& $scExe +login $SteamUsername $SteamPassword +app_update $SotMSteamAppID -validate +quit
	Start-Sleep -Seconds 10
	
	[System.Console]::WriteLine("Successfully installed Sentinels of the Multiverse")
}

### Compares the Steam and NuGet versions of the engine, and if the Steam one is newer will update the NuGet package.
function UpdateEngineNugetPackageIfNewerVersionAvailable($engine)
{
	$engineDll = "$engine.dll"

	# Make sure that the SotM engine dll from Steam is installed
	$engineSteam = Get-ChildItem -Path "$DownloadsDirectory\$SteamCmd" -Filter $engineDll -Recurse -ErrorAction SilentlyContinue -Force
	
	if($engineSteam -eq $Null)
	{
		throw [System.IO.FileNotFoundException] $engineSteam.FullName
	}

	# Get the version of the engine dll from Steam
	$engineSteamVersion = $engineSteam.VersionInfo.FileVersionRaw
	[System.Console]::WriteLine("Steam $engineDll version: $engineSteamVersion")

	# Make sure that the SotM engine dll from Nuget is installed
	$engineNuget = Get-ChildItem -Path "$ArtifactsDirectory" -Filter $engineDll -Recurse -ErrorAction SilentlyContinue -Force
	
	if($engineNuget -eq $Null)
	{
		throw [System.IO.FileNotFoundException] $engineNuget.FullName
	}
	
	# Get the version of the engine dll from NuGet
	$engineNugetVersion = $engineNuget.VersionInfo.FileVersionRaw
	[System.Console]::WriteLine("NuGet $engineDll version: $engineNugetVersion")

	# If the Steam version is newer than the NuGet version...
	if($engineSteamVersion -gt $engineNugetVersion)
	{
		# Update the NuGet package
		CreateAndPublishNuGetPackage($engine)
		return $true
	}
	else
	{
		[System.Console]::WriteLine("No new version of $engineDll found")
		return $false
	}
}

### Create the NuGet package for the engine and pushes it to Azure Artifacts.
function CreateAndPublishNuGetPackage($engine)
{
	$engineDll = "$engine.dll"
	$enginePng = "$engine.png"

	# Create our artifact staging Directory
	$stagingDirectory = "$ArtifactStagingDirectory\$engine"

	if(!(Test-Path $stagingDirectory -PathType Container))
	{
		md $stagingDirectory
		[System.Console]::WriteLine("Created staging directory: $stagingDirectory")
	}

	# Copy the newer version of the SotM engine dll from the Steam install
	$engineSteamDll = (Get-ChildItem -Path "$DownloadsDirectory\$SteamCmd" -Filter $engineDll -Recurse -ErrorAction SilentlyContinue -Force).FullName
    Copy-Item $engineSteamDll -Destination $stagingDirectory
	[System.Console]::WriteLine("Copied $engineDll to staging directory")
	
	# Copy the icon image we will use from the previous NuGet package
	$engineNugetIcon = (Get-ChildItem -Path $ArtifactsDirectory -Filter $enginePng -Recurse -ErrorAction SilentlyContinue -Force).FullName
    Copy-Item $engineNugetIcon -Destination $stagingDirectory
	[System.Console]::WriteLine("Copied $enginePng to staging directory")

	# Create the NuSpec file we'll need in order to pack this NuGet package
	CreateEngineNuspecFile($engine)

    # Create the NuGet package
	$engineNuspec = "$stagingDirectory\$engine.nuspec"
    nuget pack $engineNuspec

    # Publish the NuGet package
    nuget push "$stagingDirectory\$engine.*.nupkg" -src https://pkgs.dev.azure.com/diffidentdeckard/SotMBaseMod/_packaging/SotMBaseMod/nuget/v3/index.json -ApiKey SotMBaseMod -skipduplicate
}

### Writes a NuSpec file used to create a NuGet package for the engine.
function CreateEngineNuspecFile($engine)
{
	$stagingDirectory = "$ArtifactStagingDirectory\$engine"
	$engineDll = "$stagingDirectory\$engine.dll"
	$engineIcon = "$stagingDirectory\$engine.png"
	$engineNuspec = "$engine.nuspec"
	$engineVersion = (Get-Item $engineDll).VersionInfo.FileVersionRaw
	[System.Console]::WriteLine("Creating new $engineNuspec file...")

    # Instantiate an XmlTextWriter so we can write to the NuSpec file
    $xmlWriter = New-Object System.XMl.XmlTextWriter("$stagingDirectory\$engineNuspec",$Null)
    $xmlWriter.Formatting = "Indented"
    $xmlWriter.Indentation = 4

    # Write the NuSpec file
    $xmlWriter.WriteStartDocument()
    $xmlWriter.WriteStartElement("package")
        $xmlWriter.WriteStartElement("metadata")
            $xmlWriter.WriteElementString("id", $engine)
            $xmlWriter.WriteElementString("version", $engineVersion)
            $xmlWriter.WriteElementString("description", "SotM Engine DLL that is required to write mods for the game. I don't own this dll in any way, shape, or form. It belongs to Handelabra.")
            $xmlWriter.WriteElementString("authors", "DiffidentDeckard, Handelabra")
            $xmlWriter.WriteElementString("icon", "images\$engineName.png")
            $xmlWriter.WriteElementString("tags", "SentinelsOfTheMultiverse Sentinels Multiverse SotM Engine Mod Steam Workshop DLL")
            
            $xmlWriter.WriteStartElement("dependencies")
                $xmlWriter.WriteStartElement("group ")
                    $xmlWriter.WriteAttributeString("targetFramework", "net35")
                $xmlWriter.WriteEndElement()
            $xmlWriter.WriteEndElement()
        $xmlWriter.WriteEndElement()

        $xmlWriter.WriteStartElement("files")
            $xmlWriter.WriteStartElement("file")
                $xmlWriter.WriteAttributeString("src", $engineDll)
                $xmlWriter.WriteAttributeString("target", "lib\net35")
            $xmlWriter.WriteEndElement()
            
            $xmlWriter.WriteStartElement("file")
                $xmlWriter.WriteAttributeString("src", $engineIcon)
                $xmlWriter.WriteAttributeString("target", "images\")
            $xmlWriter.WriteEndElement()
        $xmlWriter.WriteEndElement()
    $xmlWriter.WriteEndElement()
    $xmlWriter.WriteEndDocument()
    $xmlWriter.Close()
    $xmlWriter.Dispose()
    [System.Console]::WriteLine("$engineNuspec file created")
}

# Download SteamCMD, install it, and install Sentinels of the Multiverse
InstallSentinelsOfTheMultiverse

# Update the NuGet packages for the SotM Engines if they're newer
$ecUpdated = UpdateEngineNugetPackageIfNewerVersionAvailable($EngineCommon)
$seUpdated = UpdateEngineNugetPackageIfNewerVersionAvailable($SentinelsEngine)

# If any NuGet package was updated...
if($ecUpdated -or $seUpdated)
{
	# Kick off a build in the SotM_ModBase Develop pipeline
	Write-Host "##vso[task.setvariable variable=nugetPackageUpdated;]true"
    [System.Console]::WriteLine("New engine version found, NuGet package updated.")
    [System.Console]::WriteLine("Set nugetPackageUpdated to true to kick off SotM_ModBase Develop pipeline build.")
}
# If no NuGet package was updated...
else
{
	# Avoid kicking off a build in the SotM_ModBase Develop pipeline
	Write-Host "##vso[task.setvariable variable=nugetPackageUpdated;]false"
    [System.Console]::WriteLine("No new engine versions found, NuGet packages not updated.")
    [System.Console]::WriteLine("Set nugetPackageUpdated to false to avoid kicking off SotM_ModBase Develop pipeline build.")
}

exit 0