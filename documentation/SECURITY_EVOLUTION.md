# 📓 Security Evolution Runbook: The Full-Stack AppSec Journey

This document serves as the chronological engineering ledger for this project. It details the step-by-step evolution of
an authentication flow as it progresses through development, static analysis, active exploitation and
eventual remediation.

---

## 📍 Phase 1: The Functional Baseline

### 1. The Architectural State
The initial goal of this phase was purely functional: establish an operational backend routing architecture using
Express.js and a PostgreSQL data store.

---

## 📍 Phase 2: Shifting Security Left

### 1. The Strategy
Before deploying this infrastructure to a production zone, an automated security gate was integrated into
the **GitHub Actions workflow** utilising **Semgrep**. This tool acts as an automated code reviewer, analysing
the abstract structure of our logic before the build step finishes.

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