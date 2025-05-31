# Script auto install, create shortcut sketchbook pro 
## How to use:
Download `install.cmd` and run

If you on low internet or close terminal when dowload not done yet, next time you use install will have install error. To fix that, `WIN+R` `%TEMP%` then delete Sketchbook.`SketchbookPro_<version>_neutral_k9x4nk31cvt0g.msixbundle`. OR go to github
Releases, download .msixbundle file and install manual (Fixed in new version 9.2.13 install script)

## You may also need to do this

<div align="center">
  <video src="https://github.com/user-attachments/assets/fbdf050b-7d04-4504-abfb-499b97fd4829" alt="show all folders"></video>
</div>

## Sync theme system for explorer window

Sketchbook runs in `%systemprofile%`, not `%userprofile%`
Therefore, when opening file explorer via skeetchbook to open, save, etc. It will open explorer with "light theme"
if You want sync theme with your system 
* Run `SyncTheme.bat` to auto sync theme
* Manualy:
    + Export the key `HKCU\Software\Microsoft\Windows\CurrentVersion\Themes` from the registry
    + Used notepad to open the exported `.reg` file and replace string `HKEY_CURRENT_USER` with `HKEY_USERS\\S-1-5-18`. Save the changes.
    + Import the saved `.reg` file. Done.

## TODO

- [ ] Fix error when opening file directly from text menu to edit with Sketchbook.
