# Determine the full SemVer version string for the NuGet package build, 
# then writes it out so Azure DevOps pipelines use it as the name of the build

param (
    [string]$projectFile,
    [string]$versionSuffix,
    [string]$buildSourceBranch  
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"

$versionPrefix = @(Select-Xml -Path $projectFile -XPath "/Project/PropertyGroup/VersionPrefix" | foreach { $_.node.InnerXML })[0]

$branchName = $buildSourceBranch.Split('refs/heads/')[1]

$isRelease = $branchName -eq "main"

if ($isRelease) {
    $version = $versionPrefix
}
else {
    $version = $versionPrefix + "-" + $versionSuffix
}

# UpdateBuildNumber: Override the automatically generated build number
Write-Host "##vso[build.updatebuildnumber]$version"
