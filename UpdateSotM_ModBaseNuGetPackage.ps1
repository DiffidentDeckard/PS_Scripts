
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
	
# Install ILRepack
[System.Console]::WriteLine("Installing $ILRepack...")
$ilrDirectory = "$DownloadsDirectory\$ILRepack"
Install-Package -Name $ILRepack -Source "https://api.nuget.org/v3/index.json" -Destination $ilrDirectory
	
# Make sure ILRepack was installed
$ilrExe= "$ilrDirectory\tools\$ILRepack.exe"
if(!(Test-Path $ilrExe -PathType Leaf))
{
	throw [System.IO.FileNotFoundException] "$ilrExe"
}
[System.Console]::WriteLine("Successfully installed $ILRepack")

# Run ILRepack to merge all the output .dll and .pdb files
[System.Console]::WriteLine("Running ILRepack...")

[System.Console]::WriteLine("Successfully ran ILRepack")