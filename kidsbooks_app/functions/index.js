/**
 * KidsBooks Cloud Functions — QPay integration + order lifecycle.
 *
 * QPay credentials live ONLY here (never in the app):
 *   firebase functions:config:set qpay.username="..." qpay.password="..." \
 *     qpay.invoice_code="KIDSBOOKS_INVOICE" qpay.base_url="https://merchant.qpay.mn"
 *
 * NOTE: verify endpoint paths/fields against the current QPay Merchant V2
 * docs (developer.qpay.mn) before production — see SPEC.md §4.
 */
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const QPAY_USERNAME = defineSecret("QPAY_USERNAME");
const QPAY_PASSWORD = defineSecret("QPAY_PASSWORD");
const QPAY_BASE = process.env.QPAY_BASE_URL || "https://merchant.qpay.mn";
const QPAY_INVOICE_CODE = process.env.QPAY_INVOICE_CODE || "KIDSBOOKS_INVOICE";

const DELIVERY_FEE_UB = 5000; // MNT; move to Remote Config for launch
const FREE_DELIVERY_THRESHOLD = 100000;
const ANNUAL_MEMBERSHIP_PRICE = 99000; // MNT/year; move to Remote Config
const YEAR_MS = 365 * 24 * 60 * 60 * 1000;

// ---------------------------------------------------------------- QPay auth
let cachedToken = null; // { token, expiresAt }

async function qpayToken() {
  if (cachedToken && Date.now() < cachedToken.expiresAt - 60_000) {
    return cachedToken.token;
  }
  const basic = Buffer.from(
    `${QPAY_USERNAME.value()}:${QPAY_PASSWORD.value()}`
  ).toString("base64");
  const res = await fetch(`${QPAY_BASE}/v2/auth/token`, {
    method: "POST",
    headers: { Authorization: `Basic ${basic}` },
  });
  if (!res.ok) throw new Error(`QPay auth failed: ${res.status}`);
  const data = await res.json();
  cachedToken = {
    token: data.access_token,
    expiresAt: Date.now() + (data.expires_in ?? 3600) * 1000,
  };
  return cachedToken.token;
}

// ------------------------------------------------------------- createOrder
// Validates the cart server-side (never trust client prices), creates the
// order doc and a QPay invoice, returns QR text + bank deeplinks.
exports.createOrder = onCall(
  { secrets: [QPAY_USERNAME, QPAY_PASSWORD], region: "asia-northeast1" },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in required");

    const items = req.data.items;
    if (!Array.isArray(items) || items.length === 0) {
      throw new HttpsError("invalid-argument", "Empty cart");
    }

    // Recompute prices from Firestore.
    let subtotal = 0;
    let hasPhysical = false;
    const orderItems = [];
    for (const it of items) {
      const snap = await db.collection("books").doc(it.bookId).get();
      if (!snap.exists) throw new HttpsError("not-found", `Book ${it.bookId}`);
      const book = snap.data();
      const offer = book.formats?.[it.format];
      if (!offer) throw new HttpsError("invalid-argument", "Bad format");
      const qty = it.format === "ebook" ? 1 : Math.max(1, Math.min(10, it.qty | 0));
      if (it.format === "paper") {
        hasPhysical = true;
        if ((offer.stock ?? 0) < qty) {
          throw new HttpsError("failed-precondition", `Out of stock: ${it.bookId}`);
        }
      }
      subtotal += offer.price * qty;
      orderItems.push({
        bookId: it.bookId,
        format: it.format,
        qty,
        unitPrice: offer.price,
        titleSnapshot: book.title?.en || book.title?.mn || "",
      });
    }

    let addressSnapshot = null;
    if (hasPhysical) {
      const addrQ = await db
        .collection("users").doc(uid).collection("addresses")
        .where("isDefault", "==", true).limit(1).get();
      if (addrQ.empty) {
        throw new HttpsError("failed-precondition", "No default address");
      }
      addressSnapshot = addrQ.docs[0].data();
    }

    const deliveryFee =
      hasPhysical && subtotal < FREE_DELIVERY_THRESHOLD ? DELIVERY_FEE_UB : 0;
    const total = subtotal + deliveryFee;

    const orderRef = db.collection("orders").doc();
    await orderRef.set({
      uid,
      items: orderItems,
      subtotal,
      deliveryFee,
      total,
      currency: "MNT",
      status: "pending_payment",
      addressSnapshot,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      timeline: [],
    });

    // Create QPay invoice.
    const token = await qpayToken();
    const callbackUrl =
      `https://asia-northeast1-${process.env.GCLOUD_PROJECT}` +
      `.cloudfunctions.net/qpayCallback?orderId=${orderRef.id}`;
    const invRes = await fetch(`${QPAY_BASE}/v2/invoice`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        invoice_code: QPAY_INVOICE_CODE,
        sender_invoice_no: orderRef.id,
        invoice_receiver_code: uid,
        invoice_description: `KidsBooks order ${orderRef.id}`,
        amount: total,
        callback_url: callbackUrl,
      }),
    });
    if (!invRes.ok) {
      await orderRef.update({ status: "cancelled", cancelReason: "invoice_failed" });
      throw new HttpsError("internal", `QPay invoice failed: ${invRes.status}`);
    }
    const inv = await invRes.json();

    await orderRef.update({
      qpay: {
        invoiceId: inv.invoice_id,
        qrText: inv.qr_text,
        deeplinks: (inv.urls || []).map((u) => u.link),
      },
    });

    return {
      orderId: orderRef.id,
      qrText: inv.qr_text,
      deeplinks: (inv.urls || []).map((u) => u.link),
    };
  }
);

// ---------------------------------------------- createSubscriptionOrder
// Annual membership: one-time QPay invoice; on payment, subscription
// expiry is extended by 365 days (from current expiry if still active).
exports.createSubscriptionOrder = onCall(
  { secrets: [QPAY_USERNAME, QPAY_PASSWORD], region: "asia-northeast1" },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in required");

    const total = ANNUAL_MEMBERSHIP_PRICE;
    const orderRef = db.collection("orders").doc();
    await orderRef.set({
      uid,
      type: "subscription",
      items: [
        {
          bookId: null,
          format: "membership",
          qty: 1,
          unitPrice: total,
          titleSnapshot: "KidsBooks Annual Membership",
        },
      ],
      subtotal: total,
      deliveryFee: 0,
      total,
      currency: "MNT",
      status: "pending_payment",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      timeline: [],
    });

    const token = await qpayToken();
    const callbackUrl =
      `https://asia-northeast1-${process.env.GCLOUD_PROJECT}` +
      `.cloudfunctions.net/qpayCallback?orderId=${orderRef.id}`;
    const invRes = await fetch(`${QPAY_BASE}/v2/invoice`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        invoice_code: QPAY_INVOICE_CODE,
        sender_invoice_no: orderRef.id,
        invoice_receiver_code: uid,
        invoice_description: `KidsBooks annual membership ${orderRef.id}`,
        amount: total,
        callback_url: callbackUrl,
      }),
    });
    if (!invRes.ok) {
      await orderRef.update({ status: "cancelled", cancelReason: "invoice_failed" });
      throw new HttpsError("internal", `QPay invoice failed: ${invRes.status}`);
    }
    const inv = await invRes.json();
    await orderRef.update({
      qpay: {
        invoiceId: inv.invoice_id,
        qrText: inv.qr_text,
        deeplinks: (inv.urls || []).map((u) => u.link),
      },
    });
    return {
      orderId: orderRef.id,
      qrText: inv.qr_text,
      deeplinks: (inv.urls || []).map((u) => u.link),
    };
  }
);

// ---------------------------------------------------- payment verification
async function verifyAndSettle(orderId) {
  const orderRef = db.collection("orders").doc(orderId);
  const snap = await orderRef.get();
  if (!snap.exists) return { paid: false, reason: "order_not_found" };
  const order = snap.data();
  if (order.status !== "pending_payment") return { paid: order.status !== "cancelled" };

  const token = await qpayToken();
  const res = await fetch(`${QPAY_BASE}/v2/payment/check`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      object_type: "INVOICE",
      object_id: order.qpay.invoiceId,
      offset: { page_number: 1, page_limit: 10 },
    }),
  });
  if (!res.ok) return { paid: false, reason: `check_failed_${res.status}` };
  const data = await res.json();
  const paidAmount = data.paid_amount ?? 0;
  if (paidAmount < order.total) return { paid: false, reason: "unpaid_or_partial" };

  // Idempotent settle inside a transaction.
  await db.runTransaction(async (tx) => {
    const fresh = await tx.get(orderRef);
    if (fresh.data().status !== "pending_payment") return;

    // All reads must precede writes in a Firestore transaction.
    let userSnapForSub = null;
    const isSubscription = fresh.data().type === "subscription";
    const userRef = db.collection("users").doc(fresh.data().uid);
    if (isSubscription) {
      userSnapForSub = await tx.get(userRef);
    }

    tx.update(orderRef, {
      status: "paid",
      "qpay.paidAt": admin.firestore.FieldValue.serverTimestamp(),
      timeline: admin.firestore.FieldValue.arrayUnion({
        status: "paid",
        at: admin.firestore.Timestamp.now(),
      }),
    });
    // Subscription order: extend membership by 365 days.
    if (isSubscription) {
      const current =
        userSnapForSub.data()?.subscription?.expiresAt?.toMillis?.() ?? 0;
      const base = Math.max(current, Date.now());
      tx.set(
        userRef,
        {
          subscription: {
            plan: "annual",
            startedAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromMillis(base + YEAR_MS),
            lastOrderId: orderId,
          },
        },
        { merge: true }
      );
      return;
    }

    // Grant digital entitlements + decrement paper stock.
    for (const item of fresh.data().items) {
      if (item.format === "ebook") {
        tx.set(
          db.collection("library").doc(fresh.data().uid)
            .collection("books").doc(item.bookId),
          {
            orderId,
            grantedAt: admin.firestore.FieldValue.serverTimestamp(),
          }
        );
      } else {
        tx.update(db.collection("books").doc(item.bookId), {
          "formats.paper.stock": admin.firestore.FieldValue.increment(-item.qty),
        });
      }
    }
  });

  // Push notification (best-effort).
  try {
    const user = await db.collection("users").doc(order.uid).get();
    const tokens = user.data()?.fcmTokens || [];
    if (tokens.length) {
      await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title: "KidsBooks",
          body: `Захиалга #${orderId.slice(0, 8)} төлөгдлөө! 🎉`,
        },
      });
    }
  } catch (e) {
    console.warn("push failed", e);
  }
  return { paid: true };
}

// QPay server-to-server callback. Never trusted blindly — always re-checked
// via /v2/payment/check inside verifyAndSettle.
exports.qpayCallback = onRequest(
  { secrets: [QPAY_USERNAME, QPAY_PASSWORD], region: "asia-northeast1" },
  async (req, res) => {
    const orderId = req.query.orderId;
    if (!orderId) return res.status(400).send("missing orderId");
    try {
      await verifyAndSettle(String(orderId));
      res.status(200).send("SUCCESS");
    } catch (e) {
      console.error(e);
      res.status(500).send("ERROR");
    }
  }
);

// Manual fallback for the app's "Check payment" button.
exports.checkQpayPayment = onCall(
  { secrets: [QPAY_USERNAME, QPAY_PASSWORD], region: "asia-northeast1" },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in required");
    const orderId = req.data.orderId;
    const order = await db.collection("orders").doc(orderId).get();
    if (!order.exists || order.data().uid !== uid) {
      throw new HttpsError("permission-denied", "Not your order");
    }
    return verifyAndSettle(orderId);
  }
);

// Entitlement-gated signed URL for e-book download.
exports.getBookDownloadUrl = onCall({ region: "asia-northeast1" }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required");
  const { bookId } = req.data;
  // Access if the user OWNS the book OR has an ACTIVE membership.
  const ent = await db
    .collection("library").doc(uid).collection("books").doc(bookId).get();
  if (!ent.exists) {
    const user = await db.collection("users").doc(uid).get();
    const expiresAt = user.data()?.subscription?.expiresAt;
    const active = expiresAt && expiresAt.toMillis() > Date.now();
    if (!active) {
      throw new HttpsError(
        "permission-denied",
        "Not purchased and no active membership"
      );
    }
  }
  const book = await db.collection("books").doc(bookId).get();
  const filePath = book.data()?.formats?.ebook?.filePath;
  if (!filePath) throw new HttpsError("not-found", "No e-book file");
  const [url] = await admin.storage().bucket().file(filePath).getSignedUrl({
    action: "read",
    expires: Date.now() + 15 * 60 * 1000, // 15 minutes
  });
  return { url, fileFormat: book.data().formats.ebook.fileFormat };
});
