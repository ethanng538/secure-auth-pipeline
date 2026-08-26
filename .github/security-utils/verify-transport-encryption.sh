echo "Verifying transport layer encryption compliance..."

# Fetch only the headers from the Nginx proxy gateway
HEADERS=$(curl -sI http://localhost:3000)

# Assert that the server forces a secure protocol redirect or returns an HSTS header
if echo "$HEADERS" | grep -qi "Strict-Transport-Security"; then
    echo "✅ Transport encryption validated. Security headers present."
    exit 0
else
    echo "🚨 APPSEC DETECTOR: Cleartext Transmission of Sensitive Information (CWE-319)"
    echo ""
    echo "The communication gateway transmits transaction payloads over unencrypted HTTP channels."
    echo "An actor with network line-of-sight can capture traveling packets to steal usernames,"
    echo "passwords and active session identifiers in plaintext."
    echo ""
    echo "Remediation: Configure Nginx to reject port 80 connections, bind TLS certificates"
    echo "and upgrade transmission requirements to HTTPS."
    exit 1
fi