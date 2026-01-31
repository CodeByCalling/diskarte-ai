const crypto = require('crypto');
const fs = require('fs');

// Usage: node sign_paymongo.js <payload_file> <secret>
const args = process.argv.slice(2);
if (args.length < 2) {
    console.error("Usage: node sign_paymongo.js <payload_file> <secret>");
    process.exit(1);
}

const payloadPath = args[0];
const secret = args[1];

try {
    const rawBody = fs.readFileSync(payloadPath, 'utf8');
    const timestamp = Math.floor(Date.now() / 1000);

    // Signature = HMAC-SHA256(timestamp + "." + rawBody, secret)
    const signature = crypto
        .createHmac("sha256", secret)
        .update(`${timestamp}.${rawBody}`)
        .digest("hex");

    // PayMongo Header Format: t=<timestamp>,li=<signature> (li for live, te for test - we use li to match logic usually, or just match what the code expects)
    // The code checks: liveSignaturePart?.split("=")[1] || testSignaturePart?.split("=")[1]
    // So 'li' or 'te' works. Let's use 'te' for test.
    const headerValue = `t=${timestamp},te=${signature}`;
    
    process.stdout.write(headerValue);
} catch (err) {
    console.error("Error signing payload:", err);
    process.exit(1);
}
