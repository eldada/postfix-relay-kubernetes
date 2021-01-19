#!/bin/sh

TX_SMTP_RELAY_HOST=${TX_SMTP_RELAY_HOST?Missing env var TX_SMTP_RELAY_HOST}
TX_SMTP_RELAY_MYHOSTNAME=${TX_SMTP_RELAY_MYHOSTNAME?Missing env var TX_SMTP_RELAY_MYHOSTNAME}
TX_SMTP_RELAY_USERNAME=${TX_SMTP_RELAY_USERNAME?Missing env var TX_SMTP_RELAY_USERNAME}
TX_SMTP_RELAY_PASSWORD=${TX_SMTP_RELAY_PASSWORD?Missing env var TX_SMTP_RELAY_PASSWORD}
TX_SMTP_RELAY_NETWORKS=${TX_SMTP_RELAY_NETWORKS:-10.0.0.0/8,127.0.0.0/8,172.17.0.0/16,192.0.0.0/8}

echo "==============================="
echo "===  Setting configuration  ==="
echo "TX_SMTP_RELAY_HOST        -  ${TX_SMTP_RELAY_HOST}"
echo "TX_SMTP_RELAY_MYHOSTNAME  -  ${TX_SMTP_RELAY_MYHOSTNAME}"
echo "TX_SMTP_RELAY_USERNAME    -  ${TX_SMTP_RELAY_USERNAME}"
echo "TX_SMTP_RELAY_PASSWORD    -  (hidden)"
echo "TX_SMTP_RELAY_NETWORKS    -  ${TX_SMTP_RELAY_NETWORKS}"
echo "POSTFIX_EXTRA_CONFIG      -  ${POSTFIX_EXTRA_CONFIG}"
echo "==============================="

# Write SMTP credentials
echo "${TX_SMTP_RELAY_HOST} ${TX_SMTP_RELAY_USERNAME}:${TX_SMTP_RELAY_PASSWORD}" > /etc/postfix/sasl_passwd || exit 1
postmap /etc/postfix/sasl_passwd || exit 1
rm /etc/postfix/sasl_passwd || exit 1

# Set configurations
postconf 'smtp_sasl_auth_enable = yes' || exit 1
postconf 'smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd' || exit 1
postconf 'smtp_sasl_security_options =' || exit 1

# These are required
postconf "relayhost = ${TX_SMTP_RELAY_HOST}" || exit 1
postconf "myhostname = ${TX_SMTP_RELAY_MYHOSTNAME}" || exit 1

# Set allowed networks
postconf "mynetworks = ${TX_SMTP_RELAY_NETWORKS}" || exit 1

# http://www.postfix.org/COMPATIBILITY_README.html#smtputf8_enable
postconf 'smtputf8_enable = no' || exit 1

# This makes sure the message id is set. If this is set to no dkim=fail will happen.
postconf 'always_add_missing_headers = yes' || exit 1

# Add extra configuration directly to /etc/postfix/main.cf
if [ -n "${POSTFIX_EXTRA_CONFIG}" ]; then
    echo -e "${POSTFIX_EXTRA_CONFIG}" >> /etc/postfix/main.cf || exit 1
fi

# Have supervisord run and control postfix (/etc/supervisor.d/postfix.ini)
echo
echo "===================================="
echo "=== Starting the postfix service ==="
echo "===================================="
/usr/bin/supervisord -n
