# Waste Glass Collection App

A collector app for daily waste-glass pickups. The Flutter app loads today's
stop sequence from a .NET backend (route optimised with Haversine distances +
Dijkstra), guides the collector through a barcode-gated scan-and-collect flow,
and produces a trip report that syncs to the backend.

## Architecture

```
Flutter app (Android)  --HTTP-->  .NET 9 Web API  --Firestore SDK-->  Firebase Firestore
   (offline cache: SQLite)
```

- **Flutter** — 3 screens, no login, calls the REST API, caches every
  collection locally in SQLite so the trip works without connectivity.
- **.NET 9 Web API** — owns the route optimisation, the supplier/collection
  data, and is the only thing that talks to Firestore.
- **Firebase Firestore** — chosen over SQL Server/SQLite-on-server because
  there's no existing infra to stand up, it has a generous free tier, and the
  document model (`suppliers`, `collections`) maps directly onto the
  schema below without needing migrations.

## Data model (Firestore)

**`suppliers`** (document id = supplier id, also the barcode value)
| field | type | notes |
|---|---|---|
| id, name | string | |
| lat, lng | double | GPS coordinates |
| expectedKg | double | expected collection amount |
| barcodeId | string | Code128 value scanned at the stop |
| status | string | `Pending` / `Next` / `Collected` |
| stopOrder | int | position in the optimised route |
| collectedClearKg, collectedColouredKg | double | written when collection is submitted |
| tripDate | string | `yyyy-MM-dd`, so each day gets its own list |

**`collections`** (one doc per submitted collection)
| field | type |
|---|---|
| supplierId, condition, timestamp, tripDate | string |
| clearKg, colouredKg | double |

## Route optimisation

`RouteService.cs` implements the Haversine great-circle formula for the
distance between two GPS points, then runs Dijkstra from the collector's
start location: at each step it computes the shortest-path distance to every
unvisited supplier (which, on this complete graph, is just the direct edge)
and moves to the nearest one, repeating until every stop is visited. This
produces the same ordered stop sequence a full Dijkstra run would, without
needing artificial intermediate nodes.

## REST API

| Method | Route | Purpose |
|---|---|---|
| GET | `/api/route/optimised` | Today's suppliers (status, GPS) in optimised order + total route distance |
| POST | `/api/collection` | Submit one collection by supplier id — updates quantities & sets status to `Collected` |
| POST | `/api/collection/sync` | Bulk submit (used by the Screen 3 "Sync to server" button) |
| GET | `/api/trip/summary` | Per-supplier totals, shortfall flags, route distance |

## Running the backend locally

1. Create a Firebase project and a Firestore database (test mode is fine).
2. Project Settings → Service Accounts → Generate new private key, save it as
   `WasteGlassApi/firebase-key.json` (this file is gitignored — never commit it).
3. Set `Firebase:ProjectId` in `WasteGlassApi/appsettings.json` to your project id.
4. ```
   cd WasteGlassApi
   dotnet run
   ```
   The API starts on `http://localhost:5000` and seeds 5 sample suppliers into
   Firestore on first run (it skips seeding if today's suppliers already exist).

## Running the Flutter app

1. `cd waste_glass_collection && flutter pub get`
2. Point the app at your backend in `lib/utils/constants.dart`:
   - Android emulator talking to a backend on the same machine: leave the
     default `http://10.0.2.2:5000` (the emulator's alias for the host's
     `localhost`).
   - Physical device, or once the backend is hosted: set `baseUrl` to your
     LAN IP (e.g. `http://192.168.x.x:5000`) or the hosted URL.
3. `flutter run` (or `flutter build apk --release` for a release APK).

## Testing the barcode scan flow

1. Generate a Code128 barcode for each supplier id seeded above (`SUP001`
   … `SUP005`) using a free generator such as barcode.tec-it.com.
2. Display the barcode for the supplier marked **Next** on a second screen
   (or print it) and scan it from Screen 2 with the test device's camera.
3. A correct match unlocks the quantity form; any other barcode is rejected
   and the form stays locked — there is no manual override.

## Deploying for submission

- **Backend**: deploy `WasteGlassApi` to a free tier (Railway/Render/Azure).
  Set the `Firebase:ProjectId` config value and upload `firebase-key.json` as
  a secret file/environment variable on the host — don't bake it into the image.
- **App**: update `Constants.baseUrl` to the deployed URL, then
  `flutter build apk --release`. The submitted APK must point at this URL,
  not localhost.

## Project structure

```
WasteGlassApi/              .NET 9 Web API
  Controllers/               Route, Collection, Trip endpoints
  Services/                  FirebaseService (Firestore), RouteService (Haversine + Dijkstra)
  Models/                    Supplier, CollectionRecord
  Seed/                      Test supplier seed data

waste_glass_collection/     Flutter app
  lib/
    models/                  Supplier, CollectionRecord, RouteResult
    services/                ApiService (backend), SqliteService (offline cache)
    providers/               TripProvider (trip state/flow)
    screens/                  Screen 1 Trip Sequence, Screen 2 Scan & Collect, Screen 3 Trip Report
    utils/                    colors.dart, constants.dart
```
