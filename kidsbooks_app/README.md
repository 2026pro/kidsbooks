# МИНИЙ НАЙЗ (kidsbooks) — Multilingual Children's E-Bookshop App (Flutter + Firebase)

Online children's bookstore for Mongolia: 7-language UI (mn/en/fr/es/ko/zh/ru),
QPay payments, home delivery tracking, kids' profiles with Kid Mode, built-in
e-reader, ratings & reviews, and an **annual membership** with unlimited
e-book reading (`/membership` screen + `createSubscriptionOrder` function;
access enforced server-side in `getBookDownloadUrl`).

## Project layout

```
lib/
  main.dart              app entry (Firebase init)
  app.dart               MaterialApp.router, 7 locales, GoRouter routes
  core/theme.dart        design system (colors, Material 3 theme)
  core/locale_provider.dart  persisted language selection
  models/                book, order, kid_profile
  services/              firestore streams, cart (Riverpod), QPay client,
                         phone-OTP auth
  screens/               home, search, book detail, cart, checkout (QPay QR),
                         order tracking, kids profiles, reader, language
  widgets/book_card.dart
  l10n/app_*.arb         7 translation files (gen-l10n)
functions/index.js       Cloud Functions: createOrder, qpayCallback,
                         checkQpayPayment, getBookDownloadUrl
firestore.rules          security rules
```

## Setup

1. `flutter pub get` (Flutter ≥ 3.22). ARB files auto-generate
   `lib/l10n/app_localizations.dart` on build (`generate: true`).
2. Create a Firebase project, run `flutterfire configure`, uncomment
   `firebase_options.dart` usage in `main.dart`.
3. Enable: Auth (Phone, Google, Apple), Firestore, Storage, Functions, FCM.
4. Deploy rules & functions:
   ```
   firebase deploy --only firestore:rules
   cd functions && npm i && firebase deploy --only functions
   ```
5. QPay: obtain merchant credentials (sandbox first), then:
   ```
   firebase functions:secrets:set QPAY_USERNAME
   firebase functions:secrets:set QPAY_PASSWORD
   ```
   Set `QPAY_BASE_URL` / `QPAY_INVOICE_CODE` env vars per environment.
   ⚠️ Verify endpoint paths against developer.qpay.mn Merchant V2 docs.

## Key flows

- **Checkout:** cart → `createOrder` callable (server recomputes prices,
  creates QPay invoice) → app shows QR + bank deeplinks → QPay callback hits
  `qpayCallback` → server re-verifies via `/v2/payment/check` → order flips
  to `paid` → app auto-navigates via Firestore stream.
- **E-books:** payment grants entitlement in `library/{uid}/books/{bookId}`;
  reader fetches a 15-min signed URL via `getBookDownloadUrl`.
- **Kid Mode:** catalog filtered by kid's age band; parent PIN to exit;
  purchases only in parent mode.

## Not yet wired (next steps)

- Address book UI (checkout currently uses default address)
- EPUB/PDF rendering in ReaderScreen (packages included: epub_view, pdfx)
- Review submission UI + moderation admin panel
- Courier API integration (phase 2 — statuses updated manually by admin now)
