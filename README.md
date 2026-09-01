# Gapsi Market

Product search app built with Flutter for the GAPSI practical exercise. It
searches a Walmart catalogue through the Axesso RapidAPI service, paginates as
the user scrolls, and keeps the search history on the device.

---

## Environment

| Tool | Version |
| --- | --- |
| Flutter | 3.38.3 (stable) |
| Dart | 3.10.1 |

The project is pinned to this toolchain (`environment.sdk: ^3.10.1`). Newer
releases of `go_router` and `sqflite` require Dart `^3.12.0`, so the pubspec
stays on the versions this SDK can resolve. Upgrading the SDK is a deliberate
decision, not a side effect of a dependency bump.

---

## Setup

```bash
flutter pub get
```

### API key

The app calls RapidAPI, which requires a subscription key. **The key is not in
this repository and never will be** — it is delivered separately, by email.

It is read at compile time through `String.fromEnvironment`, so it is injected
as a build flag rather than stored in a file:

```bash
flutter run --dart-define=RAPIDAPI_KEY=<key>
```

Building for release works the same way:

```bash
flutter build apk    --dart-define=RAPIDAPI_KEY=<key>
flutter build ipa    --dart-define=RAPIDAPI_KEY=<key>
```

If the app is launched without the flag it still builds and runs, and reports
the missing key on screen instead of failing with an opaque network error.

Tests and static analysis do not need the key.

---

## Running the tests

```bash
flutter test       # unit and widget tests
flutter analyze    # static analysis, expected to report no issues
```

---

## Technical decisions

Every dependency is annotated in `pubspec.yaml` with the reason it is there.
The summary below explains the choices that shape the architecture.

### State management — `flutter_bloc`

Bloc models a screen as an explicit event in, state out flow. Search has four
states the exercise calls for (loading, results, empty, error) plus pagination
layered on top, and Bloc makes that a single enumerable state instead of a set
of booleans that can contradict each other. It also keeps business logic out of
widgets, which is what allows the search and pagination rules to be tested
without pumping a UI. `bloc_test` asserts the exact sequence of emitted states.

### Local persistence — `sqflite` (SQLite)

The search history must survive an app restart. SQLite was chosen over a
key–value store because the data is relational and queried, not just read back:
history is ordered by recency and de-duplicated by term, and favourites relate
to products. It is also the storage engine every reviewer can inspect without
extra tooling.

A single connection is owned by `AppDatabase`; each module contributes its own
migration, so schema ownership stays with the feature that needs the table.

### Networking — `dio`

Chosen over `http` for its interceptor pipeline. The RapidAPI credentials are
attached in exactly one place, so no data source handles the key and a new
endpoint cannot forget it. Dio also exposes request cancellation, which the
debounced search relies on to drop in-flight requests when the query changes.

### Dependency injection — `get_it`

A service locator rather than a code generation framework: no build step, and
blocs receive their collaborators instead of constructing them, which is what
makes them testable against fakes. The locator instance is a parameter, so
tests build an isolated graph rather than mutating global state.

### Routing — `go_router`

Maintained by the Flutter team. Its declarative route table keeps navigation
readable in one file, and its `redirect` hook centralises the authentication
guard instead of scattering it across widgets.

### Error handling

Failures are modelled as a `sealed` hierarchy in `lib/shared/errors`. Being
sealed, adding a case breaks every non-exhaustive `switch` at compile time
rather than falling through at runtime. Failures carry no user-facing copy:
they state what happened and expose `isRetryable`, leaving the wording to the
presentation layer.

### Testing

`flutter_test` with `bloc_test` for state sequences, `mocktail` for null-safe
fakes without code generation, and `sqflite_common_ffi` to run a real SQLite
engine on the host VM so the persistence layer is exercised rather than mocked.

---

## Project structure

```
lib/
├── app.dart                  # application widget
├── main.dart                 # entry point: bindings, DI, router
├── configs/
│   ├── environment.dart      # build time configuration
│   └── router/               # route table and paths
├── modules/
│   └── <feature>/
│       ├── bloc/             # events, states, bloc
│       ├── contract/         # abstractions the bloc depends on
│       ├── datasource/       # remote (API) and local (SQLite) sources
│       ├── domain/           # models
│       ├── presenter/        # views and widgets
│       └── service/          # contract implementation
└── shared/
    ├── database/             # single SQLite connection and migrations
    ├── di/                   # service locator
    ├── errors/               # failure model and mapping
    └── network/              # Dio client and interceptors
```

Modules are self-contained: a feature brings its own screens, its own database
migration and its own registrations. Nothing in `shared/` or `configs/` needs to
know which features exist.

---

## Static analysis

`analysis_options.yaml` extends `flutter_lints` with the strict language modes
(`strict-casts`, `strict-inference`, `strict-raw-types`) and promotes
`unawaited_futures` to an error. Unsound casts and unawaited async work fail
analysis instead of surfacing at runtime.
