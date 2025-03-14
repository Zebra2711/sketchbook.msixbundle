@echo OFF
setlocal enabledelayedexpansion

:: Configuration variables
set "VERSION=9.2.13.0"
set "_VERSION=2025.303.1551.0"
set "URL_SKETCHBOOK=https://github.com/Zebra2711/sketchbook.msixbundle/releases/download/v%VERSION%/Sketchbook.SketchbookPro_%_VERSION%_neutral_k9x4nk31cvt0g.Msixbundle"
set "SKB_msixbundle=Sketchbook.SketchbookPro_%VERSION%_neutral_k9x4nk31cvt0g.msixbundle"
set "RUNAS_TI_DIR=C:\Program Files\RunAsTI"
set "MD5=d122d86727738277bb37e48abfa6d354"
set "SHA1=dd76308ddf4868da9bd2e8ad5e3fdd8e3a8aca63"
set "SHA256=ab955a05d47f1123b5482174a41f426215268e92a3fb2bd1b33ce02342614aa9"
set "SHA512=1cedb4e32946c9ca1c544a13c7c547dd9b6b961d07d0b40bcf0ba2f0f4ab695eb83bdfa84cb1281386d50b426d8741486adc4437c6da777b7f35931bd9ad2772"

:: Run as admin
@if not defined USER for /f "tokens=2" %%s in ('whoami /user /fo list') do set "USER=%%s">nul
@set "_=set USER=%USER%&&call "%~f0" %*"&reg query HKU\S-1-5-19>nul 2>nul||(
@powershell -nop -c "start -verb RunAs cmd -args '/d/x/q/r',$env:_"&exit)

:: Create RunAsTI directory if it doesn't exist
if not exist "%RUNAS_TI_DIR%" mkdir "%RUNAS_TI_DIR%"
cd "%RUNAS_TI_DIR%"

:: Check OS architecture
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set OS=32 || set OS=64

:: Download RunAsTI if not already downloaded
if not exist "%RUNAS_TI_DIR%\RunAsTI%OS%.exe" (
    echo File not found. Preparing to download RunAsTI%OS%.exe...
    powershell -Command ^
        "$url = 'https://github.com/fafalone/RunAsTrustedInstaller/releases/download/v2.3.1/RunAsTI%OS%.exe';" ^
        "$output = 'RunAsTI%OS%.exe';" ^
        "$webclient = New-Object System.Net.WebClient;" ^
        "$response = $webclient.OpenRead($url);" ^
        "$totalLength = [int]$webclient.ResponseHeaders['Content-Length'];" ^
        "$stream = [System.IO.File]::Create($output);" ^
        "$buffer = New-Object byte[] 1024;" ^
        "$read = $response.Read($buffer, 0, $buffer.Length);" ^
        "$bytesRead = 0;" ^
        "while ($read -gt 0) {" ^
            "$stream.Write($buffer, 0, $read);" ^
            "$bytesRead += $read;" ^
            "$percentComplete = ($bytesRead / $totalLength) * 100;" ^
            "Write-Progress -Activity 'Downloading RunAsTI' -Status ('{0:N2}%% Complete' -f $percentComplete) -PercentComplete $percentComplete;" ^
            "$read = $response.Read($buffer, 0, $buffer.Length);" ^
        "}" ^
        "$stream.Close();" ^
        "$response.Close();" ^
        "echo 'Download completed successfully!';"
) else (
    echo File already exists in the directory: %RUNAS_TI_DIR%.
)



:: Check if Sketchbook needs to be downloaded
if not exist "%TEMP%\%SKB_msixbundle%" (
    call :download_sketchbook
) else (
    echo Sketchbook file found. Verifying...
    call :verify_hashes
)

:: Create system profile directory if it doesn't exist
:: Define the subfolders to create
set "systemprofile=C:\Windows\System32\config\systemprofile"
for %%F in (Desktop Download Music Picture Video Document) do (
    if not exist "%systemprofile%\%%F" (
        mklink /J "%systemprofile%\%%F" "%userprofile%\%%F"
        echo Created symlink for %%F
    ) else (
        echo Symlink for %%F already exists. Skipping creation
    )
)

:: Install and create shortcut
call :install_sketchbook
call :create_shortcut
goto :script_end


set MAX_ATTEMPTS=3
set ATTEMPT=0

:download_sketchbook

set /a ATTEMPT+=1
echo Downloading Sketchbook to %TEMP%\%SKB_msixbundle%...
powershell -Command ^
    "$url = '%URL_SKETCHBOOK%';" ^
    "$output = [System.IO.Path]::Combine($env:TEMP, '%SKB_msixbundle%');" ^
    "Write-Host 'Installation Path:' $output;" ^
    "$webclient = New-Object System.Net.WebClient;" ^
    "$response = $webclient.OpenRead($url);" ^
    "$totalLength = [int]$webclient.ResponseHeaders['Content-Length'];" ^
    "$stream = [System.IO.File]::Create($output);" ^
    "$buffer = New-Object byte[] 8192;" ^
    "$bytesRead = 0;" ^
    "$read = $response.Read($buffer, 0, $buffer.Length);" ^
    "$stopwatch = [System.Diagnostics.Stopwatch]::StartNew();" ^
    "while ($read -gt 0) {" ^
        "$stream.Write($buffer, 0, $read);" ^
        "$bytesRead += $read;" ^
        "$elapsedSeconds = $stopwatch.Elapsed.TotalSeconds;" ^
        "$speedMBps = ($bytesRead / 1024 / 1024) / $elapsedSeconds;" ^
        "$percentComplete = ($bytesRead / $totalLength) * 100;" ^
        "Write-Progress -Activity 'Downloading Sketchbook' -Status ('{0:N2}%% Complete - Speed: {1:N2} MB/s' -f $percentComplete, $speedMBps) -PercentComplete $percentComplete;" ^
        "$read = $response.Read($buffer, 0, $buffer.Length);" ^
    "}" ^
    "$stream.Close();" ^
    "$response.Close();" ^
    "if (-Not (Test-Path $output)) {" ^
        "Write-Host 'Download failed!';" ^
    "} else {" ^
        "Write-Host 'File downloaded successfully.';" ^
    "}"



if errorlevel 1 (
    echo Download failed.
    if !ATTEMPT! geq %MAX_ATTEMPTS% (
        echo Maximum attempts reached. Exiting...
        exit /b 1
    )
    echo Try agsin
    goto :download_sketchbook
)

echo Download completed successfully!

call :verify_hashes
exit /b

:verify_hashes
echo Verifying file hashes...
set "HASH_CHECK=1"

call :verify_hash MD5 "%MD5%"
call :verify_hash SHA1 "%SHA1%"
call :verify_hash SHA256 "%SHA256%"
call :verify_hash SHA512 "%SHA512%"

if /i not "%HASH_CHECK%" == "0" (
    echo File passed all hash verifications.
)
exit /b

:verify_hash
set "ALGO=%~1"
set "EXPECTED=%~2"
echo Checking %ALGO% hash...
for /f "skip=1 tokens=* delims=" %%a in ('certutil -hashfile "%TEMP%\%SKB_msixbundle%" %ALGO%') do (
    set "line=%%a"
    if not "!line:~0,1!"==" " (
        set "HASH=!line!"
        goto :compare_hash
    )
)

:compare_hash
set "HASH=!HASH: =!"
if /i not "!HASH!" == "%EXPECTED%" (
    echo %ALGO% hash verification failed.
    echo Expected: %EXPECTED%
    echo Got: !HASH!
    set "HASH_CHECK=0"
    echo Redownloading file...
    del /f /q "%TEMP%\%SKB_msixbundle%" 2>nul
    call :download_sketchbook
)
exit /b

:install_sketchbook
echo Installing Sketchbook...
powershell -Command "Add-AppxPackage -Path \"$env:TEMP\%SKB_msixbundle%\""
if %errorlevel% neq 0 (
    echo Installation failed with error code %errorlevel%
    exit /b 1
)
echo Installation completed successfully.
exit /b

:create_shortcut
echo Creating desktop shortcut...
set "APP_DIR=C:\Program Files\WindowsApps\Sketchbook.SketchbookPro_%VERSION%_x%OS%__k9x4nk31cvt0g\SketchBookPro"
set "SHORTCUT_NAME=Sketchbook Pro.lnk"

powershell -Command ^
  "$s = (New-Object -COM WScript.Shell).CreateShortcut('%userprofile%\Desktop\%SHORTCUT_NAME%');" ^
  "$s.TargetPath = '%RUNAS_TI_DIR%\RunAsTI%OS%.exe';" ^
  "$s.IconLocation = '%APP_DIR%\SketchbookPro.exe';" ^
  "$s.Arguments = '\"%APP_DIR%\SketchbookPro.exe\"';" ^
  "$s.WorkingDirectory = '%APP_DIR%';" ^
  "$s.WindowStyle = 7;" ^
  "$s.Save();"

echo Shortcut created successfully.
exit /b

:script_end
echo Installation complete!
pause
exit /b 0