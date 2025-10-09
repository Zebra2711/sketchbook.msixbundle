@echo OFF
setlocal enabledelayedexpansion enableextensions

:: Configuration variables
set "VERSION=9.3.21.0"
set "_VERSION=2025.924.1427.0"
set "URL_SKETCHBOOK=https://github.com/Zebra2711/sketchbook.msixbundle/releases/download/v%VERSION%/Sketchbook.SketchbookPro_%_VERSION%_neutral_k9x4nk31cvt0g.Msixbundle"
set "URL_RUNASTI=https://github.com/fafalone/RunAsTrustedInstaller/releases/download/v2.3.2"
set "SKB_msixbundle=Sketchbook.SketchbookPro_%VERSION%_neutral_k9x4nk31cvt0g.msixbundle"
set "RUNAS_TI_DIR=C:\Program Files\RunAsTI"
set "MD5=b65c500789394c01093069e9f6cfd57f"
set "SHA1=a664c7a3cc9bbd206ef0b841b73d6e8ded1f7b52"
set "SHA256=79ab914262e56026d5060a3e3642585600d4c7ded4f79e87af0c0c945e02715a"
set "SHA512=58d50c9b80fe89069118e81807b7b45a07500d5a5569ee29fbddab8d6b4332e4d2b2084985cd13ff86a7d33ae8b16f6113b7543b112d89cfb950a34c79153172"

:: RunAsTI hash values
set "RUNASTI32_MD5=2a5153020e1a127f0e3177555f83971e"
set "RUNASTI32_SHA1=13eae3abd9bab969dcdddda2d79cea4ca5082826"
set "RUNASTI32_SHA256=61aeff126f3199fd7637a0bfa1fb65c703dae06f180d4eddb377cacd6593007c"
set "RUNASTI32_SHA512=d2770e74af6ecc651cbe90199ef8d7872adb2f6f3a9b2e9294b8fce9ed3043a5bd0fde7861c691ed550bd065bbe6d27fb3466c182339220a1ccf99be83ea10f5"

set "RUNASTI64_MD5=0e62fc7ceae46df907c0c5464de0edc6"
set "RUNASTI64_SHA1=d5540fe7961d00a40f20d3ba5aba176bea42b211"
set "RUNASTI64_SHA256=92a75d619744fc9559d50eac77537c89a829ff63de23162d6d63fca15ca947de"
set "RUNASTI64_SHA512=a0e88fe160e3f80c7e7f8218e91f017ae61d941e6f3d151a31ec35ccde23c364e8911a05af3e7e0d4336f4a83f9fca31863f440e946e902ccd87fec609417569"

:: Run as admin check
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo [INFO] Administrative privileges required for installation...
    echo [ACTION] Requesting elevation to administrator...
    powershell -NoP -NonI -EP Bypass -Command "Start-Process '%~dpnx0' -Verb RunAs" >nul 2>&1
    exit /b
)

:: Create RunAsTI directory if it doesn't exist
if not exist "%RUNAS_TI_DIR%" md "%RUNAS_TI_DIR%" 2>nul
cd /d "%RUNAS_TI_DIR%" 2>nul || (echo [ERROR] Failed to access directory '%RUNAS_TI_DIR%' & exit /b 1)

:: Check OS architecture
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set OS=32 || set OS=64
echo [INFO] Detected %OS%-bit Windows operating system

if "%OS%"=="32" (
    for %%H in (MD5 SHA1 SHA256 SHA512) do set "RUNASTI_%%H=!RUNASTI32_%%H!"
) else (
    for %%H in (MD5 SHA1 SHA256 SHA512) do set "RUNASTI_%%H=!RUNASTI64_%%H!"
)

set "MAX_ATTEMPTS=3"

:: =======================================================================================================================================
::                                                              MAIN FLOW
:: =======================================================================================================================================
echo.
echo [START] Beginning Sketchbook Pro %VERSION% installation process...
echo [INFO] Installation will proceed in several stages
echo.

::                 File Path                            Name          Download URL                        Hash Prefix    Display Name
:: ---------------------------------------------------------------------------------------------------------------------------------------
call :install_file "%RUNAS_TI_DIR%\RunAsTI%OS%.exe"     "RunAsTI"     "%URL_RUNASTI%/RunAsTI%OS%.exe"     "RUNASTI_"     "RunAsTI%OS%.exe"
call :install_file "%TEMP%\%SKB_msixbundle%"            "Sketchbook"  "%URL_SKETCHBOOK%"                  ""             "%SKB_msixbundle%"

call :create_symlinks
call :install_sketchbook
call :create_shortcut
goto :script_end

:: =======================================================================================================================================

:install_file
    if not exist "%~1" (
        set "ATTEMPT=0"
        echo [PROCESS] Initiating download of %~2 components...
        call :download_file "%~2" "%~3" "%~1"
        echo [VERIFY] Verifying file integrity for %~2...
        call :verify_hashes "%~1" "%~4"
    ) else (
        echo [CHECK] %~5 found in system...
        echo [VERIFY] Verifying existing file integrity...
        call :verify_hashes "%~1" "%~4"
    )
exit /b 0

:: Create system profile directory symlinks if it doesn't exist
:create_symlinks
echo.
echo [SETUP] ========================================
echo [SETUP] Creating necessary system profile links
echo [SETUP] ========================================
set "systemprofile=%SystemRoot%\system32\config\systemprofile"
for %%F in (Desktop Downloads Music Pictures Videos Documents) do (
    if not exist "%systemprofile%\%%F" (
        echo [CREATE] Setting up system profile link for %%F folder...
        mklink /J "%systemprofile%\%%F" "%userprofile%\%%F"
    ) else (
        echo [SKIP] System profile link for %%F already exists
    )
)
exit /b 0

:download_file
set /a ATTEMPT+=1
set "FILE_NAME=%~1"
set "URL=%~2"
set "OUTPUT_PATH=%~3"
echo [DOWNLOAD] Fetching %FILE_NAME%... (Attempt !ATTEMPT! of %MAX_ATTEMPTS%)
echo [INFO] Source: %URL%
echo [INFO] Destination: %OUTPUT_PATH%

powershell -NoP -NonI -EP Bypass -Command ^
    "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" ^
    "$url='%URL%';" ^
    "$output='%OUTPUT_PATH%';" ^
    "$wc=New-Object System.Net.WebClient;" ^
    "$wc.Headers.Add('User-Agent','Mozilla/5.0');" ^
    "$response=$wc.OpenRead($url);" ^
    "$total=[int]$wc.ResponseHeaders['Content-Length'];" ^
    "$stream=[System.IO.File]::Create($output);" ^
    "$buffer=New-Object byte[] 8192;" ^
    "$bytesRead=0;" ^
    "$read=$response.Read($buffer,0,$buffer.Length);" ^
    "$sw=[System.Diagnostics.Stopwatch]::StartNew();" ^
    "while($read -gt 0){" ^
        "$stream.Write($buffer,0,$read);" ^
        "$bytesRead+=$read;" ^
        "$elapsed=$sw.Elapsed.TotalSeconds;" ^
        "$speed=($bytesRead/1MB)/$elapsed;" ^
        "$percent=($bytesRead/$total)*100;" ^
        "Write-Progress -Activity 'Downloading %FILE_NAME%' -Status ('{0:N2}%% Complete - {1:N2} MB/s' -f $percent,$speed) -PercentComplete $percent;" ^
        "$read=$response.Read($buffer,0,$buffer.Length);" ^
    "}" ^
    "$stream.Close();" ^
    "$response.Close();" ^
    "if(Test-Path $output){exit 0}else{exit 1}"

if errorlevel 1 (
    if !ATTEMPT! geq %MAX_ATTEMPTS% (
        echo [ERROR] Download failed after %MAX_ATTEMPTS% attempts
        exit /b 1
    )
    echo [RETRY] Download attempt failed, retrying...
    goto :download_file
)
echo [SUCCESS] Download completed successfully
exit /b 0

:verify_hashes
set "FILE_PATH=%~1"
set "PREFIX=%~2"
echo [VERIFY] Performing integrity checks using multiple hash algorithms...
for %%A in (MD5 SHA1 SHA256 SHA512) do (
    call :verify_hash "%%A" "!%PREFIX%%%A!" "%FILE_PATH%" || exit /b 1
)
exit /b 0

:verify_hash
set "FAILED=0"
set "ALGO=%~1"
set "EXPECTED=%~2"
set "FILE_PATH=%~3"
for /f "skip=1 tokens=* delims=" %%a in ('certutil -hashfile "%FILE_PATH%" %ALGO%') do (
    set "HASH=%%a"
    if not "!HASH:~0,1!"==" " goto :check_hash
)
if /i "%FAILED%" == "0" (
    echo [SUCCESS] File integrity verified successfully using all hash algorithms
)

:check_hash
set "HASH=!HASH: =!"
if /i not "!HASH!"=="%EXPECTED%" (
    echo [WARNING] %ALGO% verification failed for %FILE_PATH%
    set "FAILED=1"
    echo [DETAIL] Expected: %EXPECTED%
    echo [DETAIL] Received: !HASH!
    echo [ACTION] Removing corrupted file...
    del /f /q "%FILE_PATH%" 2>nul
    echo [RETRY] Initiating file redownload...
    set "ATTEMPT=0"
    if "%PREFIX%"=="RUNASTI_" (
        set "URL=%URL_RUNASTI%/RunAsTI%OS%.exe"
        call :download_file "RunAsTI" "!URL!" "%FILE_PATH%"
    ) else (
        call :download_file "Sketchbook" "%URL_SKETCHBOOK%" "%FILE_PATH%"
    )
)
exit /b 0

:install_sketchbook
echo.
echo [INSTALL] ========================================
echo [INSTALL] Installing Sketchbook Pro %VERSION%
echo [INSTALL] ========================================
powershell -NoP -NonI -EP Bypass -Command "Add-AppxPackage -Path \"$env:TEMP\%SKB_msixbundle%\""
if %errorlevel% neq 0 (
    echo [ERROR] Installation failed with error code %errorlevel%
    echo [INFO] Please check system requirements and try again
    exit /b 1
)
echo [SUCCESS] Sketchbook Pro installation completed successfully
exit /b 0

:create_shortcut
echo.
echo [SETUP] Creating desktop shortcut for easy access...
set "APP_DIR=C:\Program Files\WindowsApps\Sketchbook.SketchbookPro_%VERSION%_x%OS%__k9x4nk31cvt0g\SketchBookPro"
set "SHORTCUT_NAME=Sketchbook Pro.lnk"

powershell -NoP -NonI -EP Bypass -Command ^
    "$s = (New-Object -COM WScript.Shell).CreateShortcut('%userprofile%\Desktop\%SHORTCUT_NAME%');" ^
    "$s.TargetPath = '%RUNAS_TI_DIR%\RunAsTI%OS%.exe';" ^
    "$s.IconLocation = '%APP_DIR%\SketchbookPro.exe';" ^
    "$s.Arguments = '\"%APP_DIR%\SketchbookPro.exe\"';" ^
    "$s.WorkingDirectory = '%APP_DIR%';" ^
    "$s.WindowStyle = 7;" ^
    "$s.Save();"

echo [SUCCESS] Desktop shortcut created successfully
exit /b 0

:script_end
echo.
echo [COMPLETE] ===========================
echo [COMPLETE]  Installation successful!
echo [COMPLETE] ===========================
endlocal
pause
exit /b 0
