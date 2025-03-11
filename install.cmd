@echo OFF
setlocal enabledelayedexpansion

set "URL_SKETCHBOOK=https://github.com/Zebra2711/sketchbook.msixbundle/releases/download/v9.2.13/Sketchbook.SketchbookPro_2025.303.1551.0_neutral_k9x4nk31cvt0g.Msixbundle"

:: Run as admin
@if not defined USER for /f "tokens=2" %%s in ('whoami /user /fo list') do set "USER=%%s">nul
@set "_=set USER=%USER%&&call "%~f0" %*"&reg query HKU\S-1-5-19>nul 2>nul||(
@powershell -nop -c "start -verb RunAs cmd -args '/d/x/q/r',$env:_"&exit)

if not exist "C:\Program Files\RunAsTI" mkdir "C:\Program Files\RunAsTI"

cd "C:\Program Files\RunAsTI"

:: Check OS
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set OS=32 || set OS=64

:: Download RunAsTI
if not exist "C:\Program Files\RunAsTI\RunAsTI%OS%.exe" powershell -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/fafalone/RunAsTrustedInstaller/releases/download/v2.3.1/RunAsTI%OS%.exe', 'RunAsTI%OS%.exe')"

:: File download
set "SKB_msixbundle=Sketchbook.SketchbookPro_9.2.13.0_neutral_k9x4nk31cvt0g.msixbundle"

set "MD5=d122d86727738277bb37e48abfa6d354"
set "SHA1=dd76308ddf4868da9bd2e8ad5e3fdd8e3a8aca63"
set "SHA256=ab955a05d47f1123b5482174a41f426215268e92a3fb2bd1b33ce02342614aa9"
set "SHA512=1cedb4e32946c9ca1c544a13c7c547dd9b6b961d07d0b40bcf0ba2f0f4ab695eb83bdfa84cb1281386d50b426d8741486adc4437c6da777b7f35931bd9ad2772"

set "HASH_CHECK=1"

if not exist "%TEMP%\%SKB_msixbundle%" (
    goto :download
) else (
    goto :hash_check
)

:: Download and install Sketchbook
:download
powershell -Command "$path = [System.IO.Path]::Combine($env:TEMP, '%SKB_msixbundle%'); Write-Host 'Installation Path: ' $path; if (-Not (Test-Path $path)) { Write-Host 'Downloading Sketchbook...'; (New-Object Net.WebClient).DownloadFile('%URL_SKETCHBOOK%', $path); } else { Write-Host 'File already exists.'; } if (-Not (Test-Path $path)) { Write-Host 'Download failed!' } else { Write-Host 'File downloaded successfully.'; }"
pause
goto :hash_check

:hash_check
echo Verifying file hashes...
call :verify_hash MD5 "%MD5%"
call :verify_hash SHA1 "%SHA1%"
call :verify_hash SHA256 "%SHA256%"
call :verify_hash SHA512 "%SHA512%"
goto :end_checks

:verify_hash
set "ALGO=%~1"
set "EXPECTED=%~2"
echo Checking %ALGO% hash...
for /f "skip=1 tokens=* delims=" %%a in ('certutil -hashfile "%TEMP%\%SKB_msixbundle%" %ALGO%') do (
    set "line=%%a"
    if not "!line:~0,1!"==" " (
        set "HASH=!line!"
        goto :hash_compare
    )
)

:hash_compare
set "HASH=!HASH: =!"
if /i not "!HASH!" == "%EXPECTED%" (
    echo %ALGO% hash verification failed.
    echo Expected: %EXPECTED%
    echo Got: !HASH!
    set "HASH_CHECK=0"
)
exit /b

:end_checks
if "%HASH_CHECK%" == "0" (
    echo Hash verification failed. Redownloading file...
    del /f /q "%TEMP%\%SKB_msixbundle%" 2>nul
    goto :download
) else (
    echo File passed all hash verifications.
    goto :install
)

:install
echo Installing Sketchbook...
powershell -Command "Add-AppxPackage -Path \"$env:TEMP\%SKB_msixbundle%\""

:: Fix warning when starting app
if not exist "C:\Windows\System32\config\systemprofile\Desktop" mkdir "C:\Windows\System32\config\systemprofile\Desktop"

:: Create shortcut
:: For 64-bit
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%userprofile%\Desktop\Sketchbook Pro 64Bit.lnk');$s.TargetPath='C:\Program Files\RunAsTI\RunAsTI64.exe';$s.IconLocation='C:\Program Files\WindowsApps\Sketchbook.SketchbookPro_9.2.13.0_x64__k9x4nk31cvt0g\SketchBookPro\SketchbookPro.exe';$s.Arguments='\"C:\Program Files\WindowsApps\Sketchbook.SketchbookPro_9.2.13.0_x64__k9x4nk31cvt0g\SketchBookPro\SketchbookPro.exe\"';$s.WorkingDirectory='C:\Program Files\WindowsApps\Sketchbook.SketchbookPro_9.2.13.0_x64__k9x4nk31cvt0g\SketchBookPro';$s.WindowStyle=7;$s.Save()"
:: For 32-bit
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%userprofile%\Desktop\Sketchbook Pro 32Bit.lnk');$s.TargetPath='C:\Program Files\RunAsTI\RunAsTI32.exe';$s.IconLocation='C:\Program Files\WindowsApps\Sketchbook.SketchbookPro_9.2.13.0_x32__k9x4nk31cvt0g\SketchBookPro\SketchbookPro.exe';$s.Arguments='\"C:\Program Files\WindowsApps\Sketchbook.SketchbookPro_9.2.13.0_x32__k9x4nk31cvt0g\SketchBookPro\SketchbookPro.exe\"';$s.WorkingDirectory='C:\Program Files\WindowsApps\Sketchbook.SketchbookPro_9.2.13.0_x32__k9x4nk31cvt0g\SketchBookPro';$s.WindowStyle=7;$s.Save()"
:: Remove inappropriate shortcut based on OS architecture
if %OS%==64 (
    del /f /q "%userprofile%\Desktop\Sketchbook Pro 32Bit.lnk"
) else (
    del /f /q "%userprofile%\Desktop\Sketchbook Pro 64Bit.lnk"
)
echo Installation complete!
@pause