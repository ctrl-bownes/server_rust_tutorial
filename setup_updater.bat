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

rem ------------------------------------------------------------
rem Get the latest version from GitHub.
rem ------------------------------------------------------------

if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; try { $h=@{'User-Agent'='Rust-Server-Tutorial-Updater'}; $r=Invoke-RestMethod -Uri '%API%' -Headers $h; $remote=[string]$r.tag_name; if([string]::IsNullOrWhiteSpace($remote)){throw 'GitHub release has no tag.'}; Set-Content -Path '%TEMP_DIR%\check_remote.txt' -Value $remote -NoNewline } catch { Write-Host ('Update check failed: ' + $_.Exception.Message) -ForegroundColor Red; exit 1 }"

if errorlevel 1 exit /b 2

if not exist "%TEMP_DIR%\check_remote.txt" exit /b 2

set /p "REMOTE_VERSION="<"%TEMP_DIR%\check_remote.txt"

del /f /q "%TEMP_DIR%\check_remote.txt" >nul 2>&1


rem ------------------------------------------------------------
rem Read local version.
rem ------------------------------------------------------------

set "LOCAL_VERSION="

if exist ".version" (
    set /p "LOCAL_VERSION="<".version"
)


rem ------------------------------------------------------------
rem Display versions.
rem ------------------------------------------------------------

if defined LOCAL_VERSION (
    echo Current version: %GREEN%%LOCAL_VERSION%%RESET%
) else (
    echo Current version: %YELLOW%not found%RESET%
)

echo Latest version:  %CYAN%%REMOTE_VERSION%%RESET%
echo.


rem ------------------------------------------------------------
rem Validate remote version.
rem Expected format:
rem
rem   v0.1
rem   v0.2
rem   v1.0
rem   v12.34
rem ------------------------------------------------------------

echo %REMOTE_VERSION%| findstr /r /x /c:"v[0-9][0-9]*\.[0-9][0-9]*" >nul

if errorlevel 1 (
    echo %RED%ERROR: Invalid remote version format: %REMOTE_VERSION%%RESET%
    exit /b 2
)


rem ------------------------------------------------------------
rem No local version means an update is needed.
rem ------------------------------------------------------------

if not defined LOCAL_VERSION (
    echo %YELLOW%No local version was found. An update is available.%RESET%
    exit /b 1
)


rem ------------------------------------------------------------
rem Validate local version.
rem ------------------------------------------------------------

echo %LOCAL_VERSION%| findstr /r /x /c:"v[0-9][0-9]*\.[0-9][0-9]*" >nul

if errorlevel 1 (
    echo %RED%ERROR: Invalid local version format: %LOCAL_VERSION%%RESET%
    exit /b 2
)


rem ------------------------------------------------------------
rem Remove the "v".
rem
rem Example:
rem   v0.2 -> 0.2
rem   v1.5 -> 1.5
rem ------------------------------------------------------------

set "LOCAL_NUM=%LOCAL_VERSION:v=%"
set "REMOTE_NUM=%REMOTE_VERSION:v=%"


rem ------------------------------------------------------------
rem Split versions into major and minor numbers.
rem ------------------------------------------------------------

for /f "tokens=1,2 delims=." %%A in ("%LOCAL_NUM%") do (
    set "LOCAL_MAJOR=%%A"
    set "LOCAL_MINOR=%%B"
)

for /f "tokens=1,2 delims=." %%A in ("%REMOTE_NUM%") do (
    set "REMOTE_MAJOR=%%A"
    set "REMOTE_MINOR=%%B"
)


rem ------------------------------------------------------------
rem Convert the numbers to integers.
rem ------------------------------------------------------------

set /a LOCAL_MAJOR=LOCAL_MAJOR
set /a LOCAL_MINOR=LOCAL_MINOR
set /a REMOTE_MAJOR=REMOTE_MAJOR
set /a REMOTE_MINOR=REMOTE_MINOR


rem ------------------------------------------------------------
rem Compare versions.
rem
rem Remote > Local:
rem     Update
rem
rem Remote = Local:
rem     No update
rem
rem Remote < Local:
rem     No downgrade
rem ------------------------------------------------------------

if !REMOTE_MAJOR! GTR !LOCAL_MAJOR! (
    echo %YELLOW%An update is available.%RESET%
    exit /b 1
)

if !REMOTE_MAJOR! LSS !LOCAL_MAJOR! (
    echo %YELLOW%Installed version is newer than the latest release.%RESET%
    echo %YELLOW%No downgrade will be performed.%RESET%
    exit /b 0
)

if !REMOTE_MINOR! GTR !LOCAL_MINOR! (
    echo %YELLOW%An update is available.%RESET%
    exit /b 1
)

if !REMOTE_MINOR! LSS !LOCAL_MINOR! (
    echo %YELLOW%Installed version is newer than the latest release.%RESET%
    echo %YELLOW%No downgrade will be performed.%RESET%
    exit /b 0
)

echo %GREEN%You already have the latest version.%RESET%
exit /b 0


:update

echo.
echo %CYAN%======================================%RESET%
echo %CYAN%   Rust Server Guide Package Updater%RESET%
echo %CYAN%======================================%RESET%
echo.

if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; try { $h=@{'User-Agent'='Rust-Server-Tutorial-Updater'}; $r=Invoke-RestMethod -Uri '%API%' -Headers $h; $remote=[string]$r.tag_name; if([string]::IsNullOrWhiteSpace($remote)){throw 'GitHub release has no tag.'}; $asset=$null; foreach($a in $r.assets){if($a.name -like 'simple-server-rust-*.zip'){$asset=$a;break}}; if($null -eq $asset){throw 'No simple-server-rust ZIP asset was found in the latest release.'}; Set-Content -Path '%TEMP_DIR%\remote_version.txt' -Value $remote -NoNewline; Set-Content -Path '%TEMP_DIR%\asset_url.txt' -Value $asset.browser_download_url -NoNewline; Write-Host ('Latest version: ' + $remote); Write-Host ('Asset: ' + $asset.name) } catch { Write-Host ('ERROR: ' + $_.Exception.Message); exit 1 }"

if errorlevel 1 goto failed

set /p "REMOTE_VERSION="<"%TEMP_DIR%\remote_version.txt"
set /p "ASSET_URL="<"%TEMP_DIR%\asset_url.txt"

set "LOCAL_VERSION="

if exist ".version" (
    set /p "LOCAL_VERSION="<".version"
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
rem
rem Only continue if the remote version is NEWER.
rem ------------------------------------------------------------

if not defined LOCAL_VERSION goto download_update

echo %LOCAL_VERSION%| findstr /r /x /c:"v[0-9][0-9]*\.[0-9][0-9]*" >nul

if errorlevel 1 (
    echo %RED%ERROR: Invalid local version format: %LOCAL_VERSION%%RESET%
    goto failed
)

echo %REMOTE_VERSION%| findstr /r /x /c:"v[0-9][0-9]*\.[0-9][0-9]*" >nul

if errorlevel 1 (
    echo %RED%ERROR: Invalid remote version format: %REMOTE_VERSION%%RESET%
    goto failed
)

set "LOCAL_NUM=%LOCAL_VERSION:v=%"
set "REMOTE_NUM=%REMOTE_VERSION:v=%"

for /f "tokens=1,2 delims=." %%A in ("%LOCAL_NUM%") do (
    set "LOCAL_MAJOR=%%A"
    set "LOCAL_MINOR=%%B"
)

for /f "tokens=1,2 delims=." %%A in ("%REMOTE_NUM%") do (
    set "REMOTE_MAJOR=%%A"
    set "REMOTE_MINOR=%%B"
)

set /a LOCAL_MAJOR=LOCAL_MAJOR
set /a LOCAL_MINOR=LOCAL_MINOR
set /a REMOTE_MAJOR=REMOTE_MAJOR
set /a REMOTE_MINOR=REMOTE_MINOR

if !REMOTE_MAJOR! LSS !LOCAL_MAJOR! (
    echo %YELLOW%Installed version is newer than the latest release.%RESET%
    echo %YELLOW%No downgrade will be performed.%RESET%
    rmdir /s /q "%TEMP_DIR%"
    goto done
)

if !REMOTE_MAJOR! EQU !LOCAL_MAJOR! (
    if !REMOTE_MINOR! LSS !LOCAL_MINOR! (
        echo %YELLOW%Installed version is newer than the latest release.%RESET%
        echo %YELLOW%No downgrade will be performed.%RESET%
        rmdir /s /q "%TEMP_DIR%"
        goto done
    )

    if !REMOTE_MINOR! EQU !LOCAL_MINOR! (
        echo %GREEN%You already have the latest version.%RESET%
        rmdir /s /q "%TEMP_DIR%"
        goto done
    )
)


:download_update

echo %CYAN%Downloading update...%RESET%

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; try { $h=@{'User-Agent'='Rust-Server-Tutorial-Updater'}; Invoke-WebRequest -Uri '%ASSET_URL%' -Headers $h -OutFile '%TEMP_DIR%\update.zip' } catch { Write-Host ('ERROR: ' + $_.Exception.Message); exit 1 }"

if errorlevel 1 goto failed

if not exist "%TEMP_DIR%\update.zip" goto failed


echo %CYAN%Extracting update...%RESET%

mkdir "%TEMP_DIR%\extracted"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; try { Expand-Archive -Path '%TEMP_DIR%\update.zip' -DestinationPath '%TEMP_DIR%\extracted' -Force } catch { Write-Host ('ERROR: ' + $_.Exception.Message); exit 1 }"

if errorlevel 1 goto failed


rem ------------------------------------------------------------
rem Find the actual package root. Releases normally contain the
rem package files directly, but a single wrapper folder is allowed.
rem ------------------------------------------------------------

set "PACKAGE_ROOT=%TEMP_DIR%\extracted"

if exist "%TEMP_DIR%\extracted\setup.bat" goto root_found

for /f "delims=" %%D in ('dir /b /ad "%TEMP_DIR%\extracted" 2^>nul') do (
    if exist "%TEMP_DIR%\extracted\%%D\setup.bat" set "PACKAGE_ROOT=%TEMP_DIR%\extracted\%%D"
)

:root_found

if not exist "%PACKAGE_ROOT%\setup.bat" (
    goto failed
)


rem ------------------------------------------------------------
rem Only these project files are updated by this updater.
rem server_files and rust_server are NEVER copied here.
rem ------------------------------------------------------------

echo.
echo %CYAN%Updating package files...%RESET%
echo.

copy /y "%PACKAGE_ROOT%\setup.bat" "%~dp0setup.bat" >nul

if errorlevel 1 goto failed

copy /y "%PACKAGE_ROOT%\README.txt" "%~dp0README.txt" >nul

if errorlevel 1 goto failed

if exist "%PACKAGE_ROOT%\guide" (
    robocopy "%PACKAGE_ROOT%\guide" "%~dp0guide" /E /NFL /NDL /NJH /NJS /NP >nul
    if errorlevel 8 goto failed
)


rem ------------------------------------------------------------
rem setup_updater.bat itself must be replaced last.
rem ------------------------------------------------------------

copy /y "%PACKAGE_ROOT%\setup_updater.bat" "%TEMP_DIR%\setup_updater.new.bat" >nul

if errorlevel 1 goto failed


rem ------------------------------------------------------------
rem Temporary helper to replace the updater after this process
rem finishes.
rem ------------------------------------------------------------

>"%TEMP_DIR%\apply_update.bat" echo @echo off
>>"%TEMP_DIR%\apply_update.bat" echo timeout /t 2 /nobreak ^>nul
>>"%TEMP_DIR%\apply_update.bat" echo copy /y "%TEMP_DIR%\setup_updater.new.bat" "%ROOT_DIR%setup_updater.bat" ^>nul
>>"%TEMP_DIR%\apply_update.bat" echo if errorlevel 1 echo WARNING: Could not replace setup_updater.bat
>>"%TEMP_DIR%\apply_update.bat" echo echo %REMOTE_VERSION%^>"%ROOT_DIR%.version"
>>"%TEMP_DIR%\apply_update.bat" echo rmdir /s /q "%TEMP_DIR%"
>>"%TEMP_DIR%\apply_update.bat" echo exit /b

start "" /min cmd /c call "%TEMP_DIR%\apply_update.bat"


echo.
echo %GREEN%Update downloaded successfully.%RESET%
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

goto done


:failed

echo.
echo %RED%ERROR: The update could not be completed.%RESET%
echo.
echo %YELLOW%Your existing server files were not copied or replaced by this updater.%RESET%
echo.

if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"

pause
exit /b 1


:done

endlocal
pause
exit /b 0