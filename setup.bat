@echo off

if not exist "steamcmd\steamcmd.exe" (
    echo SteamCMD not found.
    echo Downloading SteamCMD...

    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://client-update.steamstatic.com/installer/steamcmd.zip' -OutFile 'steamcmd.zip'"

    echo Extracting SteamCMD...

    powershell -NoProfile -Command "New-Item -ItemType Directory -Force -Path 'steamcmd' | Out-Null; Expand-Archive -Path 'steamcmd.zip' -DestinationPath 'steamcmd' -Force"

    del "steamcmd.zip"

    echo SteamCMD installed.
)

cd steamcmd

rem NOTE: a digit directly before ">" is read as a handle number (1> = stdout), so keep a space before ">".
echo @ShutdownOnFailedCommand 1 > rust_install.txt
echo @NoPromptForPassword 1 >> rust_install.txt
echo @sSteamCmdForcePlatformType windows>> rust_install.txt
echo force_install_dir ../rust_server/server_files>> rust_install.txt
echo login anonymous>> rust_install.txt
echo app_update 258550 -beta public>> rust_install.txt
echo quit>> rust_install.txt

steamcmd +runscript rust_install.txt

cd ../rust_server/

echo :: Double colons are used to add comments in a batch file.> start_server.bat
echo :: Anything on a line starting with :: is ignored when the batch file runs.>> start_server.bat
echo.>> start_server.bat
echo :: You can use comments to disable commands you don't want to execute.>> start_server.bat
echo :: This lets you keep the commands in the file in case you want to use them later.>> start_server.bat
echo.>> start_server.bat
echo :: For example, uncomment the 4 lines below if you want your server>> start_server.bat
echo :: to automatically update when you run your start_server.bat script.>> start_server.bat
echo.>> start_server.bat
echo :: force_install_dir ../rust_server/server_files>> start_server.bat
echo :: login anonymous>> start_server.bat
echo :: app_update 258550 -beta public>> start_server.bat
echo :: quit>> start_server.bat
echo.>> start_server.bat
echo.>> start_server.bat
echo @echo off>> start_server.bat
echo.>> start_server.bat
echo cd ./server_files/>> start_server.bat
echo.>> start_server.bat
echo RustDedicated.exe ^^>> start_server.bat
echo -batchmode ^^>> start_server.bat
echo +server.level "Procedural Map" ^^>> start_server.bat
echo +server.seed 2147483647 ^^>> start_server.bat
echo +server.worldsize 1000 ^^>> start_server.bat
echo +server.maxplayers 10>> start_server.bat


echo @echo off> update_oxide.bat
echo setlocal>> update_oxide.bat
echo echo ==============================>> update_oxide.bat
echo echo        Oxide Updater>> update_oxide.bat
echo echo ==============================>> update_oxide.bat
echo echo.>> update_oxide.bat

echo echo Downloading Oxide...>> update_oxide.bat
echo if exist oxide.zip del /F /Q oxide.zip>> update_oxide.bat
echo if exist oxide_temp rmdir /S /Q oxide_temp>> update_oxide.bat
echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://umod.org/games/rust/download?tag=public' -OutFile 'oxide.zip'">> update_oxide.bat
echo if not exist oxide.zip ^(echo ERROR: Oxide download failed.^& pause^& exit /b 1^)>> update_oxide.bat
echo echo.>> update_oxide.bat

echo echo Extracting Oxide...>> update_oxide.bat
echo powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path 'oxide.zip' -DestinationPath 'oxide_temp' -Force">> update_oxide.bat
echo if not exist oxide_temp ^(echo ERROR: Oxide extraction failed.^& pause^& exit /b 1^)>> update_oxide.bat
echo echo.>> update_oxide.bat

echo echo Removing old Oxide files...>> update_oxide.bat
echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$root=(Resolve-Path 'server_files').Path; $source=(Resolve-Path 'oxide_temp').Path; Get-ChildItem 'oxide_temp' -Recurse -File | ForEach-Object { $relative=$_.FullName.Substring($source.Length).TrimStart('\'); $target=Join-Path $root $relative; if(Test-Path $target) { Remove-Item $target -Force -ErrorAction Stop } }">> update_oxide.bat
echo if errorlevel 1 ^(echo ERROR: Could not remove old Oxide files.^& pause^& exit /b 1^)>> update_oxide.bat
echo echo.>> update_oxide.bat

echo echo Copying NEW Oxide files...>> update_oxide.bat
echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Copy-Item -Path 'oxide_temp\*' -Destination 'server_files' -Recurse -Force">> update_oxide.bat
echo if errorlevel 1 ^(echo ERROR: Oxide copy failed.^& pause^& exit /b 1^)>> update_oxide.bat
echo echo.>> update_oxide.bat

echo echo Verifying Oxide files...>> update_oxide.bat
echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$files=Get-ChildItem 'oxide_temp' -Recurse -File; $missing=0; foreach($f in $files) { $relative=$f.FullName.Substring((Resolve-Path 'oxide_temp').Path.Length).TrimStart('\'); $target=Join-Path (Resolve-Path 'server_files').Path $relative; if(-not (Test-Path $target)) { Write-Host ('MISSING: ' + $relative); $missing++ } }; if($missing -gt 0) { exit 1 } else { Write-Host 'All Oxide files copied successfully.' }">> update_oxide.bat
echo if errorlevel 1 ^(echo ERROR: Some Oxide files are missing after the copy.^& pause^& exit /b 1^)>> update_oxide.bat
echo echo.>> update_oxide.bat

echo echo Cleaning up...>> update_oxide.bat
echo rmdir /S /Q oxide_temp>> update_oxide.bat
echo del /F /Q oxide.zip>> update_oxide.bat
echo echo.>> update_oxide.bat
echo echo Oxide update finished successfully.>> update_oxide.bat
echo endlocal>> update_oxide.bat
echo pause>> update_oxide.bat


echo @echo off> select_version.bat
echo cd ../steamcmd/>> select_version.bat
echo :menu>> select_version.bat
echo cls>> select_version.bat
echo echo ==============================>> select_version.bat
echo echo       Rust Server Installer>> select_version.bat
echo echo ==============================>> select_version.bat
echo echo.>> select_version.bat
echo echo [1] Main>> select_version.bat
echo echo [2] Staging (Might not work with Oxide)>> select_version.bat
echo echo [3] Public Beta (Might not work with Oxide)>> select_version.bat
echo echo [4] Private Beta (Might not work with Oxide)>> select_version.bat
echo echo [5] Exit>> select_version.bat
echo echo.>> select_version.bat
echo choice /c 12345 /n /m "Choose a version: ">> select_version.bat
echo.>> select_version.bat

echo if %%errorlevel%%==1 goto main>> select_version.bat
echo if %%errorlevel%%==2 goto staging>> select_version.bat
echo if %%errorlevel%%==3 goto publicbeta>> select_version.bat
echo if %%errorlevel%%==4 goto privatebeta>> select_version.bat
echo if %%errorlevel%%==5 exit>> select_version.bat
echo.>> select_version.bat

echo :main>> select_version.bat
echo echo Installing Main...>> select_version.bat
echo steamcmd +force_install_dir "../rust_server/server_files" +login anonymous +app_update 258550 -beta public validate +quit>> select_version.bat
echo goto end>> select_version.bat
echo.>> select_version.bat

echo :staging>> select_version.bat
echo echo Installing Staging...>> select_version.bat
echo steamcmd +force_install_dir "../rust_server/server_files" +login anonymous +app_update 258550 -beta staging validate +quit>> select_version.bat
echo goto end>> select_version.bat
echo.>> select_version.bat

echo :publicbeta>> select_version.bat
echo echo Installing Public Beta...>> select_version.bat
echo set /p "BETA_NAME=Enter beta branch name: ">> select_version.bat
echo steamcmd +force_install_dir "../rust_server/server_files" +login anonymous +app_update 258550 -beta %%BETA_NAME%% validate +quit>> select_version.bat
echo goto end>> select_version.bat
echo.>> select_version.bat

echo :privatebeta>> select_version.bat
echo echo Installing Private Beta...>> select_version.bat
echo set /p "BETA_NAME=Enter beta branch name: ">> select_version.bat
echo set /p "BETA_KEY=Enter beta password: ">> select_version.bat
echo steamcmd +force_install_dir "../rust_server/server_files" +login anonymous +app_update 258550 -beta %%BETA_NAME%% -betapassword %%BETA_KEY%% validate +quit>> select_version.bat
echo goto end>> select_version.bat
echo.>> select_version.bat

echo :end>> select_version.bat
echo pause>> select_version.bat
echo.
powershell -NoProfile -Command "$ws=New-Object -ComObject WScript.Shell; $sc=$ws.CreateShortcut('GUIDE.lnk'); $sc.TargetPath=(Resolve-Path '../guide/open_me.html').Path; $sc.Save()"
echo Setup finished!
pause