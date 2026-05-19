// Supabase Edge Function: notify-new-order
// Triggered by Database Webhook on INSERT to 'transactions' table.
// Sends FCM push notification to 'admin_orders' topic so admin HP gets notified
// even when the app is closed/killed.

// Deno type declarations for VS Code compatibility
// deno-lint-ignore-file
declare const Deno: {
  serve(handler: (req: Request) => Promise<Response> | Response): void;
  env: { get(key: string): string | undefined };
};

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// --- Google OAuth2 token generation for FCM v1 API ---
// We need to generate an OAuth2 access token from the service account key
// because FCM HTTP v1 API requires Bearer token auth (not just a server key).

interface ServiceAccountKey {
  type: string;
  project_id: string;
  private_key_id: string;
  private_key: string;
  client_email: string;
  client_id: string;
  auth_uri: string;
  token_uri: string;
}

/** Base64url encode */
function base64url(input: Uint8Array | string): string {
  const bytes =
    typeof input === "string" ? new TextEncoder().encode(input) : input;
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/** Import a PEM private key for RS256 signing */
async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const pemContents = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binaryDer = Uint8Array.from(atob(pemContents), (c) =>
    c.charCodeAt(0)
  );
  return crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );
}

/** Generate a signed JWT for Google OAuth2 */
async function createSignedJwt(
  serviceAccount: ServiceAccountKey
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: serviceAccount.token_uri,
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  const encodedHeader = base64url(JSON.stringify(header));
  const encodedPayload = base64url(JSON.stringify(payload));
  const signingInput = `${encodedHeader}.${encodedPayload}`;

  const key = await importPrivateKey(serviceAccount.private_key);
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput)
  );

  return `${signingInput}.${base64url(new Uint8Array(signature))}`;
}

/** Exchange JWT for Google OAuth2 access token */
async function getAccessToken(
  serviceAccount: ServiceAccountKey
): Promise<string> {
  const jwt = await createSignedJwt(serviceAccount);
  const res = await fetch(serviceAccount.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });
  const data = await res.json();
  if (!res.ok) {
    throw new Error(`OAuth2 token error: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}

// --- Helpers ---

function formatRupiah(n: number): string {
  return "Rp " + n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".");
}

function parseItems(raw: unknown): Array<Record<string, unknown>> {
  if (!raw) return [];
  if (Array.isArray(raw)) return raw;
  if (typeof raw === "string") {
    try {
      return JSON.parse(raw);
    } catch {
      return [];
    }
  }
  return [];
}

// --- Main handler ---

Deno.serve(async (req: Request) => {
  try {
    // Only accept POST
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Parse the webhook payload from Supabase
    const body = await req.json();
    console.log("[notify-new-order] Received webhook:", JSON.stringify(body));

    // Supabase Database Webhook sends: { type, table, record, schema, old_record }
    const record = body.record;
    if (!record) {
      console.log("[notify-new-order] No record in payload, skipping");
      return new Response(JSON.stringify({ ok: true, skipped: true }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // Build notification content
    const orderId = record.order_id || "-";
    const customer =
      record.customer_username || record.customer_email || "Customer";
    const grossAmount = parseInt(record.gross_amount || "0", 10);
    const items = parseItems(record.items);

    const productNames = items
      .map((item) => {
        const name = (item.name || item.product_name || "") as string;
        const qty = item.quantity || item.qty || 1;
        return name ? `${name} x${qty}` : "";
      })
      .filter((s) => s.length > 0);

    // Build body text
    const bodyParts: string[] = [];
    if (customer) bodyParts.push(`👤 ${customer}`);
    if (productNames.length > 0) bodyParts.push(`📦 ${productNames.join(", ")}`);
    if (grossAmount > 0) bodyParts.push(`💰 ${formatRupiah(grossAmount)}`);
    bodyParts.push(`🧾 ${orderId}`);

    const notifTitle = "🛍️ Pesanan Baru Masuk!";
    const notifBody = bodyParts.join("\n");

    console.log("[notify-new-order] Sending FCM:", notifTitle, notifBody);

    // Get service account from env
    const saKeyRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY");
    if (!saKeyRaw) {
      console.error("[notify-new-order] FIREBASE_SERVICE_ACCOUNT_KEY not set!");
      return new Response(
        JSON.stringify({ error: "FIREBASE_SERVICE_ACCOUNT_KEY not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const serviceAccount: ServiceAccountKey = JSON.parse(saKeyRaw);
    const accessToken = await getAccessToken(serviceAccount);

    // Send FCM via HTTP v1 API
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;
    const fcmPayload = {
      message: {
        topic: "admin_orders",
        notification: {
          title: notifTitle,
          body: notifBody,
        },
        data: {
          type: "new_order",
          order_id: orderId,
          customer: customer,
          amount: grossAmount.toString(),
        },
        android: {
          priority: "HIGH",
          notification: {
            channel_id: "new_orders",
            sound: "default",
            default_vibrate_timings: true,
            notification_priority: "PRIORITY_HIGH",
            visibility: "PUBLIC",
          },
        },
      },
    };

    const fcmRes = await fetch(fcmUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(fcmPayload),
    });

    const fcmResult = await fcmRes.json();
    console.log("[notify-new-order] FCM response:", JSON.stringify(fcmResult));

    if (!fcmRes.ok) {
      console.error("[notify-new-order] FCM error:", fcmResult);
      return new Response(
        JSON.stringify({ ok: false, error: fcmResult }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ ok: true, fcm: fcmResult }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("[notify-new-order] Error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
