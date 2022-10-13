
# Get args
$ArtifactStagingDirectory = $args[0]

# Store the paths and filenames that we need
$DownloadsDirectory = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
$IlrDownloadUrl = "http://nuget.org/api/v2/package/ILRepack"
$ILRepack = "ILRepack"

[System.Console]::WriteLine("Artifact Staging Directory: $ArtifactStagingDirectory")
[System.Console]::WriteLine("Downloads directory: $DownloadsDirectory")
[System.Console]::WriteLine("$ILRepack Download URL: $IlrDownloadUrl")

# Download ILRepack through a web client
$ilrDirectory = "$DownloadsDirectory\$ILRepack"
$ilrNupkg = "$ilrDirectory.zip" # Using .zip instead of .nupkg because Expand-Archive doesn't work with .nupkg
[System.Console]::WriteLine("Downloading $SteamCmd...")
$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile($IlrDownloadUrl, $ilrNupkg)
	
# Make sure ILRepack was downloaded
if(!(Test-Path $ilrNupkg -PathType Leaf))
{
	throw [System.IO.FileNotFoundException] "$ilrNupkg"
}
[System.Console]::WriteLine("Successfully downloaded $ILRepack")
	
# Unzip ILRepack
[System.Console]::WriteLine("Extracting files from $ilrNupkg...")
Expand-Archive -Path $ilrNupkg -Destination $ilrDirectory -Force
	
# Make sure ILRepack was unzipped
$ilrExe= "$ilrDirectory\tools\$ILRepack.exe"
if(!(Test-Path $ilrExe -PathType Leaf))
{
	throw [System.IO.FileNotFoundException] "$ilrExe"
}
[System.Console]::WriteLine("Successfully extracted files from $ilrNupkg")

# Run ILRepack to merge all the output .dll and .pdb files
[System.Console]::WriteLine("Running ILRepack...")
$SotM_ModBaseDll = "$ArtifactStagingDirectory\SotM_ModBase.dll"
$EngineCommonDll = "$ArtifactStagingDirectory\EngineCommon.dll"
$SentinelsEngineDll = "$ArtifactStagingDirectory\SentinelsEngine.dll"
$NunitFrameworkDll = "$ArtifactStagingDirectory\nunit.framework.dll"
$mergedDll = "$ArtifactStagingDirectory\merged\SotM_ModBase.dll"
& $ilrExe -wildcards -out:$mergedDll $SotM_ModBaseDll $EngineCommonDll $SentinelsEngineDll $NunitFrameworkDll
	
# Make sure DLLs were merged
if(!(Test-Path $mergedDll -PathType Leaf))
{
	throw [System.IO.FileNotFoundException] "$mergedDll"
}
[System.Console]::WriteLine("Successfully ran ILRepack")

# Get the versions of all of our DLLs
$SotM_ModBaseVer = $SotM_ModBaseDll.VersionInfo.FileVersionRaw
$EngineCommonVer = $EngineCommonDll.VersionInfo.FileVersionRaw
$SentinelsEngineVer = $SentinelsEngineDll.VersionInfo.FileVersionRaw
$NunitFrameworkVer = $NunitFrameworkDll.VersionInfo.FileVersionRaw

# Create json to store all the versions of our dependencies, for us to check next time
$json = @"
{
	"SotM_ModBaseVer": $SotM_ModBaseVer,
	"EngineCommonVer": $EngineCommonVer,
	"SentinelsEngineVer": $SentinelsEngineVer,
	"NunitFrameworkVer": $NunitFrameworkVer
}
"@

# Write string to file
$json | ConvertTo-Json -depth 100 | Out-File "$ArtifactStagingDirectory\version.json"

### TESTING REGION
