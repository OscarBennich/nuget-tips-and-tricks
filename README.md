# NuGet Tips & Tricks

## Using a local NuGet feed

### Add required properties to `.csproj` file
```cs
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
    <VersionSuffix>local</VersionSuffix> <!-- Local packages will be suffixed with "-local" (e.g. MyPackage.1.0.0-local) -->
  </PropertyGroup>

[...]
```

### Add build step to `.csproj` file to push package to local feed when building project in "Debug" mode
```cs
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

