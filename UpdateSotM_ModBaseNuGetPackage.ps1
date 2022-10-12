
# Get args
$ArtifactStagingDirectory = $args[0]

# Store the paths and filenames that we need
$DownloadsDirectory = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
$IlrDownloadUrl = "http://nuget.org/api/v2/package/ILRepack"
$ILRepack = "ILRepack"
$EngineCommon = "EngineCommon"
$SentinelsEngine = "SentinelsEngine"

[System.Console]::WriteLine("Artifact Staging Directory: $ArtifactStagingDirectory")
[System.Console]::WriteLine("Downloads directory: $DownloadsDirectory")
[System.Console]::WriteLine("$ILRepack Download URL: $IlrDownloadUrl")

# Download ILRepack through a web client
$ilrDirectory = "$DownloadsDirectory\$ILRepack"
$ilrNupkg = "$ilrDirectory.nupkg"
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
Install-Package -Name $ILRepack -Source $ilrNupkg -Destination $ilrDirectory
#Expand-Archive -Path $ilrNupkg -Destination $ilrDirectory -Force
	
# Make sure ILRepack was unzipped
$ilrExe= "$ilrDirectory\tools\$ILRepack.exe"
if(!(Test-Path $ilrExe -PathType Leaf))
{
	throw [System.IO.FileNotFoundException] "$ilrExe"
}
[System.Console]::WriteLine("Successfully extracted files from $ilrNupkg")

# Run ILRepack to merge all the output .dll and .pdb files
[System.Console]::WriteLine("Running ILRepack...")

[System.Console]::WriteLine("Successfully ran ILRepack")