#!/usr/bin/env bash

# .env file content
#DOMAIN=
#SECRET_KEY=
#API_KEY=

API_URL="https://api.porkbun.com/api/json/v3/dns"
BASEDIR=$(dirname "$0")
ENV_PATH="$BASEDIR/.env"
LOG_DIR="$BASEDIR/logs"
LOG_FILE="$LOG_DIR/log_$(date '+%Y-%m-%d').txt"

# Tạo thư mục logs nếu chưa tồn tại
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

# Hàm ghi log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Tải biến môi trường
export $(grep -v '^#' "$ENV_PATH" | xargs)

log "--- Start DDNS Update ---"

# Lấy thông tin DNS record
RECORD=$(curl --location --request POST "$API_URL/retrieve/$DOMAIN" \
--header 'Content-Type: application/json' \
--data-raw '{
    "secretapikey": "'"$SECRET_KEY"'",
    "apikey": "'"$API_KEY"'"
}' | jq -r .records[0])

# Kiểm tra kết quả trả về
if [ "$RECORD" = "null" ]; then
    log "Error: Cannot retrieve DNS record."
else
    ID=$(echo "$RECORD" | jq -r .id)
    TYPE=$(echo "$RECORD" | jq -r .type)
    CONTENT=$(echo "$RECORD" | jq -r .content)
    MODEM_IP=$(curl -4 icanhazip.com)

    log "Current Record IP: $CONTENT"
    log "Current Modem IP : $MODEM_IP"

    if [ "$TYPE" = "A" ] && [ "$MODEM_IP" != "$CONTENT" ]; then
        log "IP has changed. Starting DNS update..."
        RESPONSE=$(curl --location --request POST "$API_URL/edit/$DOMAIN/$ID" \
        --header 'Content-Type: application/json' \
        --data-raw '{
            "secretapikey": "'"$SECRET_KEY"'",
            "apikey": "'"$API_KEY"'",
            "type": "A",
            "content": "'"$MODEM_IP"'",
            "ttl": "300"
        }')

        EMAIL_BODY="The IP config has been changed from $CONTENT to $MODEM_IP"
        SUBJECT="DDNS Update: IP Change Detected"

        echo -e "Subject: $SUBJECT\n$EMAIL_BODY" | msmtp -a default andyhoanghuu@gmail.com

        
        log "API Response: $RESPONSE"
    else
        log "No IP change detected. No update needed."
    fi
fi

log "--- Finish DDNS Update ---"

