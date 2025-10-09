#!/bin/sh
# docs: https://go-acme.github.io/lego/usage/cli/
# Path: /opt/entrypoint.sh

set -e

INPUT=$1

# Check if incoming command contains flags
if [[ "${1#-}" != "$INPUT" ]] && [[ "$INPUT" != "--certificate-renew" ]];
    then
    set -- lego "$@"
elif [[ -n "$LEGO_ENABLE" ]] && [[ "$LEGO_ENABLE" = "true" ]];
    then
    args=""
    op=""

    # Renew operation on demand which also skip auto-renew when file called directly
    if [[ -n "$INPUT" ]] && [[ "$INPUT" = "--certificate-renew" ]];
        then
        LEGO_RENEW=true
    fi

    # Operation types, the default is `run` subcommand
    if [[ -n "$LEGO_RENEW" ]] && [[ "$LEGO_RENEW" = "true" ]];
        then
        op=" renew"
        if [[ -n "$LEGO_RENEW_DAYS" ]];
            then
            op="$op --days=$LEGO_RENEW_DAYS"
        fi
    else
        op=" run"
    fi

    if [[ -n "$LEGO_PATH" ]];
        then
        args="$args --path=$LEGO_PATH"
    fi

    # Challenge types
    if [[ -n "$LEGO_HTTP" ]] && [[ "$LEGO_HTTP" = "true" ]];
        then
        args="$args --http"
    fi
    if [[ -n "$LEGO_DNS" ]];
        then
        args="$args --dns=$LEGO_DNS"
    fi

    # Term of services
    if [[ "$LEGO_ACCEPT_TOS" = "true" ]];
        then
        args="$args --accept-tos"
    fi

    # General options
    if [[ -n "$LEGO_EMAIL" ]];
        then
        args="$args --email=$LEGO_EMAIL"
    fi
    
    if [[ -n "$LEGO_DOMAINS" ]];
        then
        for domain in $(echo $LEGO_DOMAINS | tr "," " ")
        do 
            args="$args --domains=$domain" 
        done
    fi

    if [[ -n "$LEGO_SERVER" ]] && [[ -n "$LEGO_STAGING" ]] && [[ $LEGO_STAGING = true ]];
        then
        echo "[warn] Staging and server option cannot specified at the same time."
        echo "       Forcing staging option with server --server=https://acme-staging-v02.api.letsencrypt.org/directory"
        LEGO_SERVER="https://acme-staging-v02.api.letsencrypt.org/directory"
    elif [[ -n "$LEGO_STAGING" ]] && [[ $LEGO_STAGING = true ]];
        then
        echo "[warn] Enabling staging with default server"
        LEGO_SERVER="https://acme-staging-v02.api.letsencrypt.org/directory"
    fi

    if [[ -n "$LEGO_SERVER" ]];
        then
        args="$args --server=$LEGO_SERVER"
    else
        args="$args --server="
    fi
    echo $LEGO_SERVER

    if [[ -n "$LEGO_CSR" ]];
        then
        args="$args --csr=$LEGO_CSR"
    fi

    # Additional arguments
    if [[ -n "$LEGO_ARGS" ]];
        then
        args="$args$LEGO_ARGS"
    fi
    set -- lego $args$op

    ## Enable auto-renew only at start up time
    if [[ -z "$LEGO_RENEW" ]] || [[ "$LEGO_RENEW" = "false" ]];
        then
        if [[ "$CERT_AUTORENEW" = "true" ]];
            then
            domain=$(echo $LEGO_DOMAINS | sed 's/;.*//' | sed 's/*.//')
            cert_file=$LEGO_PATH/certificates/_.$domain.crt

            # 1. Run Lego command only if a certificate does not exist for this domain
            if [ -f $cert_file ];
                then
                echo "[info] A certificate file '$cert_file' was found. Command execution skipped."
            else
                echo "[info] Continuing with running the requested command..."
                lego $args$op
            fi

            # 2. Configure the Crontab task and redirect its output to Docker stdout
            echo
            echo "[info] Configuring the certificate auto-renewal Crontab task..."
            declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /container.env
            cmd="SHELL=/bin/bash BASH_ENV=/container.env /opt/lego/renew_certificate.sh > /proc/1/fd/1 2>&1"
            crontab -l | echo "$CERT_AUTORENEW_CRON_INTERVAL $cmd" | crontab -

            # 3. Finally, start the Crontab scheduler and block
            echo "[info] The Crontab task is configured successfully!"
            echo "[info] Waiting for the Crontab scheduler to run the task..."
            echo "[info]   Crontab interval: $CERT_AUTORENEW_CRON_INTERVAL"
            cron -f

            echo "[info]  Stopping the Crontab scheduler..."
            exit
        fi
    fi
fi

exec "$@"