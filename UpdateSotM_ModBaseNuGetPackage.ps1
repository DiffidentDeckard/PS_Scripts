
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
$mergedDll = "$ArtifactStagingDirectory\merged\SotM_ModBase.dll"
& $ilrExe -wildcards -out:$mergedDll "$ArtifactStagingDirectory\SotM_ModBase.dll" "$ArtifactStagingDirectory\EngineCommon.dll" "$ArtifactStagingDirectory\SentinelsEngine.dll" "$ArtifactStagingDirectory\nunit.framework.dll"
	
# Make sure DLLs were merged
if(!(Test-Path $mergedDll -PathType Leaf))
{
	throw [System.IO.FileNotFoundException] "$mergedDll"
}
[System.Console]::WriteLine("Successfully ran ILRepack")

### TESTING REGION
   echo $(build.buildid)
   
   echo $(build.buildnumber)