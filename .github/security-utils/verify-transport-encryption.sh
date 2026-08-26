echo "Verifying transport layer encryption compliance..."

# Targets the discrete public host mappings assigned to internal container gateways
HTTP_PORT=$(docker port secure_frontend 80 2>/dev/null | head -n 1 | awk -F ':' '{print $NF}' | tr -d '\r')
HTTPS_PORT=$(docker port secure_frontend 443 2>/dev/null | head -n 1 | awk -F ':' '{print $NF}' | tr -d '\r')

if [ -z "$HTTP_PORT" ] || [ -z "$HTTPS_PORT" ]; then
    echo "❌ Error: Could not resolve public HTTP (80) or HTTPS (443) ports for container 'secure_frontend'."
    echo ""
    exit 1
fi

echo "Auditing HTTP port: $HTTP_PORT | HTTPS port: $HTTPS_PORT"

# Audits the unencrypted port
HTTP_HOP=$(curl -sI --max-time 5 "http://localhost:$HTTP_PORT")

if [ -z "$HTTP_HOP" ]; then
    echo "❌ Error: Frontend proxy failed to respond to initial connection."
    echo ""
    exit 1
fi

# Ensures the plain HTTP port commands an explicit redirect schema
IS_REDIRECTING=$(echo "$HTTP_HOP" | grep -Ei "^HTTP/[1-2.]+ (301|302|307|308)" && echo "true" || echo "false")
REDIRECT_TARGET=$(echo "$HTTP_HOP" | grep -i "^Location:" | awk '{print $2}' | tr -d '\r')

if [ "$IS_REDIRECTING" = "false" ]; then
    echo "🚨 APPSEC DETECTOR: Cleartext Transmission of Sensitive Information (CWE-319)"
    echo "The communication gateway is serving unencrypted cleartext directly without commanding an HTTPS protocol upgrade."
    echo""
    exit 1
fi

if [[ "$REDIRECT_TARGET" != "https://"* ]]; then
    echo "🚨 APPSEC DETECTOR: Insecure Redirection Target (CWE-319)"
    echo "The server issued a redirect, but routed the client to an unencrypted channel: $REDIRECT_TARGET"
    echo ""
    exit 1
fi

echo "✅ Step 1 Passed: Plain HTTP port safely commands an upgrade to HTTPS."

# Audits the secure endpoint
HTTPS_HEADERS=$(curl -skI --max-time 5 "https://localhost:$HTTPS_PORT")

if [ -z "$HTTPS_HEADERS" ] || echo "$HTTPS_HEADERS" | grep -qE "^HTTP/[1-2.]+ (500|502|503|504)"; then
    echo "🚨 APPSEC DETECTOR: Improper Handling of Exceptional Conditions (CWE-755)"
    echo "The proxy attempted to route traffic to HTTPS, but the secure landing page is crashed or unreachable."
    echo "Check your SSL configurations, certificate paths or upstream application bindings."
    echo ""
    exit 1
fi

# Ensure HSTS is delivered exclusively over this secure session
if ! echo "$HTTPS_HEADERS" | grep -qi "Strict-Transport-Security"; then
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

echo "✅ Step 2 Passed: Secure HTTPS landing page is functional and enforcing HSTS tokens."
echo ""
echo "✅ Transport encryption validated."
echo ""
exit 0