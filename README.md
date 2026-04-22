# iOSBili

Native SwiftUI iOS rewrite of the Flutter-based third-party Bilibili client located at `D:\workspace\bilibili`.

This project lives at `D:\workspace\iOSbili` and focuses on the first usable native migration path rather than full feature parity on day one.

## What is already migrated

- Native SwiftUI app structure for iPhone and iPad
- Bilibili networking layer with WBI signing support
- Cookie import and shared login state for `URLSession` and `WKWebView`
- Home recommended feed and hot feed
- Search landing page, suggestions, hot keywords, recommended keywords, and video search
- Profile page with account info, stats, cookie import, and web login import
- Viewing history migration
- Watch later migration, including remove action
- Favorite folder list and favorite folder detail migration
- Video detail page with related videos
- Native player first pass:
  - direct play URL
  - DASH video/audio composition attempt
  - web playback fallback
  - quality metadata cards
  - lane-style danmaku overlay
  - playback controls with seek and speed
  - local playback progress save and resume

## Extra improvements added in this round

- Chinese UI localization was normalized into stable escaped strings to avoid source corruption
- Favorite folder detail now supports removing an item from the current folder
- Login migration supports both pasted cookies and embedded web login import
- Native player now exposes richer stream metadata and transport controls
- Profile and detail pages were further refined toward a more Bilibili-like hierarchy
- Video detail and native player now support local resume from saved progress
- Native player now includes fullscreen presentation and gesture-driven seek/brightness/volume controls

## Important limitation

This Windows environment does not contain Xcode, the Apple Swift toolchain, or XcodeGen runtime verification, so the project could not be compiled here. The source tree and `project.yml` were prepared for generation and build on macOS.

## Generate the Xcode project on macOS

1. Install `xcodegen`
2. Open the synced folder that contains `D:\workspace\iOSbili`
3. Run `xcodegen generate`
4. Open `IOSBili.xcodeproj` in Xcode
5. Update the bundle identifier and signing team if needed

## Login import

The app currently supports two native migration-friendly login flows:

- Paste the full browser cookie header
- Log in inside the embedded Bilibili web page and import the detected cookies

Typical required fields:

```text
SESSDATA=...; bili_jct=...; DedeUserID=...
```

## Main source mapping from the Flutter project

- `lib/pages/home/*` -> `Sources/Features/Home`
- `lib/pages/search/*` -> `Sources/Features/Search`
- `lib/pages/mine/*` -> `Sources/Features/Profile`
- `lib/pages/video/*` -> `Sources/Features/Video`
- `lib/http/*` and `lib/utils/wbi_sign.dart` -> `Sources/Core`

## Next native milestones

- Subtitle support
- Remote playback progress sync and resume history
- More complete account features and pagination
- Orientation handling and fullscreen polish
