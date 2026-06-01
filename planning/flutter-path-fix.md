# Fix Flutter And Dart PATH

The current shell could not find `flutter`, `dart`, or `git`.

Flutter includes the Dart SDK, so Dart normally appears automatically after
Flutter is installed and `flutter\bin` is on PATH. Git for Windows is also a
Flutter prerequisite on Windows.

## Recommended Install Location

Use a path without spaces or non-ASCII characters:

```text
C:\Users\zengj\develop\flutter
```

## Install Steps

1. Install Git for Windows.
2. Download the Windows Flutter SDK zip from the official Flutter install page.
3. Extract it so this file exists:

```text
C:\Users\zengj\develop\flutter\bin\flutter.bat
```

4. Add this to the User PATH:

```text
C:\Users\zengj\develop\flutter\bin
```

5. Close and reopen PowerShell, then validate:

```powershell
flutter --version
dart --version
git --version
flutter doctor
```

## Project Helper Scripts

If Flutter is installed somewhere else, pass its root path explicitly:

```powershell
.\tooling\use-flutter.ps1 -FlutterRoot C:\path\to\flutter
```

To launch this game on the local network for phone testing:

```powershell
.\tooling\run-lan-web.ps1 -FlutterRoot C:\path\to\flutter -Port 8080
```

When the server starts, open the printed `http://<LAN-IP>:8080/` URL on a phone
connected to the same Wi-Fi.
