# NuGet Tips & Tricks

## Using a local NuGet feed

- A "local feed" is just a folder on your computer where we store packages that have been built locally and point to from other solutions (e.g. C:\Users\MYUSER\some\local\folder\nuget)

### Add required properties to `.csproj` file
```xml
[...]

  <PropertyGroup>
    [...]
    <VersionPrefix>1.0.0</VersionPrefix>
    <Description>NuGet package description...</Description>
    <PackageReadmeFile>README.md</PackageReadmeFile>
    <LocalFeed>$(USERPROFILE)\some\local\folder\nuget</LocalFeed>
    <LocalNugetCache>$(USERPROFILE)\.nuget\packages</LocalNugetCache>
  </PropertyGroup>

  <PropertyGroup Condition=" '$(Configuration)' == 'Debug' ">
    <GeneratePackageOnBuild>True</GeneratePackageOnBuild>
    <DebugType>embedded</DebugType>

    <!-- Local packages will be suffixed with "-local" (e.g. MyPackage.1.0.0-local) -->
    <VersionSuffix>local</VersionSuffix>
  </PropertyGroup>

[...]
```

### Add build step to `.csproj` file to push package to local feed when building project with the "Debug" configuration
```xml
  <Target Name="PushToLocalFeed" AfterTargets="Pack" Condition=" '$(Configuration)' == 'Debug' ">
    <!-- Get path to the produced NuGet package files -->
    <PropertyGroup>
      <PackagePath>$(MSBuildProjectDirectory)\$(PackageOutputPath)$(ProjectName).$(PackageVersion)</PackagePath>
      <ExpectedOutputPath>$(LocalFeed)\$(PackageId)\$(PackageVersion)</ExpectedOutputPath>
    </PropertyGroup>

    <!-- This will create the expected foler for the local NuGet packages feed (if it does not exist) -->
    <MakeDir Directories="$(LocalFeed)" />

    <RemoveDir Condition="Exists('$(ExpectedOutputPath)')" Directories="$(ExpectedOutputPath)" />

    <!-- Delete previous NuGet files for the same package version in the local cache -->
    <RemoveDir Directories="$(LocalNugetCache)\$(ProjectName)\$(PackageVersion)" />

    <!-- Push NuGet package to local feed -->
    <Exec Command="dotnet nuget push $(PackagePath).nupkg --source $(LocalFeed)" />
  </Target>
```

### Add the local NuGet feed to the consuming solution

- In the `nuget.config` file in the repo, add this:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="Local" value="%USERPROFILE%\\some\local\folder\nuget" />
	  [...]
  </packageSources>
</configuration>
```

### Debugging packages from your local feed
- Thanks for the `<DebugType>embedded</DebugType>` statement that we added to the `.csproj` file above, the debug files will be automatically embedded with the source code when building the project with the `Debug` configuration.
- This means that debugging the package should work out-of-the-box and feel equivalent to debugging any other code that might be contained in the solution.
- This is because the embedded debug information will have a pointer to the file on your local computer and can therefore "jump" there, similar to opening the file yourself.
- You can even make changes directly in that file from the other solution.

## Debugging packages pushed to an Azure DevOps feed
Debugging code that comes from a package in the Azure Artifacts feed is slightly more annoying, but works largely the same way as debugging the local NuGet packages described above.

For these packages we instead utilize the [Source Link library](https://github.com/dotnet/sourcelink) which is a Microsoft supported way to enable "first-class source debugging experiences for binaries".

### Add required properties to `.csproj` file

For this to work you need to add this to the `.csproj` file as well:

```xml
  <PropertyGroup Condition=" '$(Configuration)' == 'Release' ">
    <!-- Needed for PDBs to be included in nuget package(we are using Azure Devops Artifacts which doesn't support source packages): https://github.com/dotnet/sourcelink#alternative-pdb-distribution-->
    <AllowedOutputExtensionsInPackageBuildOutputFolder>$(AllowedOutputExtensionsInPackageBuildOutputFolder);.pdb</AllowedOutputExtensionsInPackageBuildOutputFolder>
  </PropertyGroup>
```

You also need to add a reference to the `Microsoft.SourceLink.AzureRepos.Git` NuGet package:

```xml
<PackageReference Include="Microsoft.SourceLink.AzureRepos.Git" Version="8.0.0" PrivateAssets="All" />
```

Now, when building the project with the `Release` configuration, the debug files (`.pdb`) will also be added together with the `.dll` files in the NuGet package. 

### Disable the "Enable Just My Code" option
To be able to utilize debugging in this way in Visual Studio, you also need to disable the "Enable Just My Code" option:

- Open Visual Studio
- Go to "Debug"
- Go to "Options"
- Go to "General"
- Disable the "Enable Just My Code" option > Click OK

> NOTE: In normal cases it is recommended to have this option **enabled** for the optimal developer experience. So when you are done debugging the remote package, you should re-enable this option

## Building a new NuGet package using the version from the `<VersionPrefix>` property (in Azure DevOps)

1. 

