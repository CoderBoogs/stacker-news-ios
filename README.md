# Stacker News iOS App

A native iOS application for Stacker News — a Lightning-powered Bitcoin social news platform. Built with SwiftUI and targeting iOS 17+.

## Features

- **Face ID / Touch ID** — Biometric lock screen using LocalAuthentication
- **Dark Mode First** — Electric yellow (#E6FF00) branding on dark backgrounds  
- **Lightning Wallet** — Send, receive, and display Bitcoin balance in sats
- **Post Feed** — Browse, zap, bookmark, and comment on posts
- **New Post** — Create discussion, link, or image posts
- **Search** — Search posts with recent and trending topics
- **Profile** — View user stats, posts, comments, and zaps
- **Secure Storage** — Auth tokens stored in Keychain, never in UserDefaults

---

## Quick Start (Open in Xcode)

### Requirements

- **Mac** with macOS 14.0 (Sonoma) or later
- **Xcode 15** or later
- **iOS 17** device or simulator

### Steps

1. **Copy the `ios-app` folder to your Mac**

2. **Open the project in Xcode:**
   ```
   open ios-app/StackerNews/StackerNews.xcodeproj
   ```
   Or double-click `StackerNews.xcodeproj` in Finder.

3. **Set your backend URL** — Open `Resources/Info.plist` and update the `API_BASE_URL` value to your Replit backend:
   ```
   https://your-project-name.replit.app
   ```

4. **Select a signing team** — In Xcode, click the `StackerNews` project in the navigator, go to **Signing & Capabilities**, and select your Apple Developer team.

5. **Run the app** — Select an iPhone simulator (iPhone 15 or newer recommended) and press **Cmd+R**.

---

## Project Structure

```
ios-app/StackerNews/
├── StackerNews.xcodeproj/         ← Open this in Xcode
│   └── project.pbxproj
├── Sources/
│   ├── App/
│   │   ├── StackerNewsApp.swift   ← App entry point, lock screen, Face ID
│   │   └── MainTabView.swift      ← Tab bar navigation
│   ├── Core/
│   │   ├── Networking/
│   │   │   └── APIClient.swift    ← REST API client (async/await)
│   │   ├── Services/
│   │   │   └── AuthService.swift  ← Face ID + passcode auth
│   │   └── Storage/
│   │       └── KeychainService.swift  ← Secure token storage
│   ├── Features/
│   │   ├── HomeFeed/
│   │   │   ├── HomeFeedView.swift     ← Post list with sort picker
│   │   │   └── PostDetailView.swift   ← Post + comments thread
│   │   ├── Wallet/
│   │   │   └── WalletView.swift       ← Balance, transactions, send/receive
│   │   ├── Search/
│   │   │   └── SearchView.swift       ← Search with trending topics
│   │   ├── Profile/
│   │   │   └── ProfileView.swift      ← User profile + stats
│   │   └── NewPost/
│   │       └── NewPostView.swift      ← Create discussion, link, or image post
│   ├── Models/
│   │   └── Models.swift               ← All Codable data models
│   └── SharedUI/
│       ├── Components/
│       │   └── PostCardView.swift     ← Post card + skeleton loading state
│       └── Theme/
│           └── Theme.swift            ← Colors, AppTheme, SNLogo
└── Resources/
    ├── Info.plist                     ← Permissions + API URL
    └── Assets.xcassets/               ← App icon + accent color
```

---

## Configuring Your Backend URL

Open `Resources/Info.plist` and find the `API_BASE_URL` key. Replace the placeholder with your actual Replit backend URL:

```xml
<key>API_BASE_URL</key>
<string>https://your-project-name.replit.app</string>
```

The app reads this value automatically at launch.

---

## Capabilities Required (Xcode)

In **Signing & Capabilities**, add:

| Capability | Why |
|---|---|
| **Face ID** | Biometric lock screen |

The camera permission (QR scanning) and photo library permission (image posts) are declared in Info.plist and activate automatically when the user triggers those features.

---

## Color Reference

| Color | Value | Usage |
|---|---|---|
| Electric Yellow | `hsl(56, 100%, 60%)` | Buttons, icons, selected state |
| Bitcoin Orange | `hsl(25, 100%, 50%)` | Sat balance display |
| Dark Background | `rgb(18, 18, 18)` | Main background |
| Dark Card | `rgb(31, 31, 31)` | Card / sheet backgrounds |

---

## API Endpoints Used

The app calls these REST endpoints on your Replit backend:

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/auth/login` | Sign in with username/password |
| `GET` | `/api/auth/me` | Fetch current user |
| `GET` | `/api/posts` | List posts (hot/top/recent) |
| `POST` | `/api/posts` | Create a new post |
| `GET` | `/api/posts/:id/comments` | Get comments for a post |
| `POST` | `/api/comments` | Post a comment |
| `POST` | `/api/zaps` | Zap a post or comment |
| `GET` | `/api/lightning/transactions` | Transaction history |
| `POST` | `/api/lightning/invoice` | Generate receive invoice |
| `POST` | `/api/lightning/pay` | Pay a Lightning invoice |

---

## Future Enhancements

- **Breez SDK** — Full self-custodial Lightning wallet
- **Push Notifications** — APNs for zap alerts and replies
- **Nostr integration** — Cross-post to Nostr relays
- **Home Screen Widget** — Balance and trending posts
- **QR Scanner** — Camera-based invoice scanning (UI stubbed in SendView)
