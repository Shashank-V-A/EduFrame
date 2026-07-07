# Scripts

## Windows path fix

Flutter and Pub were installed under `C:\Users\SHASHANK V A\...` (spaces in the path). Native asset builds break on Windows when paths are not quoted.

Junctions (one-time setup):

```powershell
cmd /c mklink /J C:\flutter "C:\Users\SHASHANK V A\Downloads\flutter_windows_3.44.4-stable\flutter"
cmd /c mklink /J D:\pub-cache "C:\Users\SHASHANK V A\AppData\Local\Pub\Cache"
```

## Run on Android phone

Phone must be connected with **USB debugging** enabled. If you see `No supported devices connected`, your PC does not see the phone yet.

```powershell
.\scripts\run-android.ps1
```

### Phone not detected?

1. Use a **data USB cable** and unlock the phone.
2. Enable **Developer options** → **USB debugging**.
3. When prompted on the phone, tap **Allow** for this computer.
4. Verify:

```powershell
& "C:\Users\SHASHANK V A\AppData\Local\Android\sdk\platform-tools\adb.exe" devices
```

You should see a line like `10BF4H0H47000ZC    device`. If it says `unauthorized`, check the phone screen for the trust prompt.

Fresh install:

```powershell
.\scripts\run-android.ps1 --uninstall-first
```
