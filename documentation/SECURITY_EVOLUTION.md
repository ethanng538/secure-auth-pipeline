# 📓 Security Evolution Runbook: The Full-Stack AppSec Journey

This document serves as the chronological engineering ledger for this project. It details the step-by-step evolution of
an authentication portal as it progresses through development, static analysis, active exploitation and
eventual remediation.

---

## 📍 Phase 1: The Functional Baseline

### 1. The Architectural State
The initial milestone focused entirely on building a working full-stack authentication portal. The application pairs
a responsive React frontend with an Express.js backend API, backed by a containerised PostgreSQL database.

### 2. The Focus on Functional Success
Development was driven by standard product requirements: an intuitive interface, successful account onboarding and
accurate login verification.

*   **The Frontend:** A polished login UI that handles client-side form states and securely dispatches HTTP requests.
*   **The Backend:** Direct route handlers that extract user-provided credentials from the request body to execute immediate database lookups and storage.

**The Engineering Reality:**
At this stage, the project is a functional success. It passes standard manual testing flawlessly: users can
successfully register an account and log in with their created credentials.

---

## 📍 Phase 2: Shifting Security Left

### 1. The Strategy
To establish baseline visibility over code quality, an automated security gate was integrated into
the **GitHub Actions workflow** utilising **Semgrep**. This tool acts as an automated code reviewer, analysing
the structure of our source code on every push. Its purpose is to act as a preventative guardrail, ensuring any
future updates or feature branches are automatically checked for structural risks before they can be merged.

### 2. The Pipeline Results
Upon pushing the initial baseline code, the pipeline instantly halted execution, reporting
**4 blocking findings** across our active authentication routes.

![Semgrep Pipeline Results](images/semgrep-results.png)

```text
┌─────────────────┐
│ 4 Code Findings │
└─────────────────┘
    backend/server.js
   ❯❯❱ github.workflows.appsec-critical-sqli (CWE-89)
   ❯❯❱ github.workflows.appsec-high-unhashed-credential-storage (CWE-256)
```

**What this output means in plain English:**
- Semgrep identified that lines `40-43` (registration) and lines `59-62` (login) were feeding unvalidated
  text inputs straight into the database query engine (`pool.query`).
- Because the data flowing to the `users` table didn't pass through a hashing function, both rules fired simultaneously
  on both routes.

---

## 📍 Phase 3: Defensive Emulation (The Kali Offensive)

### 1. The Objective
Discover runtime vulnerabilities that SAST struggles to detect to inform phase 4.

### 2. The Attack Sequence
To be added.

### 3. The Exploit Confirmation
To be added.

---

## 📍 Phase 4: Runtime Operational Validation

To be added.