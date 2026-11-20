# CSE20 Final Project — Rental Listing App

Flutter mobile app that displays long-term rental listings, supports filtering,
favorites, and detailed property views with map location.

## Team Members

- **Miranda, Art Elvin B.**
- **Santos, Jonnard Enzo**
- **Santana, Christian Paul**
- **Garcia, Yuan Miguel**

## Project Overview

This project is a **Rental Listing App** built with Flutter.

The app fetches rental data from the RentCast API and lets users:

- browse listings
- filter by city/state and price range
- save/remove favorites
- view detailed listing information
- preview property coordinates on an OpenStreetMap map
- switch between light and dark mode (saved locally)

## Implemented Features

- **Remote listing fetch** from RentCast (`state=TX`, `limit=100`)
- **Listings tab** with card-based UI and thumbnail support
- **Favorites tab** persisted using `SharedPreferences`
- **Price filters** (`All`, `<1k`, `1k-1.5k`, `1.5k-2k`, `>2k`, `Custom`)
- **Location multi-select filters** generated from fetched results
- **Filter summary + collapsible filter section**
- **Infinite scroll behavior** (loads in batches of 15)
- **Detail screen** with extended property metadata
- **Embedded map** using `flutter_map` + OpenStreetMap tiles
- **Dark mode toggle** persisted in local storage

## Tech Stack

- **Framework:** Flutter (Dart)
- **State management:** `StatefulWidget` + `setState`
- **HTTP client:** `http`
- **Local persistence:** `shared_preferences`
- **Map rendering:** `flutter_map`, `latlong2`

## Project Structure

```text
lib/
  main.dart                 # App root, theme persistence, MaterialApp setup
  home_page.dart            # Main UI, API fetch, filters, favorites, navigation
  listing.dart              # Listing model + JSON serialization helpers
  listing_details_page.dart # Detail UI + map view
test/
  widget_test.dart          # Default Flutter starter test (currently outdated)
```

## Data Flow (High-Level)

1. `main.dart` loads saved theme preference.
2. `HomePage` loads favorites from local storage.
3. `HomePage` fetches listings from RentCast API.
4. Listings are mapped into the `Listing` model and deduplicated.
5. UI applies location/price filters on the in-memory list.
6. Favorites are toggled and saved back to `SharedPreferences`.
7. Tapping a listing opens `ListingDetailsPage`.

## Setup and Run

### Prerequisites

- Flutter SDK installed and configured
- Android Studio / VS Code with Flutter plugins
- Android emulator or physical Android device

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

## API Configuration

The RentCast API key is currently hardcoded in:

- `lib/home_page.dart`

```dart
const String rentcastApiKey = 'YOUR_API_KEY';
```

For production-quality security, move this key to a safer configuration approach
(e.g., build-time env vars or secure backend proxy).

## Codebase Analysis Summary

### Strengths

- Clear separation of concerns between app entry, home screen, model, and detail screen.
- User-focused features are complete for an MVP rental browsing experience.
- Good inline documentation and readable naming across the main files.
- Local persistence is implemented for both theme mode and favorites.

### Gaps / Risks

- API key is committed in source code (`lib/home_page.dart`).
- Favorites currently match by `title` only; duplicate titles may conflict.
- Listing URL in detail page is shown as text only (not tappable).
- API request is fixed to Texas (`state=TX`) and not user-configurable.
- `test/widget_test.dart` is still the default counter test and does not match app behavior.

## Suggested Next Improvements

1. Replace hardcoded API key strategy.
2. Update widget tests to reflect current screens and interactions.
3. Add tap-to-open external listing URL (with `url_launcher`).
4. Use a stable listing ID for favorites/deduping when available.
5. Add search and sorting (price, newest listing, bedroom count).

## Notes on Local Validation in This Environment

During this update, Dart/Flutter CLI commands were not runnable in the current
shell due to a local Flutter script line-ending issue:

```text
/mnt/c/Users/artelvin/develop/flutter/bin/internal/shared.sh: line 5: $'\r': command not found
```

If you run this repository on a standard Flutter setup, run:

```bash
flutter analyze
flutter test
```

to validate formatting, lints, and tests.
