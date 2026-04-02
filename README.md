# Qt Installer Framework project (offline)

Builds the **KTS InfoMate Player** Windows installer from `Setup\Windows\Binaries`.

Optional **additional instance** (same as `InfoMateEnterprise.iss`): wizard page asks for an optional folder name; if set, the installed `default` tree is **copied** to `...\Infomate\<name>\` via `CopyDirectory`.

## Prerequisites

- Qt Installer Framework at `C:\Qt\QtIFW-4.1.1` (or set `QTIFW_ROOT` in `build-installer.ps1`)

## Build

From **this folder** (`Setup\Windows\qtInstaller`):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build-installer.ps1
```

From repo root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Setup\Windows\qtInstaller\build-installer.ps1
```

Output: `Setup\Windows\qtInstaller\output\InfomatePlayer.exe`
