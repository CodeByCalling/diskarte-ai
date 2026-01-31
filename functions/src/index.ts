
import * as functions from "firebase-functions";
import { defineSecret } from "firebase-functions/params";
import { getSystemPrompt } from "./prompts";
// import { GoogleGenerativeAI } from "@google/generative-ai";
import * as admin from "firebase-admin";

admin.initializeApp();
// import * as cors from "cors"; // Not used

const apiKey = defineSecret("GEMINI_API_KEY");

// 1. Gemini Caller
export const callGemini = functions
  .region("asia-southeast1")
  .runWith({ 
      secrets: [apiKey],
      timeoutSeconds: 60,
      memory: "256MB" 
  })
  .https.onRequest(async (req, res) => {
  // Manual CORS Headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  // Handle Preflight
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  // --- Auth Guard ---
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401).json({ error: "Unauthorized: Missing or invalid token" });
    return;
  }

  const token = authHeader.split("Bearer ")[1];
  let uid: string;

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    uid = decodedToken.uid;
    console.log(`User Authenticated: ${uid}`);
    
    // --- TRIAL MODE BYPASS ---
    // If user is anonymous, skip Firestore checks (Subscription/RateLimit).
    // The client enforces the 3-message limit.
    if (decodedToken.firebase.sign_in_provider === 'anonymous') {
        console.log(`Anonymous User ${uid}: Skipping checks for Trial.`);
    } else {
        // Only run checks for FULL users
        await checkSubscriptionAndRateLimit(uid, res);
        if (res.headersSent) return; // If check failed, response was sent
    }

  } catch (error) {
    console.error("Token Verification Failed:", error);
    res.status(403).json({ error: "Unauthorized: Invalid Token" });
    return;
  }



  // --- SACHET BUSINESS LOGIC END ---

  // Expecting JSON body
  const { message, featureType } = req.body;
  const formattedMessage = message ? message.trim().toUpperCase() : ''; // Added for debug command

  if (!message) {
    res.status(400).json({ error: "The function must be called with a message." });
    return;
  }

  const key = apiKey.value();
  if (!key) {
     res.status(500).json({ error: "API Key not configured." });
     return;
  }

  // --- DEBUG: LIST MODELS ---
  if (formattedMessage === "LIST_MODELS") {
      try {
          const listResponse = await axios.get(`https://generativelanguage.googleapis.com/v1beta/models?key=${key}`);
          const models = listResponse.data.models.map((m: any) => m.name).join(", ");
          res.json({ text: `Available Models: ${models}` });
          return;
      } catch (e: any) {
          console.error("List Models Error:", e.response?.data || e.message);
          res.json({ text: `Error Listing Models: ${JSON.stringify(e.response?.data || e.message)}` });
          return;
      }
  }

  // 6. Call Gemini API (RAW HTTP via Axios to bypass SDK issues)
  const apiModel = "gemini-2.0-flash";
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${apiModel}:generateContent?key=${key}`;

  const systemPrompt = getSystemPrompt(featureType);
  const fullPrompt = `${systemPrompt}\n\nUser: ${formattedMessage}`;

  try {
      const response = await axios.post(url, {
          contents: [{
              parts: [{ text: fullPrompt }]
          }]
      }, {
          headers: { 'Content-Type': 'application/json' },
          timeout: 30000 // 30s timeout
      });

      if (response.data && response.data.candidates && response.data.candidates.length > 0) {
          const candidate = response.data.candidates[0];
          if (candidate.content && candidate.content.parts && candidate.content.parts.length > 0) {
              const text = candidate.content.parts[0].text;
              await admin.firestore()
                  .collection("users")
                  .doc(uid)
                  .collection("chat_logs")
                  .doc(featureType) // Group by feature
                  .collection("messages")
                  .add({
                      content: text,
                      sender: "ai",
                      timestamp: admin.firestore.FieldValue.serverTimestamp(),
                  });
              res.json({ text });
          } else {
              res.json({ text: "I'm sorry, I couldn't generate a response." });
          }
      } else {
          res.json({ text: "I'm sorry, I couldn't generate a response." });
      }

  } catch (error: any) {
      console.error("Gemini API Error:", error.response?.data || error.message);
      // Return the raw error to the client for debugging
      const errorMessage = JSON.stringify(error.response?.data || error.message);
      res.status(500).json({ error: `Backend Error: ${errorMessage}` });
  }
});

// --- PAYMONGO WEBHOOK HANDLER ---

import * as crypto from "crypto";

const paymongoSecret = defineSecret("PAYMONGO_WEBHOOK_SECRET");

export const handlePayMongoWebhook = functions
  .region("asia-southeast1")
  .runWith({ secrets: [paymongoSecret] })
  .https.onRequest(async (req, res) => {
    
    // 1. Verify Signature
    const signatureHeader = req.headers["paymongo-signature"];
    const secret = paymongoSecret.value();

    if (!signatureHeader || typeof signatureHeader !== "string" || !secret) {
        console.error("Missing signature or secret.");
        res.status(401).send("Unauthorized");
        return;
    }

    try {
        // PayMongo Signature Format: t=1612345678,te=...
        const parts = signatureHeader.split(",");
        const timestampPart = parts.find(p => p.startsWith("t="));
        const testSignaturePart = parts.find(p => p.startsWith("te=")); // Test mode
        const liveSignaturePart = parts.find(p => p.startsWith("li=")); // Live mode

        const timestamp = timestampPart?.split("=")[1];
        const signature = liveSignaturePart?.split("=")[1] || testSignaturePart?.split("=")[1];

        if (!timestamp || !signature) {
             throw new Error("Invalid signature format");
        }

        // Canonical String: timestamp.body
        // Note: req.rawBody is available in firebase-functions for raw bytes processing
        // But functions.https.onRequest typically parses body. 
        // We need the raw string or buffer for HMAC. 
        // In standard Firebase Functions, `req.rawBody` should be available if we cast req.
        const rawBody = (req as any).rawBody; 
        
        if (!rawBody) {
            console.error("Raw body missing for signature verification.");
             // Fallback: If rawBody isn't available (emulator vs cloud), JSON.stringify might fail if formatting differs.
             // But usually Firebase provides rawBody.
             res.status(500).send("Server Error");
             return;
        }

        const computedSignature = crypto
            .createHmac("sha256", secret)
            .update(`${timestamp}.${rawBody.toString()}`)
            .digest("hex");

        // Safe Compare
        if (computedSignature !== signature) {
            console.error("Signature mismatch.");
            res.status(401).send("Unauthorized");
            return;
        }

    } catch (err) {
        console.error("Verification failed:", err);
        res.status(401).send("Unauthorized");
        return;
    }

    // 2. Process Event
    const event = req.body;
    
    // We only care about 'payment.paid'
    if (event.data?.attributes?.type !== "payment.paid") {
        // Acknowledge other events so PayMongo doesn't retry
        res.status(200).send("Ignored");
        return;
    }

    // 3. Extract Metadata (UID)
    // Structure: data.attributes.data.attributes.metadata.uid
    // (Based on Payment Intent or Checkout Session resource structure)
    const resource = event.data.attributes.data;
    const uid = resource.attributes?.metadata?.uid;

    if (!uid) {
        console.error("No UID found in payment metadata.");
        // We still return 200 to stop retries, but log error
        res.status(200).send("No UID");
        return;
    }

    console.log(`Processing Payment for User: ${uid}`);

    // 4. Update Firestore
    const db = admin.firestore();
    const userRef = db.collection("users").doc(uid);

    try {
         // 4. Idempotency & Firestore Update
         const userDoc = await userRef.get();
         const userData = userDoc.data();

         // Idempotency: Check if we already processed this payment ID
         if (userData?.last_payment_id === resource.id) {
             console.log(`Payment ${resource.id} already processed for user ${uid}. Skipping.`);
             res.status(200).send("Already Processed");
             return;
         }

         const now = admin.firestore.Timestamp.now();
         let newExpiry = now;

         // Logic: 
         // If subscription is currently active (future expiry), extend from THAT point.
         // If expired or null, start from NOW.
         const currentExpiry = userData?.subscription_end_timestamp;
         if (currentExpiry && currentExpiry > now) {
             // Extend existing
             newExpiry = new admin.firestore.Timestamp(currentExpiry.seconds + (24 * 60 * 60), currentExpiry.nanoseconds);
         } else {
             // New 24 hour pass
             newExpiry = new admin.firestore.Timestamp(now.seconds + (24 * 60 * 60), now.nanoseconds);
         }

         await userRef.set({
             subscription_end_timestamp: newExpiry,
             last_payment_id: resource.id,
             is_active: true
         }, { merge: true });

         console.log(`User ${uid} subscription extended to ${newExpiry.toDate()}`);
         res.status(200).send("Success");

    } catch (dbErr) {
        console.error("Firestore Update Failed:", dbErr);
        res.status(500).send("Database Error");
    }

  });

// --- ADMIN DASHBOARD STATS ---

export const getAdminStats = functions
  .region("asia-southeast1")
  .https.onRequest(async (req, res) => {
    // Manual CORS
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    // 1. Auth Guard
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({ error: "Unauthorized" });
      return;
    }

    const token = authHeader.split("Bearer ")[1];
    let uid: string;

    try {
      const decodedToken = await admin.auth().verifyIdToken(token);
      uid = decodedToken.uid;
    } catch (error) {
      res.status(403).json({ error: "Invalid Token" });
      return;
    }

    // 2. Owner Guard (Update this UID with the actual Owner UID)
    const OWNER_UID = "REPLACE_WITH_YOUR_OWNER_UID"; 
    
    if (uid !== OWNER_UID) {
        console.warn(`Unauthorized Admin Access Attempt by ${uid}`);
        res.status(403).json({ error: "Forbidden: Admins Only" });
        return;
    }

    try {
        const db = admin.firestore();
        const usersColl = db.collection('users');

        // 3. Metric: Total Users
        // specific 'count' aggregation is cheapest if available, ensuring we don't read all docs.
        // Node SDK usually supports this.
        const totalUsersSnapshot = await usersColl.count().get();
        const totalUsers = totalUsersSnapshot.data().count;

        // 4. Metric: Active Now (Subscription > Now)
        const now = admin.firestore.Timestamp.now();
        const activeUsersSnapshot = await usersColl
            .where('subscription_end_timestamp', '>', now)
            .count()
            .get();
        const activeUsers = activeUsersSnapshot.data().count;

        // 5. Revenue Proxy
        // Revenue = Active Users * 50 (Assuming Day Pass)
        // This is a rough estimation as requested.
        const estimatedRevenue = activeUsers * 50; 

        res.json({
            total_users: totalUsers,
            active_now: activeUsers,
            revenue_proxy: estimatedRevenue
        });

    } catch (error) {
        console.error("Admin Stats Error:", error);
        res.status(500).json({ error: "Failed to fetch stats" });
    }
  });

// --- PAYMONGO CHECKOUT SESSION ---

import axios from "axios";

export const createCheckoutSession = functions
  .region("asia-southeast1")
  .runWith({ secrets: [paymongoSecret] })
  .https.onCall(async (data, context) => {
    // 1. Auth Guard
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }

    const uid = context.auth.uid;
    const secret = paymongoSecret.value();

    if (!secret) {
        throw new functions.https.HttpsError("internal", "Missing PayMongo Secret");
    }

    try {
        // 2. Create Checkout Session via PayMongo API
        // https://developers.paymongo.com/docs/create-a-checkout-session
        const response = await axios.post(
            "https://api.paymongo.com/v1/checkout_sessions",
            {
                data: {
                    attributes: {
                        line_items: [
                            {
                                currency: "PHP",
                                amount: 100, // ₱1.00 (Beta Testing)
                                description: "Diskarte AI Day Pass (24 Hours)",
                                name: "Day Pass",
                                quantity: 1,
                                images: ["https://diskarte-ai.web.app/icons/Icon-192.png"]
                            }
                        ],
                        payment_method_types: ["gcash", "paymaya", "card", "grab_pay"],
                        description: "Diskarte AI Subscription",
                        success_url: "https://diskarte-ai.web.app/#/success", // Redirect back to app
                        cancel_url: "https://diskarte-ai.web.app/#/cancel",
                        reference_number: `REF-${Date.now()}`,
                        metadata: {
                            uid: uid // CRITICAL: This links payment to user
                        }
                    }
                }
            },
            {
                headers: {
                    Authorization: `Basic ${Buffer.from(secret).toString("base64")}`,
                    "Content-Type": "application/json"
                }
            }
        );

        const checkoutUrl = response.data.data.attributes.checkout_url;
        return { checkoutUrl };

    } catch (error: any) {
        console.error("PayMongo Checkout Creation Failed:", error.response?.data || error.message);
        throw new functions.https.HttpsError(
            "internal", 
            "Failed to create payment link. Please try again."
        );
    }
});

// Helper: Check Subscription & Rate Limit
async function checkSubscriptionAndRateLimit(uid: string, res: functions.Response): Promise<void> {
  const db = admin.firestore();
  const userRef = db.collection('users').doc(uid);

  try {
    const userDoc = await userRef.get();
    
    // Check if user exists
    if (!userDoc.exists) {
        console.warn(`User ${uid} profile not found. Treating as Trial/Anonymous.`);
        return; // Allow request to proceed
    }

    const userData = userDoc.data();
    const now = admin.firestore.Timestamp.now();
    const subEnd = userData?.subscription_end_timestamp;

    // Check Subscription Expiry
    if (!subEnd || subEnd < now) {
        console.warn(`User ${uid} subscription expired.`);
        res.status(403).json({ error: "Subscription expired. Please reload." });
        return;
    }

    // Check Rate Limit (5 seconds)
    const lastRequest = userData?.last_request_timestamp;
    if (lastRequest) {
        const lastReqTime = lastRequest.toDate().getTime();
        const nowTime = now.toDate().getTime();
        const diff = nowTime - lastReqTime;

        if (diff < 5000) {
            console.warn(`User ${uid} rate limited.`);
            res.status(429).json({ error: "Too many requests. Please wait 5 seconds." });
            return;
        }
    }

    // Update Access Time
    await userRef.update({ 
        last_request_timestamp: now 
    });

  } catch (err) {
      console.error("Firestore Check Error:", err);
      res.status(500).json({ error: "Internal Server Error during checks." });
      return;
  }
}
