#!/bin/bash

# Configuration
PROJECT_ID="diskarte-ai"
REGION="asia-southeast1" # Must match function region
FUNCTION_NAME="handlePayMongoWebhook"
EMULATOR_HOST="127.0.0.1:5001"
URL="http://$EMULATOR_HOST/$PROJECT_ID/$REGION/$FUNCTION_NAME"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Default Values
DEFAULT_UID="test_user_$(date +%s)"
DEFAULT_SECRET="testing_secret_key" # Should match what is configured in your emulator or .env

# Usage Help
if [[ "$1" == "--help" ]]; then
  echo "Usage: ./test_webhook.sh [UID] [WEBHOOK_SECRET]"
  echo "  UID: User ID to simulate payment for (default: random)"
  echo "  WEBHOOK_SECRET: PayMongo Secret used by the function (default: testing_secret_key)"
  exit 0
fi

UID_VAL=${1:-$DEFAULT_UID}
SECRET_VAL=${2:-$DEFAULT_SECRET}

# Create Payload File
PAYLOAD_FILE="payload.json"

cat > $PAYLOAD_FILE <<EOF
{
  "data": {
    "attributes": {
      "type": "payment.paid",
      "livemode": false,
      "data": {
        "id": "pay_$(date +%s)",
        "attributes": {
          "amount": 100,
          "currency": "PHP",
          "metadata": {
            "uid": "$UID_VAL"
          }
        }
      }
    }
  }
}
EOF

echo "Generated payload for User: $UID_VAL"

# Calculate Signature using the Node.js helper
# We need to ensure the node script is found. 
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIGNATURE_HEADER=$(node "$SCRIPT_DIR/sign_paymongo.js" "$PAYLOAD_FILE" "$SECRET_VAL")

if [ $? -ne 0 ]; then
    echo -e "${RED}Error calculating signature.${NC}"
    exit 1
fi

echo "Signature Header: $SIGNATURE_HEADER"
echo "Sending Request to: $URL"

# Send Request
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$URL" \
  -H "Content-Type: application/json" \
  -H "Paymongo-Signature: $SIGNATURE_HEADER" \
  -d @"$PAYLOAD_FILE")

# Parse Response
HTTP_BODY=$(echo "$RESPONSE" | head -n -1)
HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)

echo "----------------------------------------"
if [ "$HTTP_STATUS" -eq 200 ]; then
  echo -e "${GREEN}SUCCESS (200)${NC}"
  echo "Response: $HTTP_BODY"
  echo "The user subscription should now be updated in Firestore."
elif [ "$HTTP_STATUS" -eq 204 ]; then
    echo -e "${GREEN}SUCCESS (No Content)${NC}"
else
  echo -e "${RED}FAILED ($HTTP_STATUS)${NC}"
  echo "Response: $HTTP_BODY"
  echo ""
  echo "Tip: If you get 401 Unauthorized, check if '$SECRET_VAL' matches the PAYMONGO_WEBHOOK_SECRET configured in your emulator."
fi

# Cleanup
rm $PAYLOAD_FILE
