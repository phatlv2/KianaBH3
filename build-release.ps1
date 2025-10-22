# Build Release Script for KianaBH3
# This script builds the solution and places KianaBH.exe at the root of .Release folder

param(
    [switch]$Clean = $false,
    [switch]$SkipBuild = $false
)

$ErrorActionPreference = "Stop"

# Define paths
$SolutionPath = "KianaBH.sln"
$ReleasePath = ".Release"
$BinPath = "$ReleasePath\bin"
$ConfigPath = "$ReleasePath\Config"

Write-Host "=== KianaBH3 Release Build Script ===" -ForegroundColor Green

# Clean previous build if requested
if ($Clean) {
    Write-Host "Cleaning previous build..." -ForegroundColor Yellow
    if (Test-Path "$ReleasePath\KianaBH.exe") {
        Remove-Item -Path "$ReleasePath\KianaBH.*" -Force
    }
    if (Test-Path "$ReleasePath\Kiana.ico") {
        Remove-Item -Path "$ReleasePath\Kiana.ico" -Force
    }
    dotnet clean $SolutionPath --configuration Release
}

# Create release directory structure
Write-Host "Creating release directory structure..." -ForegroundColor Yellow
$directories = @(
    $BinPath,
    "$BinPath\Common",
    "$BinPath\GameServer", 
    "$BinPath\SdkServer",
    "$BinPath\Proto",
    "$BinPath\KcpSharp",
    $ConfigPath
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created directory: $dir" -ForegroundColor Gray
    }
}

# Restore packages and build the solution
if (!$SkipBuild) {
    Write-Host "Restoring NuGet packages..." -ForegroundColor Yellow
    dotnet restore $SolutionPath
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Package restore failed!"
        exit 1
    }
    
    Write-Host "Building solution..." -ForegroundColor Yellow
    dotnet build $SolutionPath --configuration Release --no-restore
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed!"
        exit 1
    }
}

# Function to copy build outputs for library projects
function Copy-LibraryOutput {
    param(
        [string]$ProjectName,
        [string]$SourcePath,
        [string]$TargetPath
    )
    
    if (Test-Path $SourcePath) {
        Write-Host "Copying $ProjectName outputs..." -ForegroundColor Cyan
        
        # Copy main assembly
        $dllFiles = Get-ChildItem -Path $SourcePath -Filter "*.dll" -Recurse
        foreach ($dll in $dllFiles) {
            Copy-Item -Path $dll.FullName -Destination $TargetPath -Force
            Write-Host "  Copied: $($dll.Name)" -ForegroundColor Gray
        }
        
        # Copy PDB files for debugging
        $pdbFiles = Get-ChildItem -Path $SourcePath -Filter "*.pdb" -Recurse
        foreach ($pdb in $pdbFiles) {
            Copy-Item -Path $pdb.FullName -Destination $TargetPath -Force
            Write-Host "  Copied: $($pdb.Name)" -ForegroundColor Gray
        }
        
        # Copy dependencies
        $depsFiles = Get-ChildItem -Path $SourcePath -Filter "*.deps.json" -Recurse
        foreach ($deps in $depsFiles) {
            Copy-Item -Path $deps.FullName -Destination $TargetPath -Force
            Write-Host "  Copied: $($deps.Name)" -ForegroundColor Gray
        }
    } else {
        Write-Warning "Source path not found: $SourcePath"
    }
}

# Copy library outputs to bin folders
Write-Host "Copying library outputs..." -ForegroundColor Yellow

# Common project
Copy-LibraryOutput -ProjectName "Common" -SourcePath "Common\bin\Release\net9.0" -TargetPath "$BinPath\Common"

# GameServer project  
Copy-LibraryOutput -ProjectName "GameServer" -SourcePath "GameServer\bin\Release\net9.0" -TargetPath "$BinPath\GameServer"

# SdkServer project
Copy-LibraryOutput -ProjectName "SdkServer" -SourcePath "SdkServer\bin\Release\net9.0" -TargetPath "$BinPath\SdkServer"

# Proto project
Copy-LibraryOutput -ProjectName "Proto" -SourcePath "Proto\bin\Release\net9.0" -TargetPath "$BinPath\Proto"

# KcpSharp project
Copy-LibraryOutput -ProjectName "KcpSharp" -SourcePath "KcpSharp\bin\Release\net9.0" -TargetPath "$BinPath\KcpSharp"

# Copy configuration files
Write-Host "Copying configuration files..." -ForegroundColor Yellow
if (Test-Path "Config") {
    Copy-Item -Path "Config\*" -Destination $ConfigPath -Recurse -Force
    Write-Host "  Copied configuration files" -ForegroundColor Gray
}

# Copy additional runtime files
Write-Host "Copying additional runtime files..." -ForegroundColor Yellow

# Copy icon file if it exists
$iconSource = "KianaBH\Source\Kiana.ico"
if (Test-Path $iconSource) {
    Copy-Item -Path $iconSource -Destination $ReleasePath -Force
    Write-Host "  Copied: Kiana.ico" -ForegroundColor Gray
}

# Create a simple batch file to run the main application
$batchContent = @"
@echo off
echo Starting KianaBH3 Server...
cd /d "%~dp0"
KianaBH.exe
pause
"@

$batchContent | Out-File -FilePath "$ReleasePath\start-server.bat" -Encoding ASCII
Write-Host "  Created: start-server.bat" -ForegroundColor Gray

# Create a README for the release
$readmeContent = @"
# KianaBH3 Release Build

This folder contains the built KianaBH3 server.

## Directory Structure

- **KianaBH.exe** - Main application executable
- **Kiana.ico** - Application icon
- **start-server.bat** - Server startup script
- **bin/Common/** - Common library assemblies
- **bin/GameServer/** - Game server assemblies  
- **bin/SdkServer/** - SDK server assemblies
- **bin/Proto/** - Protocol buffer assemblies
- **bin/KcpSharp/** - KCP networking library
- **Config/** - Configuration files
- **Assets/** - Game assets
- **Resources/** - Game resources

## Running the Server

1. Double-click `start-server.bat` to start the server
2. Or run `KianaBH.exe` directly

## Build Information

- Built on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- .NET Version: 9.0
- Configuration: Release
"@

$readmeContent | Out-File -FilePath "$ReleasePath\README.md" -Encoding UTF8
Write-Host "  Created: README.md" -ForegroundColor Gray

Write-Host "`n=== Build Complete ===" -ForegroundColor Green
Write-Host "Release files are available in: $ReleasePath" -ForegroundColor Cyan
Write-Host "Main executable: $ReleasePath\KianaBH.exe" -ForegroundColor Cyan
Write-Host "To start the server, run: $ReleasePath\start-server.bat" -ForegroundColor Cyan
