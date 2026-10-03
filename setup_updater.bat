@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

rem ------------------------------------------------------------
rem Colors
rem ------------------------------------------------------------

for /f "delims=" %%A in ('powershell -NoProfile -Command "[char]27"') do set "ESC=%%A"

set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "GRAY=%ESC%[90m"
set "RESET=%ESC%[0m"

set "REPO=ctrl-bownes/simple-server-rust"
set "API=https://api.github.com/repos/%REPO%/releases/latest"
set "TEMP_DIR=%TEMP%\rust_server_package_update"
set "ROOT_DIR=%~dp0"

echo.
echo %GRAY%[DEBUG] Script directory: %ROOT_DIR%%RESET%
echo %GRAY%[DEBUG] GitHub repository: %REPO%%RESET%
echo %GRAY%[DEBUG] GitHub API: %API%%RESET%
echo %GRAY%[DEBUG] Temporary directory: %TEMP_DIR%%RESET%
echo.


rem ------------------------------------------------------------
rem --check is used by start_server.bat.
rem
rem   0 = no update needed
rem   1 = update available
rem   2 = check failed
rem ------------------------------------------------------------

if /I "%~1"=="--check" goto check

goto update


:check

echo.
echo %CYAN%======================================%RESET%
echo %CYAN%       Checking for Package Update%RESET%
echo %CYAN%======================================%RESET%
echo.

echo %GRAY%[DEBUG] Running in --check mode.%RESET%
echo %GRAY%[DEBUG] This mode only checks for an update.%RESET%
echo %GRAY%[DEBUG] No files will be modified.%RESET%
echo.


rem ------------------------------------------------------------
rem Get the latest version from GitHub.
rem ------------------------------------------------------------

echo %CYAN%Checking GitHub for package updates...%RESET%
echo %GRAY%[DEBUG] Creating temporary directory if necessary...%RESET%

if not exist "%TEMP_DIR%" (
    mkdir "%TEMP_DIR%"

    if errorlevel 1 (
        echo %RED%[DEBUG] Failed to create temporary directory.%RESET%
        exit /b 2
    )

    echo %GRAY%[DEBUG] Temporary directory created.%RESET%
) else (
    echo %GRAY%[DEBUG] Temporary directory already exists.%RESET%
)

echo.
echo %GRAY%[DEBUG] Requesting latest GitHub release...%RESET%
echo %GRAY%[DEBUG] URL: %API%%RESET%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; try { $h=@{'User-Agent'='Rust-Server-Tutorial-Updater'}; $r=Invoke-RestMethod -Uri '%API%' -Headers $h; $remote=[string]$r.tag_name; if([string]::IsNullOrWhiteSpace($remote)){throw 'GitHub release has no tag.'}; Set-Content -Path '%TEMP_DIR%\check_remote.txt' -Value $remote -NoNewline; Write-Host ('[DEBUG] GitHub release found: ' + $remote) } catch { Write-Host ('Update check failed: ' + $_.Exception.Message) -ForegroundColor Red; exit 1 }"

if errorlevel 1 (
    echo %RED%[DEBUG] PowerShell GitHub request failed.%RESET%
    exit /b 2
)

echo %GRAY%[DEBUG] GitHub request completed successfully.%RESET%

if not exist "%TEMP_DIR%\check_remote.txt" (
    echo %RED%[DEBUG] check_remote.txt was not created.%RESET%
    echo %RED%[DEBUG] Cannot continue without the remote version.%RESET%
    exit /b 2
)

echo %GRAY%[DEBUG] Reading remote version from temporary file...%RESET%

set /p "REMOTE_VERSION="<"%TEMP_DIR%\check_remote.txt"

echo %GRAY%[DEBUG] Remote version read: %REMOTE_VERSION%%RESET%

del /f /q "%TEMP_DIR%\check_remote.txt" >nul 2>&1

echo %GRAY%[DEBUG] Temporary remote version file removed.%RESET%
echo.


rem ------------------------------------------------------------
rem Read local version.
rem ------------------------------------------------------------

echo %GRAY%[DEBUG] Looking for local .version file...%RESET%

set "LOCAL_VERSION="

if exist ".version" (
    set /p "LOCAL_VERSION="<".version"
    echo %GRAY%[DEBUG] .version file found.%RESET%
    echo %GRAY%[DEBUG] Local version read: %LOCAL_VERSION%%RESET%
) else (
    echo %GRAY%[DEBUG] .version file was not found.%RESET%
)


rem ------------------------------------------------------------
rem Display versions.
rem ------------------------------------------------------------

echo.
if defined LOCAL_VERSION (
    echo Current version: %GREEN%%LOCAL_VERSION%%RESET%
) else (
    echo Current version: %YELLOW%not found%RESET%
)

echo Latest version:  %CYAN%%REMOTE_VERSION%%RESET%
echo.


rem ------------------------------------------------------------
rem Validate remote version.
rem ------------------------------------------------------------

echo %GRAY%[DEBUG] Validating remote version format...%RESET%

echo %REMOTE_VERSION%| findstr /r /x /c:"v[0-9][0-9]*\.[0-9][0-9]*" >nul

if errorlevel 1 (
    echo %RED%ERROR: Invalid remote version format: %REMOTE_VERSION%%RESET%
    echo %RED%[DEBUG] Expected format: v0.1, v0.2, v1.0, v12.34, etc.%RESET%
    exit /b 2
)

echo %GRAY%[DEBUG] Remote version format is valid.%RESET%


rem ------------------------------------------------------------
rem No local version means an update is needed.
rem ------------------------------------------------------------

if not defined LOCAL_VERSION (
    echo.
    echo %YELLOW%No local version was found. An update is available.%RESET%
    echo %GRAY%[DEBUG] Returning exit code 1 to start_server.bat.%RESET%
    exit /b 1
)


rem ------------------------------------------------------------
rem Validate local version.
rem ------------------------------------------------------------

echo %GRAY%[DEBUG] Validating local version format...%RESET%

echo %LOCAL_VERSION%| findstr /r /x /c:"v[0-9][0-9]*\.[0-9][0-9]*" >nul

if errorlevel 1 (
    echo %RED%ERROR: Invalid local version format: %LOCAL_VERSION%%RESET%
    echo %RED%[DEBUG] Expected format: v0.1, v0.2, v1.0, v12.34, etc.%RESET%
    exit /b 2
)

echo %GRAY%[DEBUG] Local version format is valid.%RESET%


rem ------------------------------------------------------------
rem Remove the "v".
rem ------------------------------------------------------------

echo %GRAY%[DEBUG] Removing version prefix...%RESET%

set "LOCAL_NUM=%LOCAL_VERSION:v=%"
set "REMOTE_NUM=%REMOTE_VERSION:v=%"

echo %GRAY%[DEBUG] Local numeric version: %LOCAL_NUM%%RESET%
echo %GRAY%[DEBUG] Remote numeric version: %REMOTE_NUM%%RESET%


rem ------------------------------------------------------------
rem Split versions into major and minor numbers.
rem ------------------------------------------------------------

echo %GRAY%[DEBUG] Splitting version numbers...%RESET%

for /f "tokens=1,2 delims=." %%A in ("%LOCAL_NUM%") do (
    set "LOCAL_MAJOR=%%A"
    set "LOCAL_MINOR=%%B"
)

for /f "tokens=1,2 delims=." %%A in ("%REMOTE_NUM%") do (
    set "REMOTE_MAJOR=%%A"
    set "REMOTE_MINOR=%%B"
)

echo %GRAY%[DEBUG] Local major: !LOCAL_MAJOR!%RESET%
echo %GRAY%[DEBUG] Local minor: !LOCAL_MINOR!%RESET%
echo %GRAY%[DEBUG] Remote major: !REMOTE_MAJOR!%RESET%
echo %GRAY%[DEBUG] Remote minor: !REMOTE_MINOR!%RESET%


rem ------------------------------------------------------------
rem Convert the numbers to integers.
rem ------------------------------------------------------------

set /a LOCAL_MAJOR=LOCAL_MAJOR
set /a LOCAL_MINOR=LOCAL_MINOR
set /a REMOTE_MAJOR=REMOTE_MAJOR
set /a REMOTE_MINOR=REMOTE_MINOR

echo %GRAY%[DEBUG] Numeric comparison values:%RESET%
echo %GRAY%[DEBUG]   Local  = !LOCAL_MAJOR!.!LOCAL_MINOR!%RESET%
echo %GRAY%[DEBUG]   Remote = !REMOTE_MAJOR!.!REMOTE_MINOR!%RESET%
echo.


rem ------------------------------------------------------------
rem Compare versions.
rem ------------------------------------------------------------

echo %GRAY%[DEBUG] Comparing local and remote versions...%RESET%

if !REMOTE_MAJOR! GTR !LOCAL_MAJOR! (
    echo %YELLOW%An update is available.%RESET%
    echo %GRAY%[DEBUG] Remote major version is newer.%RESET%
    echo %GRAY%[DEBUG] Returning exit code 1 to start_server.bat.%RESET%
    exit /b 1
)

if !REMOTE_MAJOR! LSS !LOCAL_MAJOR! (
    echo %YELLOW%Installed version is newer than the latest release.%RESET%
    echo %YELLOW%No downgrade will be performed.%RESET%
    echo %GRAY%[DEBUG] Remote major version is older.%RESET%
    echo %GRAY%[DEBUG] Returning exit code 0 to start_server.bat.%RESET%
    exit /b 0
)

if !REMOTE_MINOR! GTR !LOCAL_MINOR! (
    echo %YELLOW%An update is available.%RESET%
    echo %GRAY%[DEBUG] Remote minor version is newer.%RESET%
    echo %GRAY%[DEBUG] Returning exit code 1 to start_server.bat.%RESET%
    exit /b 1
)

if !REMOTE_MINOR! LSS !LOCAL_MINOR! (
    echo %YELLOW%Installed version is newer than the latest release.%RESET%
    echo %YELLOW%No downgrade will be performed.%RESET%
    echo %GRAY%[DEBUG] Remote minor version is older.%RESET%
    echo %GRAY%[DEBUG] Returning exit code 0 to start_server.bat.%RESET%
    exit /b 0
)

echo %GREEN%You already have the latest version.%RESET%
echo %GRAY%[DEBUG] Versions are identical.%RESET%
echo %GRAY%[DEBUG] Returning exit code 0 to start_server.bat.%RESET%
exit /b 0


:update

echo.
echo %CYAN%======================================%RESET%
echo %CYAN%   Rust Server Guide Package Updater%RESET%
echo %CYAN%======================================%RESET%
echo.

echo %GRAY%[DEBUG] Running in full update mode.%RESET%
echo %GRAY%[DEBUG] Package root: %ROOT_DIR%%RESET%
echo %GRAY%[DEBUG] Temporary directory: %TEMP_DIR%%RESET%
echo.


rem ------------------------------------------------------------
rem Prepare temporary directory.
rem ------------------------------------------------------------

echo %CYAN%Preparing update environment...%RESET%

if exist "%TEMP_DIR%" (
    echo %GRAY%[DEBUG] Removing old temporary directory...%RESET%
    rmdir /s /q "%TEMP_DIR%"

    if errorlevel 1 (
        echo %RED%[DEBUG] Failed to remove old temporary directory.%RESET%
        goto failed
    )

    echo %GRAY%[DEBUG] Old temporary directory removed.%RESET%
)

mkdir "%TEMP_DIR%"

if errorlevel 1 (
    echo %RED%[DEBUG] Failed to create temporary directory.%RESET%
    goto failed
)

echo %GRAY%[DEBUG] Temporary directory created successfully.%RESET%
echo.


rem ------------------------------------------------------------
rem Get latest release information.
rem ------------------------------------------------------------

echo %CYAN%Checking the latest package release on GitHub...%RESET%
echo %GRAY%[DEBUG] API URL: %API%%RESET%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; try { $h=@{'User-Agent'='Rust-Server-Tutorial-Updater'}; $r=Invoke-RestMethod -Uri '%API%' -Headers $h; $remote=[string]$r.tag_name; if([string]::IsNullOrWhiteSpace($remote)){throw 'GitHub release has no tag.'}; $asset=$null; foreach($a in $r.assets){if($a.name -like 'simple-server-rust-*.zip'){$asset=$a;break}}; if($null -eq $asset){throw 'No simple-server-rust ZIP asset was found in the latest release.'}; Set-Content -Path '%TEMP_DIR%\remote_version.txt' -Value $remote -NoNewline; Set-Content -Path '%TEMP_DIR%\asset_url.txt' -Value $asset.browser_download_url -NoNewline; Write-Host ('[DEBUG] Latest release: ' + $remote); Write-Host ('[DEBUG] Release asset: ' + $asset.name); Write-Host ('[DEBUG] Asset URL: ' + $asset.browser_download_url) } catch { Write-Host ('ERROR: ' + $_.Exception.Message); exit 1 }"

if errorlevel 1 (
    echo %RED%[DEBUG] Failed to retrieve GitHub release information.%RESET%
    goto failed
)

echo %GRAY%[DEBUG] GitHub release information retrieved successfully.%RESET%
echo.


rem ------------------------------------------------------------
rem Read release information.
rem ------------------------------------------------------------

echo %GRAY%[DEBUG] Reading temporary release information...%RESET%

set /p "REMOTE_VERSION="<"%TEMP_DIR%\remote_version.txt"
set /p "ASSET_URL="<"%TEMP_DIR%\asset_url.txt"

echo %GRAY%[DEBUG] Remote version: %REMOTE_VERSION%%RESET%
echo %GRAY%[DEBUG] Asset URL: %ASSET_URL%%RESET%
echo.


rem ------------------------------------------------------------
rem Read local version.
rem ------------------------------------------------------------

set "LOCAL_VERSION="

if exist ".version" (
    set /p "LOCAL_VERSION="<".version"
    echo %GRAY%[DEBUG] Local .version found: %LOCAL_VERSION%%RESET%
) else (
    echo %GRAY%[DEBUG] No local .version file found.%RESET%
)


if defined LOCAL_VERSION (
    echo Installed version: %GREEN%%LOCAL_VERSION%%RESET%
) else (
    echo Installed version: %YELLOW%not found%RESET%
)

echo Latest version: %CYAN%%REMOTE_VERSION%%RESET%
echo.


rem ------------------------------------------------------------
rem Compare local and remote versions.
rem ------------------------------------------------------------

if not defined LOCAL_VERSION (
    echo %YELLOW%No local version was found.%RESET%
    echo %GRAY%[DEBUG] Update will be installed because there is no .version file.%RESET%
    goto download_update
)

echo %GRAY%[DEBUG] Validating local version...%RESET%

echo %LOCAL_VERSION%| findstr /r /x /c:"v[0-9][0-9]*\.[0-9][0-9]*" >nul

if errorlevel 1 (
    echo %RED%ERROR: Invalid local version format: %LOCAL_VERSION%%RESET%
    echo %RED%[DEBUG] Expected format: v0.1, v0.2, v1.0, etc.%RESET%
    goto failed
)

echo %GRAY%[DEBUG] Local version is valid.%RESET%

echo %GRAY%[DEBUG] Validating remote version...%RESET%

echo %REMOTE_VERSION%| findstr /r /x /c:"v[0-9][0-9]*\.[0-9][0-9]*" >nul

if errorlevel 1 (
    echo %RED%ERROR: Invalid remote version format: %REMOTE_VERSION%%RESET%
    echo %RED%[DEBUG] Expected format: v0.1, v0.2, v1.0, etc.%RESET%
    goto failed
)

echo %GRAY%[DEBUG] Remote version is valid.%RESET%


set "LOCAL_NUM=%LOCAL_VERSION:v=%"
set "REMOTE_NUM=%REMOTE_VERSION:v=%"

echo %GRAY%[DEBUG] Local numeric version: %LOCAL_NUM%%RESET%
echo %GRAY%[DEBUG] Remote numeric version: %REMOTE_NUM%%RESET%

for /f "tokens=1,2 delims=." %%A in ("%LOCAL_NUM%") do (
    set "LOCAL_MAJOR=%%A"
    set "LOCAL_MINOR=%%B"
)

for /f "tokens=1,2 delims=." %%A in ("%REMOTE_NUM%") do (
    set "REMOTE_MAJOR=%%A"
    set "REMOTE_MINOR=%%B"
)

echo %GRAY%[DEBUG] Local major: !LOCAL_MAJOR!%RESET%
echo %GRAY%[DEBUG] Local minor: !LOCAL_MINOR!%RESET%
echo %GRAY%[DEBUG] Remote major: !REMOTE_MAJOR!%RESET%
echo %GRAY%[DEBUG] Remote minor: !REMOTE_MINOR!%RESET%

set /a LOCAL_MAJOR=LOCAL_MAJOR
set /a LOCAL_MINOR=LOCAL_MINOR
set /a REMOTE_MAJOR=REMOTE_MAJOR
set /a REMOTE_MINOR=REMOTE_MINOR

echo %GRAY%[DEBUG] Comparing versions:%RESET%
echo %GRAY%[DEBUG]   Local  = !LOCAL_MAJOR!.!LOCAL_MINOR!%RESET%
echo %GRAY%[DEBUG]   Remote = !REMOTE_MAJOR!.!REMOTE_MINOR!%RESET%
echo.


if !REMOTE_MAJOR! LSS !LOCAL_MAJOR! (
    echo %YELLOW%Installed version is newer than the latest release.%RESET%
    echo %YELLOW%No downgrade will be performed.%RESET%
    echo %GRAY%[DEBUG] Remote major version is lower.%RESET%
    rmdir /s /q "%TEMP_DIR%"
    goto done
)

if !REMOTE_MAJOR! EQU !LOCAL_MAJOR! (
    if !REMOTE_MINOR! LSS !LOCAL_MINOR! (
        echo %YELLOW%Installed version is newer than the latest release.%RESET%
        echo %YELLOW%No downgrade will be performed.%RESET%
        echo %GRAY%[DEBUG] Remote minor version is lower.%RESET%
        rmdir /s /q "%TEMP_DIR%"
        goto done
    )

    if !REMOTE_MINOR! EQU !LOCAL_MINOR! (
        echo %GREEN%You already have the latest version.%RESET%
        echo %GRAY%[DEBUG] Local and remote versions are identical.%RESET%
        rmdir /s /q "%TEMP_DIR%"
        goto done
    )
)

echo %GRAY%[DEBUG] Remote version is newer. Continuing with update.%RESET%
echo.


:download_update

echo %CYAN%Downloading package update from GitHub...%RESET%
echo %GRAY%[DEBUG] Download URL: %ASSET_URL%%RESET%
echo %GRAY%[DEBUG] Destination: %TEMP_DIR%\update.zip%RESET%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; try { $h=@{'User-Agent'='Rust-Server-Tutorial-Updater'}; Invoke-WebRequest -Uri '%ASSET_URL%' -Headers $h -OutFile '%TEMP_DIR%\update.zip'; Write-Host '[DEBUG] Download completed successfully.' } catch { Write-Host ('ERROR: ' + $_.Exception.Message); exit 1 }"

if errorlevel 1 (
    echo %RED%[DEBUG] Package download failed.%RESET%
    goto failed
)

if not exist "%TEMP_DIR%\update.zip" (
    echo %RED%[DEBUG] update.zip does not exist after download.%RESET%
    goto failed
)

echo %GRAY%[DEBUG] update.zip exists.%RESET%

for %%A in ("%TEMP_DIR%\update.zip") do (
    echo %GRAY%[DEBUG] Downloaded file size: %%~zA bytes%RESET%
)

echo.
echo %GREEN%Download complete.%RESET%
echo.


rem ------------------------------------------------------------
rem Extract update.
rem ------------------------------------------------------------

echo %CYAN%Extracting package update...%RESET%
echo %GRAY%[DEBUG] Extraction destination: %TEMP_DIR%\extracted%RESET%

mkdir "%TEMP_DIR%\extracted"

if errorlevel 1 (
    echo %RED%[DEBUG] Failed to create extraction directory.%RESET%
    goto failed
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; try { Expand-Archive -Path '%TEMP_DIR%\update.zip' -DestinationPath '%TEMP_DIR%\extracted' -Force; Write-Host '[DEBUG] ZIP extraction completed successfully.' } catch { Write-Host ('ERROR: ' + $_.Exception.Message); exit 1 }"

if errorlevel 1 (
    echo %RED%[DEBUG] ZIP extraction failed.%RESET%
    goto failed
)

echo %GREEN%Extraction complete.%RESET%
echo.


rem ------------------------------------------------------------
rem Find actual package root.
rem ------------------------------------------------------------

echo %CYAN%Locating package files...%RESET%
echo %GRAY%[DEBUG] Initial package root: %TEMP_DIR%\extracted%RESET%

set "PACKAGE_ROOT=%TEMP_DIR%\extracted"

if exist "%TEMP_DIR%\extracted\setup.bat" (
    echo %GRAY%[DEBUG] setup.bat found directly inside extracted folder.%RESET%
    goto root_found
)

echo %GRAY%[DEBUG] setup.bat not found at extraction root.%RESET%
echo %GRAY%[DEBUG] Searching for a wrapper folder...%RESET%

for /f "delims=" %%D in ('dir /b /ad "%TEMP_DIR%\extracted" 2^>nul') do (
    echo %GRAY%[DEBUG] Checking folder: %%D%RESET%

    if exist "%TEMP_DIR%\extracted\%%D\setup.bat" (
        set "PACKAGE_ROOT=%TEMP_DIR%\extracted\%%D"
        echo %GRAY%[DEBUG] setup.bat found in wrapper folder: %%D%RESET%
    )
)

:root_found

echo %GRAY%[DEBUG] Final package root: %PACKAGE_ROOT%%RESET%

if not exist "%PACKAGE_ROOT%\setup.bat" (
    echo %RED%[DEBUG] Could not find setup.bat in package root.%RESET%
    goto failed
)

echo %GRAY%[DEBUG] Package root validated.%RESET%
echo.


rem ------------------------------------------------------------
rem Update package files.
rem ------------------------------------------------------------

echo %CYAN%Updating package files...%RESET%
echo.


echo %GRAY%[DEBUG] Updating setup.bat...%RESET%

if not exist "%PACKAGE_ROOT%\setup.bat" (
    echo %RED%[DEBUG] Source setup.bat is missing.%RESET%
    goto failed
)

copy /y "%PACKAGE_ROOT%\setup.bat" "%~dp0setup.bat" >nul

if errorlevel 1 (
    echo %RED%[DEBUG] Failed to copy setup.bat.%RESET%
    goto failed
)

echo %GREEN%  setup.bat updated.%RESET%


echo %GRAY%[DEBUG] Updating README.txt...%RESET%

if not exist "%PACKAGE_ROOT%\README.txt" (
    echo %RED%[DEBUG] Source README.txt is missing.%RESET%
    goto failed
)

copy /y "%PACKAGE_ROOT%\README.txt" "%~dp0README.txt" >nul

if errorlevel 1 (
    echo %RED%[DEBUG] Failed to copy README.txt.%RESET%
    goto failed
)

echo %GREEN%  README.txt updated.%RESET%


echo %GRAY%[DEBUG] Updating guide...%RESET%

if exist "%PACKAGE_ROOT%\guide" (
    robocopy "%PACKAGE_ROOT%\guide" "%~dp0guide" /E /NFL /NDL /NJH /NJS /NP >nul

    if errorlevel 8 (
        echo %RED%[DEBUG] robocopy reported a failure while updating guide.%RESET%
        goto failed
    )

    echo %GREEN%  guide updated.%RESET%
) else (
    echo %YELLOW%[DEBUG] No guide folder was found in the update package.%RESET%
)

echo.


rem ------------------------------------------------------------
rem Prepare updater replacement.
rem ------------------------------------------------------------

echo %CYAN%Preparing updater update...%RESET%
echo %GRAY%[DEBUG] The current setup_updater.bat cannot replace itself directly.%RESET%
echo %GRAY%[DEBUG] Creating a temporary copy first...%RESET%

if not exist "%PACKAGE_ROOT%\setup_updater.bat" (
    echo %RED%[DEBUG] New setup_updater.bat was not found in package.%RESET%
    goto failed
)

copy /y "%PACKAGE_ROOT%\setup_updater.bat" "%TEMP_DIR%\setup_updater.new.bat" >nul

if errorlevel 1 (
    echo %RED%[DEBUG] Failed to prepare new setup_updater.bat.%RESET%
    goto failed
)

echo %GRAY%[DEBUG] New updater prepared successfully.%RESET%


rem ------------------------------------------------------------
rem Temporary helper to replace updater.
rem ------------------------------------------------------------

echo %GRAY%[DEBUG] Creating self-update helper...%RESET%

>"%TEMP_DIR%\apply_update.bat" echo @echo off
>>"%TEMP_DIR%\apply_update.bat" echo echo [DEBUG] Waiting for updater to finish...
>>"%TEMP_DIR%\apply_update.bat" echo timeout /t 2 /nobreak ^>nul
>>"%TEMP_DIR%\apply_update.bat" echo echo [DEBUG] Replacing setup_updater.bat...
>>"%TEMP_DIR%\apply_update.bat" echo copy /y "%TEMP_DIR%\setup_updater.new.bat" "%ROOT_DIR%setup_updater.bat" ^>nul
>>"%TEMP_DIR%\apply_update.bat" echo if errorlevel 1 echo WARNING: Could not replace setup_updater.bat
>>"%TEMP_DIR%\apply_update.bat" echo echo [DEBUG] Writing package version...
>>"%TEMP_DIR%\apply_update.bat" echo echo %REMOTE_VERSION%^>"%ROOT_DIR%.version"
>>"%TEMP_DIR%\apply_update.bat" echo echo [DEBUG] Cleaning temporary files...
>>"%TEMP_DIR%\apply_update.bat" echo rmdir /s /q "%TEMP_DIR%"
>>"%TEMP_DIR%\apply_update.bat" echo echo [DEBUG] Package update finished.
>>"%TEMP_DIR%\apply_update.bat" echo exit /b

if not exist "%TEMP_DIR%\apply_update.bat" (
    echo %RED%[DEBUG] Failed to create self-update helper.%RESET%
    goto failed
)

echo %GRAY%[DEBUG] Self-update helper created successfully.%RESET%
echo.


rem ------------------------------------------------------------
rem Launch helper.
rem ------------------------------------------------------------

echo %CYAN%Starting updater replacement process...%RESET%
echo %GRAY%[DEBUG] The helper will wait for this updater to finish.%RESET%

start "" /min cmd /c call "%TEMP_DIR%\apply_update.bat"

if errorlevel 1 (
    echo %RED%[DEBUG] Failed to start self-update helper.%RESET%
    goto failed
)

echo %GRAY%[DEBUG] Self-update helper started.%RESET%
echo.


echo.
echo %GREEN%Package update installed successfully.%RESET%
echo.
echo %CYAN%Updated:%RESET%
echo   - setup_updater.bat
echo   - setup.bat
echo   - README.txt
echo   - guide\*
echo.
echo %GRAY%Server files were NOT modified.%RESET%
echo %GRAY%start_server.bat was NOT modified.%RESET%
echo.
echo %YELLOW%The updater will finish replacing itself after this window closes.%RESET%
echo.

goto done


:failed

echo.
echo %RED%======================================%RESET%
echo %RED%           UPDATE FAILED%RESET%
echo %RED%======================================%RESET%
echo.
echo %RED%ERROR: The update could not be completed.%RESET%
echo.
echo %GRAY%[DEBUG] Temporary directory: %TEMP_DIR%%RESET%
echo %GRAY%[DEBUG] Package root: %ROOT_DIR%%RESET%
echo.

if exist "%TEMP_DIR%" (
    echo %GRAY%[DEBUG] Cleaning temporary directory...%RESET%
    rmdir /s /q "%TEMP_DIR%"

    if errorlevel 1 (
        echo %YELLOW%[DEBUG] WARNING: Could not completely remove temporary directory.%RESET%
    ) else (
        echo %GRAY%[DEBUG] Temporary directory removed.%RESET%
    )
)

echo.
pause
exit /b 1


:done

echo %GRAY%[DEBUG] Cleaning up and exiting updater.%RESET%
echo %GRAY%[DEBUG] Returning exit code 0.%RESET%
echo.

endlocal
pause
exit /b 0