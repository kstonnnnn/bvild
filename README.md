# Lost Luggage

A Flutter trading sim: bid blind on unclaimed airport luggage, unpack it, check what's real and flip the finds.

## Download

Open **Releases** on the right side of this page and grab the newest build:

- `lost-luggage-N.apk` — Android. New builds install over the old one and keep your progress.
- `lost-luggage-web-N.zip` — browser build for itch.io.

Every push to `main` builds a new release through GitHub Actions.

## Release setup

Repository secrets (Settings → Secrets and variables → Actions):

| Name | Kind | Purpose |
|---|---|---|
| `ANDROID_KEYSTORE_B64` | secret | Base64 of the release keystore. Without it, builds are debug-signed and cannot update each other. |
| `ANDROID_KEYSTORE_PASSWORD` | secret | Keystore and key password (alias `upload`) |
| `BUTLER_API_KEY` | secret | Optional. itch.io API key for automatic uploads |
| `ITCH_GAME` | variable | Optional. `user/game` on itch.io |
| `ITCH_URL` | variable | Optional. Link to the itch page shown in Settings |

The itch.io page kit (description, tags, theme colors, cover and banner) is in [`itch/PAGE.md`](itch/PAGE.md).

## Build locally

```
flutter create --project-name lost_luggage --org com.kston --platforms=android,web .
flutter pub get
flutter build apk --release
flutter build web --release
```
