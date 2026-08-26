# Full-Stack AppSec Lifecycle & Exploit Emulation Lab

> ### 📢 The Self-Directed Learning Journey
> This repository documents a hands-on learning project engineered to practicalise application security concepts.
> Instead of just reading theory, I built a standard authentication page and systematically moved it through a 
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
    low-hanging fruit before deployment.
-   **The Guardrail:** Integrated a **GitHub Actions pipeline** utilising the
    **Semgrep AST (Abstract Syntax Tree) engine**.
-   **The Result:** The pipeline successfully scans the repository on every push, automatically identifying and
    blocking code containing the SQL injection (`CWE-89`) and plaintext storage (`CWE-256`) vulnerabilities.

### 📍 Phase 3: Defensive Emulation (Attacking the Frontend via Kali Linux)
-   **Objective:** Go beyond source code scanning. Step into the shoes of an attacker to verify runtime weaknesses.
-   **The Attack Vector:** Booting up an isolated local container and using **Kali Linux toolchains**
  (Nmap, Dirb, Wireshark) to evaluate the attack surface and find vulnerabilities.

### 📍 Phase 4: Runtime Operational Validation (DAST Evolution)
-   **Objective:** Use the data gathered from active exploitation to 
-   **The Defence:** 

---

## 🏢 System & Network Architecture

This application simulates a standard authentication workflow, entirely containerised and split into
isolated virtual routing zones to enforce a strict **Defence-in-Depth** model:

```text
  [ frontend-ui ]                  [ backend-api ]                  [ postgres-db ]
 (Port 3000 -> 80)                 (Port 5000:5000)                (Internal Port 5432)
         │                                │                                 │
         └─── via frontend-api network ───┘                                 │
                                          └─── via api-db network ──────────┘
```

👉 **To read my complete plain-English risk translations, active terminal attack payloads and phase-by-phase code logs,
view the:** [Security Evolution Runbook](./documentation/SECURITY_EVOLUTION.md)

---

## 🚀 One-Command Local Initialisation

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

*   **Frontend UI Interface:** Accessible locally at `http://localhost:3000`
*   **Backend API Gateway:** Accessible locally at `http://localhost:5000`

To tear down the environment and purge temporary storage networks cleanly, execute:
```bash
docker compose down -v
```
</details>