#!/usr/bin/env bash

# .env file content
#DOMAIN=
#SECRET_KEY=
#API_KEY=

BASEDIR=$(dirname "$0")
ENV_PATH="$BASEDIR"/.env

export $(grep -v '^#' "$ENV_PATH" | xargs)

RECORD=$(curl --location --request POST "https://porkbun.com/api/json/v3/dns/retrieve/$DOMAIN" \
--header 'Content-Type: application/json' \
--data-raw '{
    "secretapikey": "'"$SECRET_KEY"'",
    "apikey": "'"$API_KEY"'"
}' | jq -r .records[0])

if [ "$RECORD" = "null" ]
then
      echo "Something went wrong!"
else
      ID=$(echo "$RECORD" | jq -r .id);
      TYPE=$(echo "$RECORD" | jq -r .type);
      CONTENT=$(echo "$RECORD" | jq -r .content);

      MODEM_IP=$(curl -4 icanhazip.com)

      if [ "$TYPE" = "A" ] && [ "$MODEM_IP" != "$CONTENT" ]
      then
            curl --location --request POST "https://porkbun.com/api/json/v3/dns/edit/$DOMAIN/$ID" \
            --header 'Content-Type: application/json' \
            --data-raw '{
            	"secretapikey": "'"$SECRET_KEY"'",
              "apikey": "'"$API_KEY"'",
              "type": "A",
            	"content": "'"$MODEM_IP"'",
            	"ttl": "300"
            }'
      fi
fi

