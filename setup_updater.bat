@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "REPO=ctrl-bownes/server_rust_tutorial"
set "API=https://api.github.com/repos/%REPO%/releases/latest"
set "TEMP_DIR=%TEMP%\rust_server_package_update"
set "ROOT_DIR=%~dp0"

rem ------------------------------------------------------------
rem --check is used by start_server.bat.
rem   0 = no update / up to date
rem   1 = update available
rem   2 = check failed
rem ------------------------------------------------------------

if /I "%~1"=="--check" goto check

goto update

:check
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; try { $h=@{'User-Agent'='Rust-Server-Tutorial-Updater'}; $r=Invoke-RestMethod -Uri '%API%' -Headers $h; $remote=[string]$r.tag_name; if(-not $remote){exit 2}; $local=''; if(Test-Path '.version'){ $local=(Get-Content '.version' -Raw).Trim() }; Write-Host ('Current version: ' + ($(if($local){$local}else{'not found'}))); Write-Host ('Latest version:  ' + $remote); if($local -eq $remote){ exit 0 } else { exit 1 } } catch { Write-Host ('Update check failed: ' + $_.Exception.Message); exit 2 }"
exit /b %errorlevel%

:update

echo.
echo ======================================
echo       Rust Server Package Updater
echo ======================================
echo.

if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; try { $h=@{'User-Agent'='Rust-Server-Tutorial-Updater'}; $r=Invoke-RestMethod -Uri '%API%' -Headers $h; $remote=[string]$r.tag_name; if([string]::IsNullOrWhiteSpace($remote)){throw 'GitHub release has no tag.'}; $asset=$null; foreach($a in $r.assets){if($a.name -like 'simple-server-rust-*.zip'){$asset=$a;break}}; if($null -eq $asset){throw 'No simple-server-rust ZIP asset was found in the latest release.'}; Set-Content -Path '%TEMP_DIR%\remote_version.txt' -Value $remote -NoNewline; Set-Content -Path '%TEMP_DIR%\asset_url.txt' -Value $asset.browser_download_url -NoNewline; Write-Host ('Latest version: ' + $remote); Write-Host ('Asset: ' + $asset.name) } catch { Write-Host ('ERROR: ' + $_.Exception.Message); exit 1 }"
if errorlevel 1 goto failed


set /p "REMOTE_VERSION="<"%TEMP_DIR%\remote_version.txt"
set /p "ASSET_URL="<"%TEMP_DIR%\asset_url.txt"

set "LOCAL_VERSION="
if exist ".version" set /p "LOCAL_VERSION="<".version"

if defined LOCAL_VERSION (
    echo Installed version: %LOCAL_VERSION%
) else (
    echo Installed version: not found
)
echo Latest version:     %REMOTE_VERSION%
echo.

if /I "%LOCAL_VERSION%"=="%REMOTE_VERSION%" (
    echo You already have the latest version.
    rmdir /s /q "%TEMP_DIR%"
    goto done
)

echo Downloading update...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; try { $h=@{'User-Agent'='Rust-Server-Tutorial-Updater'}; Invoke-WebRequest -Uri '%ASSET_URL%' -Headers $h -OutFile '%TEMP_DIR%\update.zip' } catch { Write-Host ('ERROR: ' + $_.Exception.Message); exit 1 }"
if errorlevel 1 goto failed

if not exist "%TEMP_DIR%\update.zip" goto failed

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
    echo ERROR: setup.bat was not found in the release archive.
    goto failed
)

rem ------------------------------------------------------------
rem Only these project files are updated by this updater.
rem server_files and rust_server are NEVER copied here.
rem ------------------------------------------------------------

echo.
echo Updating package files...

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
rem The current process continues from this already-loaded script.
rem ------------------------------------------------------------

copy /y "%PACKAGE_ROOT%\setup_updater.bat" "%TEMP_DIR%\setup_updater.new.bat" >nul
if errorlevel 1 goto failed

rem Use a temporary helper after this script exits so this file can
rem safely replace the currently running setup_updater.bat.
>"%TEMP_DIR%\apply_update.bat" echo @echo off
>>"%TEMP_DIR%\apply_update.bat" echo timeout /t 2 /nobreak ^>nul
>>"%TEMP_DIR%\apply_update.bat" echo copy /y "%TEMP_DIR%\setup_updater.new.bat" "%ROOT_DIR%setup_updater.bat" ^>nul
>>"%TEMP_DIR%\apply_update.bat" echo if errorlevel 1 echo WARNING: Could not replace setup_updater.bat
>>"%TEMP_DIR%\apply_update.bat" echo echo %REMOTE_VERSION%^>"%ROOT_DIR%.version"
>>"%TEMP_DIR%\apply_update.bat" echo rmdir /s /q "%TEMP_DIR%"
>>"%TEMP_DIR%\apply_update.bat" echo exit /b

start "" /min cmd /c call "%TEMP_DIR%\apply_update.bat"

echo.
echo Update downloaded successfully.
echo.
echo Updated:
echo   - setup_updater.bat
echo   - setup.bat
echo   - README.txt
echo   - guide\*
echo.
echo Server files were NOT modified.
echo start_server.bat was NOT modified.
echo.
echo The updater will finish replacing itself after this window closes.

goto done

:failed
echo.
echo ERROR: The update could not be completed.
echo Your existing server files were not copied or replaced by this updater.
echo.
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
exit /b 1

:done
endlocal
exit /b 0
