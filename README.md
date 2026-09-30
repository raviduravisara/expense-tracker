# Expense Tracker

A clean, responsive expense tracker built with **Flutter** and **Firebase** (Authentication + Cloud Firestore) for the CyphLab Flutter Developer Internship practical task.

**Demo video and release APK:** [OneDrive folder](https://1drv.ms/f/c/cb64a54655cc30ab/IgBiw0gWmfipQJHH97ckRjViARZAjUCNYpLOz_APpm1KvzI?e=mR2xb5) (contains the screen recording and `app-release.apk`)

## Features

### Core requirements
- **Add, edit and delete expenses** with title, amount, category, date and an optional note
- **Category selection** from 8 categories, each with its own icon and colour
- **Cloud Firestore storage** with real-time updates, scoped to the signed-in user
- **Monthly total** for the selected month, with navigation between months
- **Expense history** grouped by day with daily subtotals ("Today", "Yesterday", …)
- **Filtering** by category and by date range, which can be combined with search
- **Form validation**: required fields, amount format (max 2 decimals, > 0, upper limit), title/note length limits, required category, no future dates
- **Loading, empty, error and "no results" states** on every data-driven screen, with a retry action on errors

### Additional features
- **Firebase Authentication**: email/password sign-up, sign-in, password reset and sign-out
- **Insights tab**
  - Pie chart of spending by category, with percentages. Tapping a category jumps to the filtered list
  - Bar chart of the last 6 months
  - Monthly stats: total, daily average and largest expense
- **Search** by title or note
- **Dark mode** toggle; the choice is saved on the device
- **Swipe to delete with Undo**, plus delete from the edit screen with a confirmation dialog
- **Unsaved-changes guard**: leaving the form with edits asks before discarding them
- **Offline-friendly saves**: Firestore caches writes locally. If the server doesn't confirm within a few seconds, the user is told the expense will sync when back online
- **Responsive layout**: bottom navigation on phones, navigation rail on wide screens, constrained content width on tablets and web, and a two-column Insights layout on large screens
- **Firestore security rules** so users can only read and write their own data, and every write is schema-validated

## Tech stack

| Area | Choice |
|---|---|
| Framework | Flutter 3.38 / Dart 3.10, Material 3 |
| Backend | Firebase Authentication, Cloud Firestore |
| State management | [`provider`](https://pub.dev/packages/provider) (`ChangeNotifier`) |
| Charts | [`fl_chart`](https://pub.dev/packages/fl_chart) |
| Formatting | [`intl`](https://pub.dev/packages/intl) |
| Local preferences | [`shared_preferences`](https://pub.dev/packages/shared_preferences) (theme mode) |
| Testing | `flutter_test` (unit and widget tests with a fake repository) |

## Project structure

```
lib/
├── main.dart                     # Firebase + preferences bootstrap
├── app.dart                      # MaterialApp, themes, top-level providers
├── core/
│   ├── theme/                    # Material 3 light/dark theme, theme controller
│   └── utils/                    # formatters, validators, error messages, sync helper
├── data/
│   ├── auth_repository.dart      # FirebaseAuth wrapper
│   └── expense_repository.dart   # ExpenseRepository interface + Firestore implementation
├── models/                       # Expense, ExpenseCategory, ExpenseFilter, summaries
├── features/
│   ├── auth/                     # AuthGate + sign-in / sign-up screen
│   ├── home/                     # Navigation shell (bottom bar / rail)
│   ├── expenses/                 # Controller, list view, add/edit form, tile, actions
│   └── insights/                 # Charts and monthly summary
└── widgets/                      # Shared UI: state views, month selector, dialogs
test/                             # Unit tests + widget tests
firestore.rules                   # Firestore security rules
```

**How the pieces fit together**
- The UI never talks to Firebase directly. Screens depend on the `ExpenseRepository` interface, so tests swap in a fake repository.
- `ExpensesController` holds the selected month, the active filters and the list state (loading / error / data). It exposes computed values such as totals and filtered lists.
- `AuthGate` listens to the auth state and creates a fresh repository and controller per signed-in user.

## Data model

Expenses are stored per user at `users/{uid}/expenses/{expenseId}`:

| Field | Type | Notes |
|---|---|---|
| `title` | string | 2–50 characters |
| `amount` | number | > 0 |
| `category` | string | enum name, e.g. `food`, `transport` |
| `date` | timestamp | the day the expense happened |
| `note` | string \| null | optional, ≤ 200 characters |
| `createdAt` | timestamp | tie-breaker for ordering within a day |
| `updatedAt` | timestamp | server timestamp |

**Design decisions**
- **Month and date queries run on the server.** The app queries Firestore with a `date` range (`>= start of month`, `< start of next month`) ordered by `date`. Only the selected month is downloaded, and no composite index is needed.
- **Category, date-range and search filters run on the client.** They act on the month's data that is already loaded, so filtering is instant, costs no extra reads, and filters can be combined freely.

## Getting started

### Prerequisites
- Flutter SDK 3.38+ (`flutter doctor` should pass)
- A Firebase project ([console.firebase.google.com](https://console.firebase.google.com))
- Firebase CLI and FlutterFire CLI:
  ```bash
  npm install -g firebase-tools
  dart pub global activate flutterfire_cli
  ```

### 1. Clone and install
```bash
git clone <repo-url>
cd <repo-folder>
flutter pub get
```

### 2. Set up Firebase
1. In the Firebase console, create a project (or use an existing one).
2. **Authentication → Sign-in method** → enable **Email/Password**.
3. **Firestore Database** → create a database (production mode).
4. **Firestore → Rules** → paste the contents of [`firestore.rules`](firestore.rules) and publish.
5. Connect the app to your project:
   ```bash
   firebase login
   flutterfire configure
   ```
   Select your project and the platforms you need (Android / iOS / Web). This generates `lib/firebase_options.dart` and the platform config files.

### 3. Run
```bash
flutter run
```

### 4. Build a release APK
```bash
flutter build apk --release
```
The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Tests

```bash
flutter analyze
flutter test
```

The tests cover:
- the model (Firestore serialization)
- filter matching
- summaries (totals, grouping by day/category/month)
- validators
- the controller (loading/error states, month navigation, optimistic delete)
- widget tests for the add/edit form (validation, create, update, save failure)
- widget tests for the list and insights screens (loading, empty, error, no-results and chart rendering)

## AI tools used

- **Claude Code (Anthropic Claude)** was my main AI pair programmer. It helped me:
  - plan the architecture (repository interface, a `ChangeNotifier` controller per signed-in user, feature-based folders)
  - scaffold the screens and widgets
  - write the Firestore queries and security rules
  - write the unit and widget tests
- **Debugging and refinement.** Claude helped me check the `fl_chart` 1.x API. The widget tests caught a layout overflow on narrow (360 px) screens, which I then fixed. It also suggested handling offline Firestore writes, where a write stays pending forever without a connection.
- **Review.** I reviewed, ran and tested all generated code. I can explain every part of the project and have adjusted it where needed.
