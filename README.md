# Neon Dash

A portrait Android endless runner set in a neon city. Tap to jump, swipe down to
slide, avoid barriers, and collect coins. Spend earned coins in the in-game shop
to unlock runners and gameplay upgrades.

The game stores progress locally. The shop uses in-game coins only; it does not
charge real money or require an account.

## Build an Android APK

Push this folder to a GitHub repository. In **Actions**, run **Build Android
APK**, then download the `neon-dash-apk` artifact from the completed workflow.

You can also build locally with Flutter:

```text
cd app
flutter pub get
flutter build apk --release
```
