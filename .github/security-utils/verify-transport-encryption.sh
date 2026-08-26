echo "Verifying transport layer encryption compliance..."

# Finds what public host port secure_frontend is using
GATEWAY_PORT=$(docker port secure_frontend 80 | head -n 1 | grep -oE '[0-9]+$')

# Fallback block if the container isn't listening on port 80 (e.g. it's already on 443)
if [ -z "$GATEWAY_PORT" ]; then
    GATEWAY_PORT=$(docker port secure_frontend 443 | head -n 1 | grep -oE '[0-9]+$')
fi

# Query the dynamically resolved gateway endpoint
HEADERS=$(curl -sI http://localhost:$GATEWAY_PORT)

# Assert that the server forces a secure protocol redirect or returns an HSTS header
if echo "$HEADERS" | grep -qi "Strict-Transport-Security"; then
    echo "✅ Transport encryption validated. Security headers present."
    echo ""
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
    echo ""
    exit 1
fi