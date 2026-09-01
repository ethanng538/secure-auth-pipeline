# Full-Stack AppSec Lifecycle & Exploit Emulation Lab

> ### 📢 The Self-Directed Learning Journey
> This repository documents a hands-on learning project engineered to practicalise application security concepts.
> Going beyond theory, I built a standard authentication page and systematically moved it through a 
> **four-phase security lifecycle**: writing the initial code, integrating automated source-code gates (SAST),
> simulating real-world attacks via Kali Linux and validating runtime defences (DAST).

***

## 🗺️ My Technical Evolution Roadmap

```text
[Phase 1: Build Core App] ──> [Phase 2: Establish SAST] ──> [Phase 3: Kali Offensive] ──> [Phase 4: Implement DAST]
   Basic Form Auth              Automated Pipeline Guard          Exposed Port Attacks           Active Runtime Defence
```

### 📍 Phase 1: The Functional Baseline (The Initial Login Page)
-   **Objective:** Build a responsive full-stack authentication portal using React (Tailwind CSS) and an Express.js API
    talking to a Dockerised PostgreSQL server.
-   **Security Posture:** Plaintext storage and dynamic, string-concatenated queries are used to establish a
    baseline for testing.

### 📍 Phase 2: Shifting Security Left (Automated SAST Guardrails)
-   **Objective:** Implement automated static scanning to see how modern development teams catch
    low-hanging fruit before deployment and embed automated guardrails into future development.
-   **The Guardrail:** Integrated a **GitHub Actions pipeline** utilising the
    **Semgrep AST (Abstract Syntax Tree) engine**.
-   **The Result:** The pipeline successfully scans the repository on every push, automatically identifying and
    blocking code containing the SQL injection (`CWE-89`) and plaintext storage (`CWE-256`) vulnerabilities.

### 📍 Phase 3: Defensive Emulation (Attacking the Frontend via Kali Linux)
-   **Objective:** Go beyond source code scanning. Step into the shoes of an attacker to verify runtime weaknesses.
-   **The Attack Vector:** Booting up an isolated local container and using **Kali Linux toolchains**
  (Nmap, Dirb, Wireshark) to evaluate the attack surface and find vulnerabilities.

### 📍 Phase 4: Runtime Operational Validation (DAST Evolution)
-   **Objective:** Translate findings from active exploitation into automated runtime guardrails, engineering a
    resilient network perimeter and traffic throttling system.
-   **The Guardrail:** Extended the existing GitHub Actions pipeline by incorporating custom Docker-native validation
    utilities paired with the **OWASP ZAP Automation Framework**.
-   **The Result:** The automated checks dynamically block exposed backend ports, verify protection against brute-force
    vectors and enforce secure, encrypted web connections to protect credentials in transit.

---

## 🏢 System & Network Architecture

This application simulates a standard authentication workflow. It is entirely containerised and split into
isolated virtual routing zones to enforce strict network segmentation and the principle of least privilege:

```text
       [ frontend-ui ]                 [ backend-api ]                  [ postgres-db ]
      (Port 3000 -> 80)             (Internal Port 5000)             (Internal Port 5432)
      (Port 3443 -> 443)                     │                                 │
              │                              │                                 │
              └─── via frontend-api network ─┴┘                                │
                                             └──────── via api-db network ─────┘
```

👉 **To read my complete plain-English risk translations, active terminal attack payloads and phase-by-phase code logs,
view the:** [Security Evolution Runbook](./documentation/SECURITY_EVOLUTION.md)

---

## 🚀 Local Initialisation

Thanks to Docker orchestration, reviewers can spin up this entire multi-tier environment independently on any
operating system without installing local database servers.

<details>
<summary><b>🛠️ Click to expand Engineer-Facing Installation & Launch Instructions</b></summary>

### Prerequisites
Ensure your host development machine has **Docker Desktop** installed and actively running.

### Initialisation Sequence

1. **Clone the Project Workspace**
   ```bash
   git clone <your-repository-url>
   cd secure-auth-pipeline
   ```

2. **Supply Environmental Variables**\
   Create a file named `.env` in the root directory (alongside `docker-compose.yml`) to define your local, non-secret container variables:
   ```env
   DB_USER=admin_user
   DB_PASSWORD=super_secure_password
   DB_NAME=secure_auth_lab
   ```

3. **Pre-Flight Infrastructure Check**\
   Verify your local Docker daemon is active and responding to commands before launching the stack:
   ```bash
   docker info
   ```

4. **Launch the Container Cluster**
   ```bash
   docker compose up --build
   ```

*   **Frontend UI Interface:** Accessible locally at `https://localhost:3443`

#### ⚠️ A Note on Local HTTPS (Browser Warnings)
Since this lab uses locally generated self-signed certificates to demonstrate transit encryption without a paid domain,
your web browser will throw a standard security warning when you visit `https://localhost:3443`.

-   **Why this happens:** Browsers naturally alert you when a certificate isn't signed by a public
    Certificate Authority.
-   **How to proceed:** This is expected behaviour for an isolated local environment. You can safely bypass the warning
    by clicking "Advanced" and selecting "Continue" (or words to that effect) to see the application in action.

To tear down the environment and purge temporary storage networks cleanly, execute:
```bash
docker compose down -v
```
</details>