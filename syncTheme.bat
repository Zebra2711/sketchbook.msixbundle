@echo off
setlocal

set THEME=%TEMP%\system_themes.reg
set THEME_BK=%TEMP%\TIBK.reg
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes" "%THEME_BK%" /y
:: Export system theme
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes" "%THEME%" /y
if errorlevel 1 (
    echo Failed to export system theme.
    exit /b 1
)

:: Replace HKCU with HKEY_USERS\S-1-5-18 using PowerShell
powershell -Command ^
    "$f = Get-Content -Raw '%THEME%';" ^
    "$f = $f -replace 'HKEY_CURRENT_USER', 'HKEY_USERS\\S-1-5-18';" ^
    "Set-Content -Encoding ASCII '%THEME%' -Value $f"

:: Import the modified reg file
reg import "%THEME%"
if errorlevel 1 (
    echo Failed to import modified registry key.
    del "%THEME%"
    exit /b 1
)

:: Cleanup temp files
del "%THEME_FILE%"

endlocal
pause

