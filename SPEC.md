# KidsBooks — Multilingual Online Children's Bookshop Mobile App
## Full Product & Technical Specification (v1.0)

**Project:** Online children's bookshop mobile app for the Mongolian market
**Languages:** Mongolian (mn), English (en), French (fr), Spanish (es), Korean (ko), Chinese (zh), Russian (ru)
**Payments:** QPay (Mongolia) | **Fulfillment:** Home delivery + in-app digital reading
**Stack:** Flutter (iOS + Android) + Firebase

---

## 1. Product Overview

KidsBooks is a mobile bookstore for children's books, serving parents and kids in Mongolia and abroad. Users browse a catalog of physical and digital children's books in 7 interface languages, filter by age group and language of the book itself, pay via QPay, and either receive physical books by courier or read purchased e-books inside the app's built-in reader.

### 1.1 Target users
- **Parents (primary buyers):** browse, purchase, manage delivery, control kids' profiles.
- **Children (readers):** kid-mode UI, read purchased e-books, browse age-appropriate titles only.
- **Diaspora / expat families:** buy Mongolian-language books abroad (digital) or gift-deliver domestically.

### 1.2 Core value propositions
1. The only children's bookstore app with a 7-language interface and per-book language filtering.
2. Frictionless local payment via QPay QR / deeplink.
3. Hybrid fulfillment: physical delivery in Ulaanbaatar (and provinces via postal partner) + instant digital delivery.
4. Safe, parent-controlled kids' experience with age-gated catalog.

---

## 2. Feature Set (MVP — all included per product decision)

### 2.1 Catalog & discovery
- Home screen: featured carousels (New, Bestsellers, By age: 0–2, 3–5, 6–8, 9–12), category chips.
- Full-text search (title, author, keyword) with filters: book language, age group, format (paper / e-book / both), price range.
- Book detail page: cover gallery, description (localized when available), age badge, language badge, format & price options, ratings & reviews, "similar books".

### 2.1b First-launch onboarding & personalization
Flow (before any catalog access): **Language → Age + Gender → Avatar → App skin → Home.**
1. **Language screen (first screen, language only):** scrollable list of the 7 UI languages in their native names; selection immediately switches the whole app to that language and advances.
2. **Age & gender:** age band (0–2 / 3–5 / 6–8 / 9–12) and gender (boy / girl / prefer not to say). Age drives default catalog filtering and avatar set; gender only tunes recommendations (never restricts catalog).
3. **Avatar picker:** age-appropriate sets of fairy-tale heroes, animals, and characters (e.g. 0–2: baby animals; 3–5: friendly animals/unicorn; 6–8: heroes, fairies, dragons, robots; 9–12: wizards, detectives, adventurers).
4. **App skin picker:** whole-app theme (background, primary/secondary colors, dark/light ink) applied via ThemeData: Classic, Pink Princess, Super Hero, Wizard School, Nature, Ocean, Calm, Spooky, Fairy-tale Palace. Changeable later in settings; stored per kid profile.
   > ⚠️ **IP note:** "Barbie", "Spider-Man", "Harry Potter" are licensed brands — shipping skins under those names/likenesses requires license agreements. Use original inspired-by themes (as above) unless licenses are obtained.
Onboarding data is stored locally pre-signup and merged into the user/kid profile after registration.

### 2.2 Accounts & kids' profiles
- Auth: phone number (OTP, primary for Mongolia), email/password, Google & Apple sign-in.
- One parent account → up to 4 kids' profiles (name, avatar, birth year → derived age band).
- Kid Mode: PIN-protected exit; catalog auto-filtered to profile's age band; no purchasing, no external links; larger touch targets and minimal text UI.
- Parental controls: spending happens only in parent mode; wishlist requests from kid profiles surface to parents ("Tanya wants this book").

### 2.3 Cart & checkout
- Cart supports mixed physical + digital items; digital items skip delivery fields.
- Checkout steps: cart review → delivery address (physical only) → payment (QPay) → confirmation.
- Address book: saved addresses (district/khoroo/building structure for UB + free-form for provinces/abroad-gifting).
- Delivery fee rules: flat fee by zone (UB central / UB outer / provincial post), free over threshold (configurable via Remote Config).

### 2.4 Payments — QPay
- Invoice created server-side (Cloud Function) at checkout; app shows QR code (for cross-device) and bank-app deeplinks (same-device).
- Payment confirmation via QPay callback → Cloud Function → order status flips to `paid` in Firestore → app updates in realtime.
- Manual "Check payment" button as fallback (polls payment-check endpoint).
- Refund handling: admin-initiated (phase 2 exposes user-facing cancellation before shipment).

### 2.5 Delivery & order tracking
- Order statuses: `pending_payment → paid → packing → shipped → delivered` (physical) / `pending_payment → paid → available` (digital).
- Realtime status screen with timeline UI; push notification on each transition.
- Courier integration: phase 1 = manual dispatch from admin panel; phase 2 = API integration with local courier aggregator.

### 2.6 E-reader
- Formats: EPUB (reflowable, preferred) and PDF (fixed layout, common for picture books).
- Purchased digital books listed in "My Library"; downloaded encrypted to app storage; offline reading.
- Reader features: page turn, thumbnails, brightness, kid-friendly UI; remembers last page per kid profile.
- Basic content protection: files stored encrypted per-device, no export/share. (Full DRM out of scope for MVP.)

### 2.7 Ratings & reviews
- 1–5 stars + text review, only after purchase (verified-purchase badge).
- Reviews moderated (admin approve/flag); profanity filter pre-check.
- Aggregate rating stored on book doc; recalculated by Cloud Function trigger.

### 2.8 Localization (7 languages)
- All UI strings via Flutter `intl` / ARB files: `app_mn.arb, app_en.arb, app_fr.arb, app_es.arb, app_ko.arb, app_zh.arb, app_ru.arb`.
- Language picker on first launch + in settings; persisted in local storage and user profile.
- Book metadata: `title`, `description` stored as localized map `{mn: ..., en: ...}` with fallback chain (selected → en → mn).
- Currency displayed in MNT; number/date formatting via `intl` per locale.
- RTL not required for these 7 languages.

### 2.9 Membership subscription (annual)
- **Annual membership** (price configurable via Remote Config, e.g. ₮99,000/yr) paid via a one-time QPay invoice — same payment rail as regular orders.
- **Benefit:** active members get **unlimited reading of all e-books** inside the app's reader (access, not ownership: no permanent entitlement is granted; downloads remain gated by short-lived signed URLs that check subscription validity).
- **Renewal:** QPay has no card-on-file auto-renewal in this flow, so renewal = a new invoice; push reminder 7 days and 1 day before expiry. Renewing early extends from the current expiry date (no lost days).
- **Data model:** `users/{uid}.subscription = { plan: "annual", startedAt, expiresAt, lastOrderId }`. Subscription purchases are stored as orders with `type: "subscription"` for a unified payment/refund history.
- **Access rule (server-side):** `getBookDownloadUrl` grants access if the user owns the book (`library` entitlement) **OR** `subscription.expiresAt > now`.
- **Edge cases:** expiry mid-read (already-downloaded book stays readable until app restart re-check; then blocked), refunds (admin removes subscription), family scope = one parent account incl. all kids' profiles.

### 2.10 Notifications
- FCM push: order status, payment success, new arrivals (opt-in), kid wishlist requests.
- In-app notification center (Firestore `notifications` subcollection).

---

## 3. Architecture

```
┌─────────────────────────────┐
│        Flutter App          │
│  (iOS / Android, 7 locales) │
│  Riverpod state · GoRouter  │
└──────────┬──────────────────┘
           │ Firebase SDKs (Auth, Firestore, Storage, FCM, Remote Config)
           ▼
┌─────────────────────────────┐        ┌──────────────┐
│         Firebase            │  HTTPS │   QPay API   │
│ Auth · Firestore · Storage  │◄──────►│ merchant.qpay│
│ Cloud Functions · FCM       │callback│    .mn/v2    │
└──────────┬──────────────────┘        └──────────────┘
           │ (phase 2)
           ▼
   Courier / Post API
```

- **State management:** Riverpod. **Navigation:** GoRouter. **Local cache:** Firestore offline persistence + `flutter_secure_storage` for reader keys.
- **All secrets (QPay credentials) live only in Cloud Functions env** — never in the app binary.
- **Admin panel:** phase 1 = Firebase console + a simple Flutter Web admin app (catalog CRUD, order dispatch, review moderation).

### 3.1 Firestore data model

```
users/{uid}
  displayName, phone, email, locale, fcmTokens[], createdAt
  kidsProfiles/{kidId}: name, avatar, birthYear, pin?, lastReadPositions{bookId: page}
  addresses/{addressId}: label, city, district, khoroo, building, detail, phone, isDefault
  notifications/{notifId}: type, title{loc}, body{loc}, read, createdAt

books/{bookId}
  title{mn,en,...}, description{mn,en,...}, authors[], coverUrls[],
  bookLanguage, ageBand (0-2|3-5|6-8|9-12), categories[],
  formats: { paper: {price, stock, weightGr}, ebook: {price, fileFormat, filePath, fileSizeMb} }
  ratingAvg, ratingCount, isFeatured, isActive, createdAt
  reviews/{reviewId}: uid, stars, text, status(pending|approved|rejected), createdAt

orders/{orderId}
  uid, items[{bookId, format, qty, unitPrice, titleSnapshot}],
  subtotal, deliveryFee, total, currency:"MNT",
  status, addressSnapshot?, qpay:{invoiceId, senderInvoiceNo, qrText, paidAt, paymentId},
  timeline[{status, at}], createdAt

library/{uid}/books/{bookId}   // digital entitlements
  orderId, grantedAt, fileFormat, filePath
```

### 3.2 Security rules (summary)
- `users/*`: owner read/write; kidsProfiles under owner only.
- `books`: public read (`isActive == true`); write admin-only (custom claim `admin: true`).
- `reviews`: create by verified purchaser (checked in Cloud Function via callable, not raw writes); read approved only.
- `orders`: owner read; create via callable function only (server computes prices — never trust client totals).
- `library`: owner read; write by Cloud Functions only.
- Storage: e-book files not publicly readable; delivered via short-lived signed URLs from a callable that checks entitlement.

---

## 4. QPay Integration Spec

> ⚠️ Endpoint paths/fields below are from prior integration knowledge; verify against the current Merchant V2 docs before implementation (see NotebookLM task in workflow).

**Flow (server-side, in Cloud Functions):**
1. **Auth:** `POST https://merchant.qpay.mn/v2/auth/token` with HTTP Basic (username/password issued by QPay) → `access_token` (+ `refresh_token`; refresh via `/v2/auth/refresh`). Cache token until expiry.
2. **Create invoice:** `POST /v2/invoice` with:
   ```json
   {
     "invoice_code": "KIDSBOOKS_INVOICE",
     "sender_invoice_no": "<orderId>",
     "invoice_receiver_code": "<uid>",
     "invoice_description": "KidsBooks order <orderId>",
     "amount": 45900,
     "callback_url": "https://<region>-<project>.cloudfunctions.net/qpayCallback?orderId=<orderId>"
   }
   ```
   Response: `invoice_id`, `qr_text`, `qr_image` (base64), `urls[]` (bank-app deeplinks). Store on order doc; app renders QR + deeplink buttons.
3. **Callback:** QPay calls `callback_url` on payment. Function must **not trust the callback blindly** — it calls `POST /v2/payment/check` with `object_type: "INVOICE"`, `object_id: <invoice_id>` to confirm `paid_amount == total`, then sets order `status: paid`, grants digital entitlements, sends FCM push, and responds `SUCCESS`.
4. **Fallback polling:** app's "Check payment" button → callable function → same payment-check call.
5. **Sandbox:** use QPay's merchant sandbox credentials for development; switch base URL via Functions config.

**Edge cases:** double callback (idempotency by orderId + invoice status guard), underpayment/partial (reject, keep pending, notify admin), invoice expiry (QPay invoices expire — recreate on retry), currency is MNT only.

---

## 5. UI/UX Direction

- **Look:** warm, playful, storybook-like. Rounded cards, generous whitespace, soft shadows.
- **Palette:** cream background `#FFF8EF`, coral primary `#FF6B57`, teal secondary `#2EC4B6`, sunshine accent `#FFC94D`, ink text `#2D2A32`.
- **Type:** Nunito / Baloo-style rounded sans (supports Cyrillic + Latin; Noto Sans KR/SC fallbacks for ko/zh).
- **Kid Mode:** bigger cards, icon-first navigation, mascot character, no prices shown.
- Age badges color-coded: 0–2 mint, 3–5 sky, 6–8 amber, 9–12 lavender.
- Bottom nav: Home · Search · Library · Orders · Profile.

---

## 6. Delivery Plan / Roadmap

| Phase | Scope | Est. |
|---|---|---|
| **P0 — Foundations** | Flutter project, i18n (7 ARB), design system, Firebase setup, auth | 2 wks |
| **P1 — Commerce core** | Catalog, search, book detail, cart, checkout, QPay (sandbox→prod), orders | 4 wks |
| **P2 — Kids & reading** | Kids profiles, Kid Mode, e-reader (EPUB/PDF), library, entitlements | 3 wks |
| **P3 — Social & polish** | Reviews, notifications, delivery tracking UI, admin web panel | 3 wks |
| **P4 — Launch** | Store listing (7-locale metadata), QA matrix, QPay production sign-off | 2 wks |

**KPIs:** activation (first purchase within 7 days), repeat purchase rate, e-book open rate, delivery SLA (UB < 48h).

---

## 7. Risks & open questions

1. **QPay production onboarding** requires a registered Mongolian merchant + contract — start early; sandbox first.
2. **E-book licensing/DRM** — confirm publisher requirements; MVP encryption may be insufficient for some publishers.
3. **Courier API availability** — phase 1 manual dispatch de-risks this.
4. **App Store kids category rules** (Apple) — if listed as Kids category, ads/tracking restrictions apply; recommend listing as Books/Shopping with parental gate instead.
5. **zh/ko font rendering size** — bundle Noto subsets or use system fonts to keep APK size sane.
