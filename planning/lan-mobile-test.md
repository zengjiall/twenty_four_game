# LAN Mobile Test

Current LAN IPv4 observed on this machine:

```text
192.168.1.109
```

## Current Recommended Test Flow

Flutter 3.44 currently crashes `flutter analyze` from this repo's original
Chinese OneDrive path. For verification and LAN serving, use an ASCII temporary
copy:

```powershell
robocopy "C:\Users\zengj\OneDrive\文档\24\flutter_projects\twenty_four_game\twenty_four_game" "C:\tmp\twenty_four_game_inner_copy" /MIR /XD .git .dart_tool build docs .idea /XF flutter_*.log
cd C:\tmp\twenty_four_game_inner_copy
flutter pub get
flutter analyze
flutter test
flutter build web
```

Serve the built web app:

```powershell
node "C:\Users\zengj\OneDrive\文档\24\flutter_projects\twenty_four_game\twenty_four_game\tooling\serve-build-web.mjs" --root "C:\tmp\twenty_four_game_inner_copy\build\web" --host 0.0.0.0 --port 8080
```

Phone URL on the same Wi-Fi:

```text
http://192.168.1.109:8080/
```

## Flutter Web-Server Alternative

Run this from the inner mainline project root after Git and Flutter are
installed:

```powershell
cd "C:\Users\zengj\OneDrive\文档\24\flutter_projects\twenty_four_game\twenty_four_game"
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Or use the helper script:

```powershell
.\tooling\run-lan-web.ps1 -FlutterRoot "$env:USERPROFILE\develop\flutter" -Port 8080
```

Then open this URL on a phone connected to the same Wi-Fi:

```text
http://192.168.1.109:8080/
```

If Windows Firewall prompts, allow access on private networks.

## Current Blocker

This shell cannot find `flutter`, `dart`, or `git`, so the latest Flutter source
cannot be built or served from here yet.

## Static Build Alternative

Once Flutter is available, a static build can be generated and served locally:

```powershell
flutter build web
```

Then serve `build/web` with any local static server bound to `0.0.0.0`. Do not
serve `docs/` for current testing unless it has just been rebuilt, because
`docs/` is a generated publishing artifact and may be stale.
