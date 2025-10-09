#!/bin/ash
# Scripts to renew certificate before expiration run by a crontb

echo "[info] Starting certificate check script..."

# Check for required environment variable
if [[ -z "$LEGO_DOMAINS" ]]; then
    echo "[warn] LEGO_DOMAINS is required, but provided. Nothing happens!"
    exit
fi
if [[ -z "$AUTORENEW_PERIOD" ]]; then
    echo "[warn] AUTORENEW_PERIOD is not provided. Nothing happens!"
    exit
fi

# Find the cert file based on `LEGO_DOMAINS`
# NOTE: The autorenewal feature should work for more than one domain.
for domain in $(echo $LEGO_DOMAINS | tr "," " ")
    do
    cert_file=$LEGO_PATH/certificates/_.$domain.crt

    if [ ! -f $cert_file ]; then
        echo "[warn] The certificate file '$cert_file' was not found. Cancelled!"
        continue
    fi

    end_date=$(openssl x509 -in $cert_file -noout -enddate | sed 's/;.*//' | sed 's/notAfter=//')
    end_date_timestamp=$(date -d "$end_date" +"%s")
    end_date_before_expire=$(date -d "$end_date $AUTORENEW_PERIOD days ago" +"%s")
    current_time=$(date +%s)
    # DEBUG: enable this when testing
    current_time=$(date -d "+90 days" +%s)

    echo "[info] Checking if certificate is closer to expire..."
    echo "           Cert File: $cert_file"
    echo "           End Date: $end_date | End Date Timestamp=$end_date_timestamp"
    echo "           Renew Before: $AUTORENEW_PERIOD day(s)"

    # Checking certificate expiration
    if [ $current_time -lt $end_date_before_expire ]; then
        echo "[info] The certificate is still valid until $end_date. Nothing to do."
        continue
    fi

    # Certificated closer to expire, try to renew it
    echo "[warn] The certificate is closer to expire on $end_date"
    echo "[info] Trying to renew the certificate before expire..."
    echo

    /usr/local/bin/entrypoint.sh --certificate-renew

    echo "[info] The certificate renewal was performed successfully!"
    end_date=$(openssl x509 -in $cert_file -noout -enddate | sed 's/;.*//' | sed 's/notAfter=//')
    end_date_timestamp=$(date -d "$end_date" +"%s")
    echo "           Cert File: $cert_file"
    echo "           End Date: $end_date | End Date Timestamp=$end_date_timestamp"
    echo
done