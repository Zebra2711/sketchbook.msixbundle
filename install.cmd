@echo OFF

set "URL_SKETCHBOOK=https://github.com/Zebra2711/sketchbook.msixbundle/releases/download/v9.1.38.0/Sketchbook.SketchbookPro_9.1.38.0_neutral_._k9x4nk31cvt0g.Msixbundle"

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

:: Download and install Sketchbook
powershell -Command "$path = [System.IO.Path]::Combine($env:TEMP, 'Sketchbook.SketchbookPro_9.1.38.0_neutral_~_k9x4nk31cvt0g.msixbundle');Write-Host 'Installation Path: ' $path;if (-Not (Test-Path $path)){Write-Host 'Downloading Sketchbook...';(New-Object Net.WebClient).DownloadFile('%URL_SKETCHBOOK%', $path);pause;} else {Write-Host 'File already exists.';}if (-Not (Test-Path $path)){Write-Host 'Download failed!'} else{Write-Host 'Install...';Add-AppxPackage -Path $path}"

:: Fix warring when start app
if not exist "C:\Windows\System32\config\systemprofile\Desktop" mkdir "C:\Windows\System32\config\systemprofile\Desktop"

:: Create shortcut
:: For 64-bit (Default)
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%userprofile%\Desktop\Sketchbook Pro.lnk');$s.TargetPath='C:\Program Files\RunAsTI\RunAsTI64.exe';$s.IconLocation='C:\Program Files\WindowsApps\Sketchbook.SketchbookPro_9.1.38.0_x64__k9x4nk31cvt0g\SketchBookPro\SketchbookPro.exe';$s.Arguments='\"C:\Program Files\WindowsApps\Sketchbook.SketchbookPro_9.1.38.0_x64__k9x4nk31cvt0g\SketchBookPro\SketchbookPro.exe\"';$s.WorkingDirectory='C:\Program Files\WindowsApps\Sketchbook.SketchbookPro_9.1.38.0_x64__k9x4nk31cvt0g\SketchBookPro';$s.WindowStyle=7;$s.Save()"
:: For 32-bit
:: powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%userprofile%\Desktop\Sketchbook Pro.lnk');$s.TargetPath='C:\Program Files\RunAsTI\RunAsTI32.exe';$s.IconLocation='C:\Program Files\WindowsApps\Sketchbook.SketchbookPro_9.1.38.0_x32__k9x4nk31cvt0g\SketchBookPro\SketchbookPro.exe';$s.Arguments='\"C:\Program Files\WindowsApps\Sketchbook.SketchbookPro_9.1.38.0_x32__k9x4nk31cvt0g\SketchBookPro\SketchbookPro.exe\"';$s.WorkingDirectory='C:\Program Files\WindowsApps\Sketchbook.SketchbookPro_9.1.38.0_x32__k9x4nk31cvt0g\SketchBookPro';$s.WindowStyle=7;$s.Save()"

@pause
