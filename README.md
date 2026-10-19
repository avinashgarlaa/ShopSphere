# ShopSphere

ShopSphere is a Flutter shopping catalogue built for the Prosessed Flutter Developer Intern assignment. It uses DummyJSON for sign-in, product discovery, product details, profile data, and simulated checkout; the cart and theme preference are persisted locally.

**Android release APK:** Built locally at `build/app/outputs/flutter-apk/app-release.apk`; it is debug-signed and must be signed with a private release keystore before distribution.  
**Demo video:** Not recorded yet.  
**GitHub repository:** Add the public repository link before submission.

## Screenshots

The required phone and tablet screenshots have not been captured in this workspace. Add at least four phone screenshots and two tablet/landscape screenshots here before submission. Include the login, catalogue, details, cart, profile, and expanded master-detail views.

## Features

### Mandatory requirements

- [x] Splash gate and persisted secure sign-in session.
- [x] Login validation, password visibility, loading feedback, and friendly invalid-credential errors.
- [x] Responsive product grid, API categories, debounced search, sorting, pull-to-refresh, pagination, skeletons, empty state, and retryable failures.
- [x] Product details with image carousel, rating, brand, price/discount, stock, quantity selector, reviews, and a graceful not-found state.
- [x] Locally persisted cart, quantity updates/removal, live badge, subtotal/discount/total, simulated checkout, and success confirmation.
- [x] Profile from `/auth/me`; manual logout and forced logout after an unauthorized profile response.
- [x] Light/dark theme preference persistence; compact, medium, and expanded layouts.

### Bonus and submission work

- [x] Automatic access-token refresh and one-time request retry; failed refresh clears the secure session.
- [x] Persisted wishlist, cached product pages with an offline banner, persisted English/Hindi selection, widget test, and GitHub Actions checks.
- [ ] Device/emulator screenshots, error-scenario recording, and release APK upload.

## Tech stack

- Flutter 3.44.0 / Dart 3.12.0 (stable at implementation time).
- `flutter_riverpod` for dependency injection and feature state controllers, keeping repositories out of widgets.
- `dio` for the shared configured HTTP client, timeouts, auth headers, debug logging, and failure mapping.
- `flutter_secure_storage` 10 for access and refresh tokens stored in the platform secure store.
- `shared_preferences` for local cart, theme, language, wishlist, and product-page-cache persistence.
- `cached_network_image` for network product and profile images with loading/error placeholders.
- `intl` for locale-aware currency formatting.
- `mocktail` and `flutter_test` for isolated repository, controller, model, and widget tests.

## Architecture

Feature-first, clean-architecture-inspired layers keep domain contracts independent of Flutter and HTTP:

```text
lib/
  core/                 # networking, failures, DI, theme, storage, shared UI
  features/
    auth/               # login contracts, repository, session controller
    products/           # product entities, repository, browse/detail UI
    cart/               # cart entities, local persistence, checkout
    profile/            # signed-in user UI
  app.dart              # session gate, login, responsive app shell
  main.dart             # startup and SharedPreferences bootstrap
```

Product-list data flow:

```text
ProductsScreen → ProductsController → ProductsRepository
  → ApiClient / DummyJSON → Result<ProductsPage>
  → ProductsState → ProductsScreen
```

## State management

Riverpod provides dependency injection and `Notifier` controllers for product, cart, session, theme, and navigation state. Business rules such as pagination, debouncing, cart persistence, and session transitions stay out of widgets. Async states are modeled explicitly with small sealed result/failure types rather than generated unions; this avoids code generation but requires maintaining state transitions manually.

## Error handling

`ApiClient` maps network errors, timeouts, HTTP validation/authorization/not-found/server responses, and unknown failures to typed `Failure` objects. Repositories return `Result<T>` for API-driven operations, and screens provide retry or empty feedback. Unauthorized requests trigger a serialized refresh attempt and retry once; failed refresh or a rejected retry clears the secure session and returns to login.

## Getting started

Prerequisites: Flutter 3.44.0 or a compatible stable SDK and Android tooling.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

No code generation is required. Build an Android release artifact with:

```bash
flutter build apk --release
```

The Android minimum SDK is 26 (Android 8.0). The current Gradle release configuration uses the debug signing key as a local-build convenience; configure a private release keystore outside source control before distributing the APK. Rename the final artifact to `ShopSphere_<FullName>_v1.0.0.apk`.

## Testing

Run `flutter test` for the unit and widget suite, or `flutter test --coverage` to regenerate the LCOV report at `coverage/lcov.info`. The current suite has 31 passing tests covering repository success/server/network/not-found paths, login validation and password visibility, product/cart JSON and calculations, sorting, controller loading/failure/stale-request behavior, and auth-header attachment. The latest measured line coverage is 19.5% (301 of 1,543 lines); the optional 60% target has not been reached. GitHub Actions runs `flutter analyze` and `flutter test` for pushes and pull requests.

## Test credentials

| Username | Password |
| --- | --- |
| `emilys` | `emilyspass` |

## Assumptions and trade-offs

- DummyJSON endpoints follow the documented response shapes; its checkout endpoint only simulates order creation.
- Cart items are persisted locally because server-side carts are not durable.
- Expired sessions attempt one refresh for concurrent requests; if refresh fails, secure tokens are cleared and the app returns to login.
- Network and image availability depend on DummyJSON and connectivity; failures remain retryable.
- English and Hindi cover the main authentication and shopping flows; product names, descriptions, and server-provided review text remain in their source language.

## AI assistance

AI assistance was used during implementation and review. The developer should review, understand, and personalize the submitted code and be ready to explain its behavior.

## Author

Replace this section with your full name, email, and LinkedIn/portfolio link before submitting.
