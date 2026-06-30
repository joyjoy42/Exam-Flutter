# BadWallet — Consumer Mobile App

Flutter "consumer" client for BadWallet: balance, peer-to-peer transfers, bill
payments, and transaction history, backed by the BadWallet API & Payment
Service exposed at `http://localhost:8080`.

This app is the **client tier** of the system — the backend (BadWallet API)
is a separate, pre-existing service. Everything below describes how the
client is architected to be production-grade and to scale (more screens,
more traffic, a future GraphQL/gRPC backend, multi-region rollout) without a
rewrite.

---

## 1. System architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter Client (this repo)                │
│                                                                     │
│  Screens (Widgets)                                                 │
│      │  watch / read                                               │
│      ▼                                                             │
│  Providers (ChangeNotifier) — Loading / Success / Failure state    │
│      │  call                                                       │
│      ▼                                                             │
│  Repositories — stale-while-revalidate, cache invalidation,        │
│                 JSON ↔ model mapping                               │
│      │                              │                               │
│      ▼                              ▼                               │
│  ApiClient (http)            CacheService (SharedPreferences)      │
│  - base URL resolution        - TTL-based local cache              │
│  - timeout + bounded retry    - offline fallback                   │
│  - status code → AppException │                                    │
└──────────────┬──────────────────────────────────────────────────┘
               │ HTTPS/HTTP (JSON)
               ▼
┌─────────────────────────────────────────────────────────────────┐
│         BadWallet API & Payment Service  (localhost:8080)         │
│         — out of scope for this repo, treated as a contract —     │
└─────────────────────────────────────────────────────────────────┘
```

**Why this shape scales:**

- **UI never talks to `http` directly.** Every network call goes through
  `ApiClient` → `Repository` → `Provider` → `Widget`. Swapping `http` for
  `Dio`, adding auth headers, or pointing at a gateway/BFF later touches one
  file, not every screen.
- **Repositories are the only thing that knows about caching.** Providers
  just render `Result<T>` (`Loading` / `Success` / `Failure`); they don't
  know or care whether the data came from the network or disk.
- **Idempotency keys** are generated client-side for every mutating call
  (`transfer`, `pay-factures`). A backend that honors them can safely
  de-duplicate a request the client had to retry after a timeout — this is
  what prevents double-spends at scale, not "just don't retry."
- **Feature-first folders** mean two engineers can work on `transfers/` and
  `bills/` in parallel without touching each other's files, and a feature
  can be deleted/flagged off by deleting one directory.

---

## 2. Component structure

```
lib/
├── main.dart                  # composition root: builds singletons,
│                               # wires repositories → providers, MaterialApp
├── core/
│   ├── constants/              # base URL resolution, TTLs, magic numbers
│   ├── network/                # ApiClient, AppException taxonomy, Result<T>
│   ├── storage/                # CacheService (TTL cache), SecureStorageService
│   ├── theme/                  # colors, typography
│   ├── router/                 # route names + onGenerateRoute
│   ├── utils/                  # currency formatting, idempotency keys
│   └── widgets/                # TransactionTile (shared dashboard/history)
├── models/                     # Wallet, Transaction, Facture, requests
├── features/
│   ├── auth/        # phone capture, session restore (data/providers/screens)
│   ├── dashboard/   # balance + quick actions + recent transactions
│   ├── transfers/   # recipient + custom numeric keypad + confirm + submit
│   ├── bills/        # provider picker, facture checkboxes, batch pay
│   └── history/      # full transaction list (reuses dashboard's repository)
└── test/
    ├── core/cache_service_test.dart
    └── models/transaction_test.dart
```

Each feature follows the same internal shape: `data/` (Repository),
`providers/` (ChangeNotifier), `screens/` + `widgets/` (UI). This is the
seam to extract a feature into its own package if the app/team grows.

---

## 3. Data flow

**Read path (e.g. opening the dashboard):**

1. `DashboardScreen` calls `WalletProvider.load(phone)`.
2. `WalletProvider` sets state to `Loading`, notifies, then calls
   `WalletRepository.getBalance()` / `getRecentTransactions()` concurrently
   (`Future.wait`) — balance and transactions never block each other.
3. `WalletRepository` checks `CacheService` first. If a fresh (within-TTL)
   entry exists, it's returned immediately — no network round-trip.
4. Otherwise it calls `ApiClient.get(...)`. On success, the response is
   cached (with TTL) and mapped to a model. On failure, it falls back to
   whatever is cached, marked `isStale: true`, so the UI still shows the
   last known balance instead of a blank error screen.
5. `WalletProvider` stores the `Result` and notifies listeners; the screen
   rebuilds via `context.watch`.

**Write path (e.g. a transfer):**

1. `TransferScreen` collects recipient + amount via the custom numeric
   keypad, shows a confirmation dialog, then calls
   `TransferProvider.submit(...)`.
2. `TransferProvider` generates a fresh idempotency key and calls
   `TransferRepository.transfer()`, which `POST`s to
   `/api/wallets/transfer`.
3. On success, the repository **invalidates the cache** for both the
   sender's and recipient's phone numbers — this is what stops the
   dashboard from showing a pre-transaction balance after a successful
   transfer.
4. The screen pops back to the dashboard with `result: true`; the dashboard
   refresh-on-return re-fetches balance + transactions from the network.

This same Loading → Repository → cache-invalidate-on-write pattern is
reused identically for bill payments.

---

## 4. API design (client contract against the BadWallet API)

| Method | Path | Purpose | Client cache |
|---|---|---|---|
| `GET` | `/api/wallets/{phone}/balance` | Current balance | 30s TTL |
| `GET` | `/api/wallets/{phone}/transactions` | Full transaction history (dashboard takes the 5 most recent) | 60s TTL |
| `GET` | `/api/external/factures/{provider}?phone={phone}` | Unpaid bills for a provider (ISM, WOYAFAL, RAPIDO, SENELEC) | 5min TTL |
| `POST` | `/api/wallets/transfer` | Peer-to-peer transfer | invalidates balance+tx cache for both parties |
| `POST` | `/api/wallets/pay-factures` | Batch-pay selected bills | invalidates balance+tx cache + bills cache |

Mutating request bodies include a client-generated `idempotencyKey`
(`core/utils/idempotency.dart`) so a manual retry after a timeout is safe
even if the first attempt actually succeeded server-side.

`ApiClient` maps every non-2xx response to one exception type
(`core/network/app_exception.dart`):

| HTTP status | Exception | UI treatment |
|---|---|---|
| timeout / socket error | `NetworkException` / `TimeoutAppException` | "no connection" + retry |
| 400 / 422 | `ValidationException` | inline form error |
| 401 / 403 | `AuthException` | force re-auth |
| 404 | `NotFoundException` | empty state |
| 5xx | `ServerException` | generic error + retry |

GET requests retry automatically (bounded, exponential backoff) since reads
are side-effect-free. POST requests are **not** auto-retried — see the
idempotency note above for why a blind retry of a money-moving call is
dangerous.

---

## 5. Database schema

This client does not own a database — BadWallet API does. Two schemas are
relevant to this repo:

### 5.1 Backend schema (reference only — owned by BadWallet API)

```
wallets
  phone         varchar PK
  balance       decimal(18,2)
  currency      varchar(3)         -- e.g. "XOF"
  updated_at    timestamp

transactions
  id            uuid PK
  from_phone    varchar FK -> wallets.phone (nullable for deposits)
  to_phone      varchar FK -> wallets.phone (nullable for withdrawals)
  type          enum('TRANSFER','BILL_PAYMENT','DEPOSIT','WITHDRAWAL')
  amount        decimal(18,2)
  status        enum('PENDING','COMPLETED','FAILED')
  idempotency_key varchar UNIQUE   -- dedupes retried client requests
  created_at    timestamp

factures
  id            uuid PK
  provider      varchar            -- 'ISM' | 'WOYAFAL' | 'RAPIDO' | 'SENELEC'
  wallet_phone  varchar FK -> wallets.phone
  reference     varchar
  amount        decimal(18,2)
  due_date      date
  paid          boolean
```

`idempotency_key` as a unique constraint on `transactions` is the piece
that makes the client's retry strategy actually safe — it's listed here as
the production recommendation for whoever owns the backend.

### 5.2 Client-side local persistence (implemented in this repo)

| Store | Mechanism | Keys | Contents |
|---|---|---|---|
| Secure storage | `flutter_secure_storage` (Keystore/Keychain) | `user_phone` | the signed-in phone number only — never balances or transactions |
| TTL cache | `SharedPreferences`, JSON blobs | `balance::{phone}`, `transactions::{phone}`, `factures::{provider}::{phone}` | last-known API responses + `cachedAt` + `ttlMs`, for instant cold-start render and offline fallback |

The `::` separator in cache keys is what lets `CacheService.invalidateForPhone(phone)`
sweep every cache entry for a user in one call after a transfer or bill
payment.

---

## 6. Caching strategy

**Stale-while-revalidate, not just "cache-first":**

1. Read from `CacheService`. If present and within TTL → return instantly,
   no network call.
2. If absent or expired → call the network. On success, overwrite the
   cache and return fresh data.
3. If the network call fails (offline, timeout, 5xx) → fall back to the
   cached value even if it's expired, tagged `isStale: true`. The UI shows
   a small "offline" indicator instead of an error screen. Only if there's
   *no* cache at all does the user see a hard failure + retry button.

**TTLs are tuned per resource volatility**, not a single global value:
balance (30s) needs to look fresh; bills (5min) change a handful of times a
month. This is configured in one place (`AppConstants`) for easy tuning.

**Write-through invalidation:** every mutating call (`transfer`,
`pay-factures`) invalidates the affected phone numbers' cache entries
immediately on success, so the next read is guaranteed fresh — correctness
trumps cache hit-rate for money.

**Scaling this further:** `CacheService` is intentionally the only file
that knows about `SharedPreferences`. If transaction history grows past
what's comfortable in a JSON blob, swap it for Hive/Isar/sqflite behind the
same `read`/`write`/`invalidate` interface — no repository changes needed.
A production rollout would also add a `Cache-Control`/`ETag`-aware HTTP
cache at the `ApiClient` layer if the backend starts sending those headers.

---

## 7. State management

`Provider` + `ChangeNotifier`, as recommended by the spec. Every async
operation is represented as `Result<T>` (`core/network/result.dart`):

```dart
sealed class Result<T> {}
class Loading<T> extends Result<T> {}
class Success<T> extends Result<T> { final T data; final bool isStale; }
class Failure<T> extends Result<T> { final AppException error; }
```

Screens pattern-match on it (`switch (state) { Loading() => ..., Success(:final data) => ..., Failure(:final error) => ... }`)
so the analyzer enforces exhaustiveness — adding a new state can't silently
leave a screen unhandled.

---

## 8. Getting started

Flutter SDK was not available in the environment this code was authored
in, so the platform folders (`android/`, `ios/`, `web/`) are intentionally
**not** checked in — generate them locally, then drop this `lib/` and
`pubspec.yaml` in:

```bash
flutter create --org com.badwallet --project-name badwallet_app .
flutter pub get
flutter run
```

(If `flutter create .` prompts about overwriting `pubspec.yaml`/`lib/`,
keep your existing files — it only needs to add the missing `android/`,
`ios/`, etc. folders.)

### Pointing at the backend

By default the app resolves the BadWallet API base URL automatically:
- Android emulator → `http://10.0.2.2:8080` (emulator's alias for host loopback)
- iOS simulator / desktop / web → `http://localhost:8080`
- Physical device or a non-default host → override at build/run time:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8080
```

### Android: cleartext HTTP

The backend is plain HTTP (`localhost:8080`), and Android blocks cleartext
traffic by default from API 28+. After `flutter create .`, add to
`android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

(For a real production deploy, put the backend behind HTTPS instead and
remove this flag.)

### Custom app icon

Add an icon at `assets/icon/icon.png` (1024×1024 recommended), then
uncomment the `flutter_launcher_icons` block in `pubspec.yaml` and the
`flutter.assets` entry, and run:

```bash
dart run flutter_launcher_icons
```

### Tests

```bash
flutter test
```

### Building the release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## 9. What "production-grade" means here vs. what's deliberately deferred

Implemented: layered architecture, typed error handling, offline-first
caching with TTL + invalidation, idempotency keys on mutations, bounded
retry with backoff on reads, environment-based API host configuration,
unit tests on the cache/model layer.

Deliberately out of scope for this exam deliverable (called out so it's
clear these are *known* gaps, not oversights): real authentication
(OTP/PIN/biometric — the spec marks this optional/simulated), server-side
pagination for transaction history (the repository signature already
supports `forceRefresh`/limit so wiring pagination later doesn't change
call sites), push notifications, and CI/CD.
