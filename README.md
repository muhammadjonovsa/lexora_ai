# LexoraAI - AI-Powered Smart Text Editor

LexoraAI is a production-level, feature-complete Android mobile application built using Flutter. It is designed to be a premium, high-fidelity personal writing workstation that merges standard mobile rich-text editing with cutting-edge artificial intelligence capabilities.

---

## 🌟 Key Features

1. **Animated Splash Screen:** Holographic pulsing AI launcher that automatically checks authentication tokens and boots configurations.
2. **Robust Multi-mode Authentication:** Clean forms for Login, Registration, and Password Resets powered by Firebase. Includes a **one-tap Guest Mode** that redirects instantly to local storage operations if Firebase configurations are not yet set.
3. **Executive Dashboard Hub:** Features recent document feeds, dynamic global text searches, responsive grid vs list layout toggles, quick actions (Create Document, launch AI), and swipeable menus.
4. **Hybrid WYSIWYG Editor:** Integrates a custom `LexoraRichTextController` that parses markdown delimiters (`**bold**`, `*italic*`, `_underline_`, headings, bullets, blocks) in real-time. It renders the formatting inline and styles the raw markdown symbols as semi-transparent so they disappear into the background.
5. **Auto-Save & Offline Sync:** Keypresses fire throttled updates to local caches (`SharedPreferences`). If the user is authenticated and online, it asynchronously updates Cloud Firestore without blocking the editor UI thread.
6. **Dynamic AI Assistant Console:** 
   - **Uzbek Grammar Inspector:** Locates common mistakes, explains changes in Uzbek, and provides side-by-side comparison blocks with "Apply Changes" hooks.
   - **Smart Summarization:** Generates high-level summaries and key bullet-point takeaways.
   - **Tone Polisher:** Transforms standard drafts into executive, formal copy.
   - **Bi-directional Translator:** Supports Uzbek ↔ English and Russian ↔ Uzbek translations.
7. **Conversational AI Chat console:** Thread-safe chatbot memory with suggesting chips (e.g. "Brainstorm startup ideas", "Draft professional resignation letter") and an animated character-by-character streaming typing effect.
8. **On-device ML OCR Scanner:** Connects Google ML Kit Text Recognition with camera/gallery frames to scan documents and inject text lines at the current cursor location.
9. **Speech-to-Text Voice Dictation:** Handles local microphone recordings, calculates live decibel sound levels to render a pulsing animated sound wave, and pastes transcribed sentences at the cursor position.
10. **Universal Document Exporters:** Custom PDF generator with clean print margins, native share sheet integrations, and direct network printing.

---

## 📂 Architecture & Folder Structure

We follow the **Clean Architecture** specifications:

```
lib/
├── core/
│   ├── theme/          # Curved design system (gradients, obsidian dark mode)
│   ├── routes/         # Type-safe navigation, scale+fade page transitions
│   ├── constants/      # App keys, prompt templates, global models
│   └── widgets/        # Universal premium controls (buttons, glow textfields, toasts)
├── features/
│   ├── splash/         # Pulse breathing loading launch
│   ├── auth/           # Login, Register, Forgot Password
│   ├── dashboard/      # Document filters, view togglers, search
│   ├── editor/         # Visual toolbar, controllers, local caches
│   ├── ai_assistant/   # Streaming chat logs, suggestion lists
│   └── profile/        # Theme togglers, dynamic Gemini vaults
├── services/
│   ├── firebase_auth_service.dart  # Auth pipelines, Guest logic
│   ├── ai_service.dart             # Gemini REST API & Sandbox Emulator
│   ├── ocr_service.dart            # On-device Google ML Text recognizer
│   ├── voice_service.dart          # Local microphone capture, amplitude feeds
│   └── export_service.dart         # Layout margins PDF builders, system sharing
└── main.dart           # Riverpod bootstrap, Safe Firebase bootstrapper
```

---

## 🚀 Setup & Execution Guide

### Prerequisites
- **Flutter SDK:** `^3.41.3`
- **Dart SDK:** `^3.11.1`
- **Android SDK:** API 21 or newer

### Installation Step-by-Step

1. **Clone & Open Project:**
   Open this project directory in your preferred IDE (VS Code or Android Studio).

2. **Retrieve Dependencies:**
   Run the package downloader command:
   ```bash
   flutter pub get
   ```

3. **Deploy Firebase (Optional):**
   LexoraAI is designed to be **100% testable out-of-the-box** without Firebase files. If you want to connect your cloud accounts:
   - Create a project on the [Firebase Console](https://console.firebase.google.com/).
   - Add an Android App and enter package name `com.example.lexoraai` (or matching).
   - Download the `google-services.json` file and place it inside:
     `android/app/google-services.json`
   - Re-run the app. Cloud Firestore synchronization will activate automatically.

4. **Activate AI Features:**
   To perform real-time Gemini queries:
   - Go to Google AI Studio and fetch a free [Gemini API Key](https://aistudio.google.com/).
   - Launch the LexoraAI app.
   - Click the Profile Icon (top right) -> paste your key in the **Gemini API Kaliti** field -> tap **Kalitni saqlash**.
   - Your device now makes direct REST calls to `gemini-1.5-flash`! If no key is entered, the app gracefully runs in **AI Sandbox Simulator** mode, producing extremely high-fidelity mock results for immediate testing.

5. **Run the App:**
   ```bash
   flutter run
   ```

---

## 🛠️ State Management & Data Flow
- **Riverpod Providers:**
  - `authStateProvider`: Direct stream of the user state from Firebase.
  - `guestModeProvider`: Local boolean flag determining if the user is in local storage guest mode.
  - `documentListProvider`: Stateful notifier that loads, auto-saves, renames, and deletes documents, triggering instant visual rebuilds across the Dashboard search lists and editors.
  - `themeModeProvider`: Rebuilding provider checking local settings caches to swap palettes.
