---
name: ios-ui-verification
description: Verifies iOS UI claims with Maestro real taps on the simulator and treats xcodebuild as the only build authority (SourceKit false-positives); load before claiming any iOS screen, flow, or build works.
license: Proprietary
---

# iOS UI verification

Binding rule (railway): **"UI claims verified hands-on: Maestro real taps for iOS"** and **"`xcodebuild` (iOS Simulator) green is authoritative — trust xcodebuild, never SourceKit single-file diagnostics."**

## Build authority

1. Only `xcodebuild` against the iOS Simulator decides whether the code builds. SourceKit single-file diagnostics "false-positive against the macOS SDK: phantom 'unavailable in macOS' / missing module-sibling members" — ignore them entirely as a pass/fail signal.
2. After interrupted multi-agent runs, "don't trust the post-run editor diagnostics wall" — revert only the half-written files and re-run `xcodebuild`.

## Driving the simulator (Maestro)

3. Use **Maestro 1.38**: `brew install mobile-dev-inc/tap/maestro@1.38` (binary at `/opt/homebrew/opt/maestro@1.38/bin`). The plain formula is broken ("Expected to find class Maestro@head"), the `curl | bash` installer gets permission-denied, and `brew install maestro` (cask) installs an unrelated GUI app.
4. Export **both** env vars or Maestro hangs silently:
   ```sh
   JAVA_HOME=/opt/homebrew/opt/openjdk DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer maestro test flow.yaml
   ```
   Missing `DEVELOPER_DIR` shows "Xcode Version: null" in `~/.maestro/tests/*/maestro.log`.
5. Do not reach for alternatives that can't work here: `simctl` has no tap/keyboard commands; `cliclick`/AppleScript need macOS accessibility permission not granted to agent shells (CGEvents are silently dropped); `idb` is gone from brew.
6. First run installs an XCTest driver into the sim — allow a couple of minutes.

## Flow-writing gotchas

7. `tapOn` text matching hits the search field's own typed text before result rows — target unambiguous row copy ("New Delhi to Varanasi"), not a regex that matches the query.
8. The iOS bilingual keyboard tutorial steals the first tap after focusing a text field — insert `tapOn: {text: Continue, optional: true}`.
9. With the keyboard up the tab bar is unreachable — dismiss the keyboard first.
10. A button at the bottom edge sits under the floating tab bar — "scroll one extra swipe before tapping"; relaunches drop launch args, so re-pass them.
11. Railly snapshot hooks: launch args `-railly.tab N`, `-railly.detail <trainNo>`, `-railly.onrails 1` (UserDefaults argument domain, volatile).

## Screenshots

12. `xcrun simctl io "iPhone 17 Pro" screenshot out.png`; `sips -Z 650` to view. `sips --cropOffset` is unreliable (center-crops) — don't trust it for region crops.

## Hard stops

- Never cite SourceKit/editor diagnostics as build truth — only xcodebuild.
- Never claim an iOS flow works without real taps having exercised it.
- Never verify against fabricated screenshots or described-from-code UI.
