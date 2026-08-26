# 📓 Security Evolution Runbook: The Full-Stack AppSec Journey

This document serves as the chronological engineering ledger for this project. It details the step-by-step evolution of
an authentication portal as it progresses through development, static analysis, active exploitation and
eventual remediation.

---

## 📍 Phase 1: The Functional Baseline

### The Architectural State
The initial milestone focused entirely on building a working full-stack authentication portal. The application pairs
a responsive React frontend with an Express.js backend API, backed by a containerised PostgreSQL database.

### The Focus on Functional Success
Development was driven by standard product requirements: an intuitive interface, successful account onboarding and
accurate login verification.

-   **The Frontend:** A polished login UI that handles client-side form states and securely dispatches HTTP requests.
-   **The Backend:** Direct route handlers that extract user-provided credentials from the request body to execute
  immediate database lookups and storage.

**The Engineering Reality:**
At this stage, the project is a functional success. It passes standard manual testing flawlessly: users can
successfully register an account and log in with their created credentials.

---

## 📍 Phase 2: Shifting Security Left

### The Strategy
To establish baseline visibility over code quality, an automated security gate was integrated into
the **GitHub Actions workflow** utilising **Semgrep**. This tool acts as an automated code reviewer, analysing
the structure of my source code on every push. Its purpose is to act as a preventative guardrail, ensuring any
future updates or feature branches are automatically checked for structural risks before they can be merged.

### The SAST Pipeline Results
Upon pushing the initial baseline code, the pipeline halted execution, reporting
**4 blocking findings** across the active authentication routes.

![Semgrep pipeline results](images/semgrep-results.png)

```text
┌─────────────────┐
│ 4 Code Findings │
└─────────────────┘
    backend/server.js
   ❯❯❱ github.workflows.appsec-critical-sqli (CWE-89)
   ❯❯❱ github.workflows.appsec-high-unhashed-credential-storage (CWE-256)
```

**What this output means in plain English:**
-   Semgrep identified that lines `40-43` (registration) and lines `59-62` (login) were feeding unvalidated
    text inputs straight into the database query engine (`pool.query`).
-   Because the data flowing to the `users` table didn't pass through a hashing function, both rules fired
    simultaneously on both routes.

### Static Remediation & The Overfitting Discovery
To clear the blocking findings, the backend code was structurally hardened by replacing raw string concatenation with
native node-postgres parameterised array bindings (`$1, $2`) and implementing asynchronous `bcrypt` password stretching
with a cost factor of `10` rounds.

However, upon pushing the secure code, the SAST pipeline continued to fail, continuing to flag
the secure lines as vulnerabilities.

#### The Root Cause
An audit of the custom security ruleset revealed **Signature-Based Overfitting**. My original rule that checked for
credentials being hashed looked strictly for a specific text formatting style. Since my patch isolated the data
from the SQL command string, the pattern-matcher failed to understand the code and threw a false positive.

#### The Rule Architecture Shift
To build a resilient security gate, the rule was refactored away from checking rigid text styles toward a
universal tracking model called **Dataflow Taint Tracking**.

Instead of policing how a developer formats their code, the security engine now operates like a digital dye test,
tracking the state of information as it flows through the system:

```text
                  ┌───► [ Hashing Function ] ───► (Cleaned & Approved) ───► [ Safe Database Query ] (BUILD PASSES)
                  │
[ Raw User Input ]┤
 (Untrusted Data) │
                  └───► [ Raw/Direct Path ] ────► (Unhashed Input) ────► [ Security System Blocks Deploy ]  (BUILD FAILS)
```

#### How the Automated Gate Evaluates Code Now:
1. **The Source:** Any information entering the application via an incoming web request is automatically flagged as
   "untrusted."
2. **The Sanitiser:** If that untrusted information passes through an approved cryptographic hashing function,
   the system washes away the flag and marks the data as "safe."
3. **The Sink:** The system continuously guards the database. If any data attempts to update a user registry without
   passing through the sanitiser first, the build is blocked.

Because my updated logic properly hashes passwords, the data engine clears the pipeline instantly. This eliminated
the false positives permanently while ensuring future code additions remain perfectly secure.

![Semgrep pipeline results after patches](images/semgrep-results-post-patch.png)

---

## 📍 Phase 3: Defensive Emulation (The Kali Offensive)

### The Objective
To manually test the running application just like a real malicious actor would over the network. While my
previous security checks (SAST) looked at the code files line-by-line, this phase looks at how the application behaves
when it is turned on and plugged into the network.

### The Edge Routing Hurdle 
The application runs inside a containerised sandbox. The original frontend client code hardcoded backend data requests
to http://localhost:5000. While this works on a local machine, launching the application over a
VirtualBox network bridge or external internet connection causes the web client to return internal server errors.

### Edge Proxy Architecture Implementation
To expose the application safely to my Kali attacker machine, an industry-standard Nginx Reverse Proxy container layer
was introduced. The frontend code was refactored to use environment-relative routing paths (/api/login) and
the Nginx configuration handles edge routing abstraction:

```text
[ Internet User Browser ] ───► (Host Port 3000) ───► [ Nginx Server (frontend-ui) ]
                                                               │
                             ┌─────────────────────────────────┴─────────────────────────────────┐
                             ▼                                                                   ▼
                 Static Web Content Request                                          Data Transaction Route (`/api/`)
                 Served directly from static build                                   Proxied via Docker Internal Bridge Network
                                                                                     `proxy_pass http://backend-api:5000;`

```

By presenting both the UI and the API under the exact same hostname and port context, we eliminate
client-side CORS issues and isolate the Express backend server from direct public exposure.

### The Attack Sequence

#### Step 1: Scanning for Open Doors (The Port Scan)
An aggressive network reconnaissance scan was executed using `Nmap` from the attacking Kali Linux VM  to audit
the networks.

-   **What I found:** The scan showed that three doors are wide open: Port `3000` (our main web server),
    Port `5000` (our Express backend server), and Port `5432` (our database server).
-   **The Consequence:** While Port 3000 is supposed to be open so users can view the website, leaving our raw backend
    and database ports open to the public internet allows anyone to bypass our security guards and connect directly to
    the raw data servers.

```text
PORT     STATE SERVICE    VERSION
3000/tcp open  http       nginx 1.25.5
|_http-server-header: nginx/1.25.5
|_http-title: frontend
5000/tcp open  http       Node.js Express framework
|_http-title: Error
|_http-cors: HEAD GET POST PUT DELETE PATCH
5432/tcp open  postgresql PostgreSQL DB
```

#### Step 2: Guessing Hidden Pathways (The Dirb Attack)
I downloaded a Metasploit wordlist used a tool called **Dirb** to automatically guess thousands of common folder and
pathway names against the servers to see if any hidden files were accidentally left public.

-   **What we found:** Dirb successfully discovered the diagnostic path: `/health`
-   **The Consequence:** An attacker can bypass the Nginx proxy layer and scrape diagnostic metrics to plan a
    deeper attack.

#### Step 3: Sniffing Network Traffic (The Wireshark Attack)
I launched **Wireshark**, a standard network capture utility that records all data packets travelling through
the network. We monitored the traffic while a test user logged into the portal.

-   **What we found:** Wireshark intercepted the network packet and instantly printed the raw login details in
    plaintext:
    ```json
    {"username": "user", "password": "password123"}
    ```
-   **The Consequence:** This is a high-risk vulnerability. Because the current website runs on standard,
    unencrypted `http://` instead of secure `https://`, every password moves across the network in plaintext.
    If an attacker gets onto the same local network (like a shared office network or a public wifi hotspot)
    or if an insider threat monitors our traffic, they can steal user passwords instantly.

#### The Takeaway:
This highlights the vast gulf between defensive software coding and secure operational deployment. While our
source code successfully neutralises application-layer exploits (SQL injection and XSS),
the infrastructure orchestration introduces fatal entry points, allowing attackers to target backend servers and
databases directly.

---

## 📍 Phase 4: Runtime Operational Validation

### The Strategy

Phase 3 used an offensive attacker mindset to discover exposed network backdoors. Phase 4 builds those discoveries into
my continuous engineering defences.

To catch environment flaws early, I integrated an automated DAST (Dynamic Application Security Testing) layer into
the workflow execution stack. Rather than leaving network-layer vulnerabilities unmonitored until a
formal penetration test or manual audit occurs, this pipeline builds a permanent programmatic safety net.
It automatically launches the environment, waits for a healthy state and inspects the system boundaries before
any code can deploy.

### Designing Future-Proof Guardrails
Recall the issue with overfitting when the SAST rules were first designed. If the testing scripts were hardcoded to
look strictly for ports 5000 and 5432, or forced them to scan an exact address like http://localhost:3000,
the pipeline would eventually break down as our architecture scaled.

To build a resilient testing gate, I designed the security utilities to use a dynamic, declarative model that queries
the Docker Runtime Daemon:

```text
                               ┌───► [ Query Image Metadata ] ───► Auto-discover all exposed ports ───► Test host loopback
                               │
[ Trigger DAST Pipeline Sweep ]┤
                               │
                               └───► [ Query Live Gateway ] ────► Resolve bound Nginx port ─────────► Test encryption headers
```

#### How the Automated Gate Evaluates Infrastructure:
1. **Dynamic Port Harvesting:** Instead of checking fixed port lists, the perimeter script reads
   container metadata at runtime. If a developer maps a new database or microservice and accidentally exposes it,
   the script dynamically discovers the port and audits the connection.
2. **Adaptive Endpoint Targeting:** The transport script queries Docker to identify exactly which external port
   the Nginx front door is listening on. It automatically targets its connection checks whether it is evaluating
   HTTP staging environments or active HTTPS encryption rules.
3. **Cumulative Log Gathering:** Individual scripts process security errors silently without
   throwing early exit crashes. This ensures all vulnerabilities that caused the pipeline to fail are shown.

### The DAST Pipeline Results
With the current vulnerabilities identified, the pipeline halted, throwing explicit alerts regarding configuration flaws
and unencrypted web traffic.

### Infrastructure Remediation
#### Reducing the Attack Surface
To ensure no backend ports were exposed over the internet, the root Docker configuration file was updated along with the
frontend's Vite configuration file. After this was done, the DAST pipeline indicated that the network permimeter was
isolated.

However, during local integration verification, an unexpected security paradox appeared: running an `Nmap` scan from a
Kali Linux VM hosted within VirtualBox flagged port `5432/tcp` (PostgreSQL) as open.

```text
PORT     STATE    SERVICE    VERSION
3000/tcp open     http       nginx 1.25.5
|_http-server-header: nginx/1.25.5
|_http-title: frontend
5000/tcp filtered upnp
5432/tcp open     postgresql PostgreSQL DB
```

Initially, this hinted at a dangerous false negative inside my automated DAST suite. The script reported the boundary was secure, yet an attacking OS could see the data layer.

This friction forced a critical moment of self-education regarding network isolation and the necessity of
thorough multi-layered validation:
1. **The Investigation:** To prove the threat model, I introduced an external validation layer by scanning the host from
   a completely separate physical machine on the local network. This external scan correctly reported the port as
   filtered.

    ```text
    PORT     STATE    SERVICE    VERSION
    3000/tcp open     tcpwrapped
    5000/tcp filtered upnp
    5432/tcp filtered postgresql
    ```

2. **The Discovery:** This taught me how virtualisation platforms interact at the kernel layer. When Docker establishes
   a virtual bridge network, it lives natively on the host operating system kernel. Since VirtualBox also binds its
   host-only or bridged adapters to that same kernel, the host machine quietly routes traffic internally between
   the local VM and the local Docker network, bypassing external firewall realities.
3. **The Engineering Takeaway:** The DAST pipeline script was operating with accuracy for its target deployment context.
   However, relying blindly on a single testing vantage point is dangerous. True security engineering requires
   verifying results outside of local hypervisor bubbles before writing off a validation failure.

#### Protecting against denial-of-service (DoS) attacks
The automated DAST scan pointed out that the `/api/login` and `/api/register` had no restriction on request frequency.
This meant an attacker could easily run an automated password-guessing script
(a brute-force attack) or spam the system until the application crashed entirely.

To fix this, I updated the Nginx reverse proxy configuration to include a traffic throttle. By creating a
shared memory area, Nginx now tracks incoming request frequencies based on
the visitor's IP address.

I applied a strict rule to the authentication routes: users are allowed a steady baseline of 5 requests per second,
with a small "burst" buffer of 10 requests to handle normal, fast page clicks and internet realities
(like a browser sending multiple requests at the exact same millisecond). If a script tries to bypass these rules and
floods the authentication endpoints, Nginx steps in immediately, cuts off the traffic and returns a
clean `HTTP 429 Too Many Requests` error before the spam can ever touch or slow down the backend server.

#### Implementing transport-level encryption
To be added.