# Scripts

## Windows path fix

Flutter and Pub were installed under `C:\Users\SHASHANK V A\...` (spaces in the path). Native asset builds break on Windows when paths are not quoted.

Junctions (one-time setup):

```powershell
cmd /c mklink /J C:\flutter "C:\Users\SHASHANK V A\Downloads\flutter_windows_3.44.4-stable\flutter"
cmd /c mklink /J D:\pub-cache "C:\Users\SHASHANK V A\AppData\Local\Pub\Cache"
```

## Run on Android phone

```powershell
.\scripts\run-android.ps1
```

Fresh install:

```powershell
.\scripts\run-android.ps1 --uninstall-first
```
