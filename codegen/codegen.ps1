# Get script directory to use as base for relative paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

function Build-CodegenIfNeeded {
    param (
        [string]$BuildDir,
        [string]$SourceDir
    )

    $executable = Join-Path $BuildDir "Codegen.exe"
    $releaseExecutable = Join-Path $BuildDir "Release\Codegen.exe"

    if (Test-Path $executable -PathType Leaf) {
        Write-Host "Found existing Codegen executable. Skipping build."
        return $executable
    }
    elseif (Test-Path $releaseExecutable -PathType Leaf) {
        Write-Host "Found existing Codegen Release executable. Skipping build."
        return $releaseExecutable
    }

    Write-Host "Codegen executable not found, starting build process..."

    if (-not (Test-Path $BuildDir)) {
        New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
    }

    Write-Host "Configuring CMake..."
    # Add timeout (e.g., 300 seconds = 5 minutes) to prevent hanging forever
    $configureProcess = Start-Process -FilePath "cmake" `
        -ArgumentList "-S", $SourceDir, "-B", $BuildDir `
        -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput "./cmake_configure_out.txt" `
        -RedirectStandardError "./cmake_configure_err.txt"

    if ($configureProcess -eq $null) {
        Write-Error "Failed to start cmake configure process."
        exit 1
    }

    if ($configureProcess.ExitCode -ne 0) {
        Write-Host "CMake configuration failed (ExitCode: $($configureProcess.ExitCode)):"
        Write-Host "--- Standard Output ---"
        Get-Content "./cmake_configure_out.txt" | ForEach-Object { Write-Host $_ }
        Write-Host "--- Standard Error ---"
        Get-Content "./cmake_configure_err.txt" | ForEach-Object { Write-Host $_ }
        exit $configureProcess.ExitCode
    }

    Write-Host "Building project..."
    $buildProcess = Start-Process -FilePath "cmake" `
        -ArgumentList "--build", $BuildDir, "--config", "Release" `
        -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput "./cmake_build_out.txt" `
        -RedirectStandardError "./cmake_build_err.txt"

    if ($buildProcess -eq $null) {
        Write-Error "Failed to start cmake build process."
        exit 1
    }

    if ($buildProcess.ExitCode -ne 0) {
        Write-Host "Build failed (ExitCode: $($buildProcess.ExitCode)):"
        Write-Host "--- Standard Output ---"
        Get-Content "./cmake_build_out.txt" | ForEach-Object { Write-Host $_ }
        Write-Host "--- Standard Error ---"
        Get-Content "./cmake_build_err.txt" | ForEach-Object { Write-Host $_ }
        exit $buildProcess.ExitCode
    }

    if (Test-Path $executable -PathType Leaf) {
        return $executable
    }
    elseif (Test-Path $releaseExecutable -PathType Leaf) {
        return $releaseExecutable
    }
    else {
        Write-Error "Executable not found in expected locations after build:"
        Write-Host "  $executable"
        Write-Host "  $releaseExecutable"
        exit 1
    }
}

function Run-CodegenOnFolders {
    param (
        [string]$ExePath
    )

    $bindingsDir = Resolve-Path (Join-Path $scriptDir "bindings/bindings") -ErrorAction SilentlyContinue
    $outputBaseDir = Resolve-Path (Join-Path $scriptDir "../src/data/versions") -ErrorAction SilentlyContinue

    if (-not $bindingsDir) {
        Write-Error "Bindings directory not found: bindings"
        exit 1
    }

    if (-not $outputBaseDir) {
        New-Item -ItemType Directory -Path (Join-Path $scriptDir "src/data/versions") -Force | Out-Null
        $outputBaseDir = Resolve-Path (Join-Path $scriptDir "src/data/versions")
    }

    Write-Host "Bindings directory: $bindingsDir"
    Write-Host "Output base directory: $outputBaseDir"

    $successfulFolders = @()

    Get-ChildItem -Path $bindingsDir -Directory | Sort-Object Name | ForEach-Object {
        $folder = $_
        if ($folder.Name.ToLower() -eq "include") {
            Write-Host "Skipping folder: $($folder.Name)"
            return
        }

        $entryBro = Join-Path $folder.FullName "Entry.bro"
        if (-not (Test-Path $entryBro)) {
            Write-Warning "Entry.bro not found in $($folder.Name), skipping."
            return
        }

        Write-Host "Running executable on folder: $($folder.Name)"
        $args = @("Win64", $folder.FullName, "./")

        Write-Host "Executing command: $ExePath $($args -join ' ')"

        $proc = Start-Process -FilePath $ExePath -ArgumentList $args -NoNewWindow -Wait -PassThru
        if ($proc.ExitCode -ne 0) {
            Write-Warning "Codegen error in folder $($folder.Name) with return code $($proc.ExitCode)"
        }
        else {
            Write-Host "Completed folder: $($folder.Name)"
            $successfulFolders += $folder.Name
        }
    }

    foreach ($version in $successfulFolders) {
        $srcFile = Join-Path $bindingsDir "$version\Geode\CodegenData.json"
        $destDir = Join-Path $outputBaseDir $version
        $destFile = Join-Path $destDir "codegen.json"

        # Always create the destination directory
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        if (-not (Test-Path $srcFile)) {
            Write-Warning "CodegenData.json not found for $version at expected path: $srcFile"
            continue
        }

        try {
            Copy-Item -Path $srcFile -Destination $destFile -Force
            Write-Host "Copied CodegenData.json for $version to $destFile"
        }
        catch {
            Write-Warning ("Failed to copy CodegenData.json for $($version): $($_.Exception.Message)")
        }
    }
}

# Main script execution

$sourceDir = Resolve-Path (Join-Path $scriptDir "bindings/codegen") -ErrorAction Stop
$buildDirObj = Resolve-Path (Join-Path $scriptDir "build") -ErrorAction SilentlyContinue
$buildDir = if ($buildDirObj) { $buildDirObj.Path } else { $null }

if (-not $buildDir) {
    New-Item -ItemType Directory -Path (Join-Path $scriptDir "build") -Force | Out-Null
    $buildDir = Resolve-Path (Join-Path $scriptDir "build") -ErrorAction Stop
}

$exePath = Build-CodegenIfNeeded -BuildDir $buildDir -SourceDir $sourceDir

if (-not (Test-Path $exePath -PathType Leaf)) {
    Write-Error "Codegen executable not found at $exePath"
    exit 1
}

Run-CodegenOnFolders -ExePath $exePath
