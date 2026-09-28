---
layout:
  width: default
  title:
    visible: true
  description:
    visible: true
  tableOfContents:
    visible: true
  outline:
    visible: true
  pagination:
    visible: true
  metadata:
    visible: true
  tags:
    visible: true
  actions:
    visible: true
  anchors:
    visible: true
---

# LSA

<figure><img src="../../.gitbook/assets/ChatGPT Image Aug 20, 2025, 07_46_56 AM.png" alt=""><figcaption></figcaption></figure>

## 🛡️ Local Security Authority (LSA) and Its Databases

The **Local Security Authority (LSA)** is a core Windows security component responsible for:

* Handling user logons and authentication
* Maintaining security policies and privileges
* Managing secrets (passwords, cached credentials)
* Issuing access tokens to authenticated sessions

LSA **does not access registry hives directly** for sensitive data; it uses **protected communication channels and APIs** to interact with its databases.

***

### 1. Crucial Databases Managed by LSA

LSA interacts with three main databases:

| Database     | Hive Location   | Purpose                                                                                       |
| ------------ | --------------- | --------------------------------------------------------------------------------------------- |
| **SAM**      | `HKLM\SAM`      | Stores local user and group accounts + password hashes                                        |
| **SECURITY** | `HKLM\SECURITY` | Stores system security policies, secrets (cached passwords, VPN credentials), and logon cache |
| **SYSTEM**   | `HKLM\SYSTEM`   | Provides Boot Key (SYSKEY) to decrypt SAM and SECURITY contents                               |

***

### 2. Key Components Inside LSASS

#### **LSASS** – Local Security Authority Subsystem Service

* **What it is:**
  * LSASS is a **core Windows system process** (`lsass.exe`) that runs in the background.
  * It implements the **Local Security Authority (LSA)** and manages security-related operations on the system.
* **Main responsibilities:**
  * Handles **user logons and authentication**.
  * Maintains **security policies** (password rules, audit policies, trust relationships).
  * Stores **and protects secrets** (cached passwords, service account credentials).
  * Issues **access tokens** for processes after authentication.
* **Key point:**
  * LSASS is the **central authority** that coordinates access to SAM, SECURITY, and SYSTEM.
  * It is highly privileged and protected; killing LSASS will crash Windows.

***

#### **LSA** – Local Security Authority Module

* **What it is:**
  * A module running inside LSASS.
  * Responsible for **processing logon requests, authentication, policy enforcement, and secret management**.
* **Role:**
  * Acts as the **decision-maker** for authentication and security policy enforcement.
  * Communicates with SAM, SECURITY, and SYSTEM to fetch required data securely.

***

#### **SAMSRV** – Security Account Manager Service

* **What it is:**
  * A **service inside LSASS** that specifically handles the **SAM database (`HKLM\SAM`)**.
  * Think of it as a **gateway or server** enforcing secure access to local user and group account data.
* **Main responsibilities:**
  * Responds to **RPC requests** from LSA or other Windows components.
  * Provides **read-only or read-write access** to user account info (password hashes, user IDs, group membership).
  * Enforces **security boundaries** so no process can read SAM directly.
* **Key point:**
  * SAMSRV is **not a standalone process**; it lives inside LSASS.
  * Communication with SAMSRV is always **via RPC** (or LRPC locally) — never direct registry access.

***

#### Analogy:

* LSASS = **Security HQ** of Windows
* LSA = **the security officer inside HQ** who processes requests
* SAMSRV = **the secure vault manager** controlling access to user account data (SAM)

***

### 3. How LSA Communicates with the Databases

#### 3.1 Communication with **SAM Database** (`HKLM\SAM`)

* **Purpose:** Verify local logons by checking password hashes.
* **How:**
  * LSA communicates with **SAMSRV** inside LSASS.
  * Instead of reading registry values directly, LSA calls **functions exposed by SAMSRV**.
  * This communication is carried out using **Local Remote Procedure Calls (LRPC)**.
  * Example functions: `SamIConnect`, `SamrOpenDomain`, `SamrGetInformationUser`.
* **Why not direct access?**
  * Password hashes are too sensitive to expose directly.
  * RPC provides a controlled interface with authentication, auditing, and access checks.

👉 So: **LSA → SAM = RPC (via LRPC) to SAMSRV**

***

#### 3.2 Communication with **SECURITY Database** (`HKLM\SECURITY`)

* **Purpose:** Store and manage **system policies** (like audit policies) and **secrets** (cached passwords, service account credentials).
* **How:**
  * LSA itself manages this database.
  * Communication is handled internally through **LSA APIs**, not RPC.
  * Key APIs: `LsaOpenPolicy`, `LsaQueryInformationPolicy`, `LsaStorePrivateData`, `LsaRetrievePrivateData`.
  * Secrets stored here are encrypted; decryption only happens inside LSASS.

👉 So: **LSA → SECURITY = Internal APIs (direct calls within LSASS)**

***

#### 3.3 Communication with **SYSTEM Database** (`HKLM\SYSTEM`)

* **Purpose:** Provide the **Boot Key (SYSKEY)** needed to decrypt sensitive data in SAM and SECURITY.
* **How:**
  * LSA retrieves values from SYSTEM hive using **Windows registry APIs**.
  * It derives the Boot Key → initializes cryptographic routines.
  * No RPC involved.

👉 So: **LSA → SYSTEM = Registry APIs + Cryptographic derivation**

***

### 4. What is RPC? (Beginner-Friendly)

**Remote Procedure Call (RPC)** lets one program **call a function inside another program** as if it were local, even if the other program is in a different process or computer.

* **Without RPC:**
  * Program A would need to know the internal details of Program B to execute a function.
  * It would need to handle messaging, data formats, access control — very complex.
* **With RPC:**
  * Program A simply calls a function like `CheckPassword()`.
  * RPC handles:
    * Packaging the function name and parameters
    * Sending them to Program B
    * Executing the function
    * Returning the result to Program A
    * Enforcing authentication and access control
* **Analogy:**
  * Calling a waiter in a restaurant — you place an order, the kitchen (Program B) prepares it, and the waiter brings it back. You don’t enter the kitchen yourself.

***

### 5. What is LRPC (Local RPC)?

* **LRPC** is an optimized version of RPC for **processes on the same machine**.
* Uses **shared memory and local IPC** instead of network transport.
* Benefits:
  * Faster than normal RPC
  * Still enforces security boundaries, authentication, and auditing
* Example: LSA calling **SAMSRV** inside LSASS uses LRPC.
  * To LSA, it looks like a normal function call.
  * Behind the scenes, LRPC handles communication securely and efficiently.

***

### Communication Flow Overview

<figure><img src="../../.gitbook/assets/ChatGPT Image Aug 20, 2025, 07_46_56 AM.png" alt="" width="375"><figcaption></figcaption></figure>

***

### 7. Summary

* **LSASS** = central Windows security process
* **LSA** = module inside LSASS handling authentication, policy enforcement, and secret management
* **SAMSRV** = secure service inside LSASS managing access to SAM
* **RPC/LRPC** = mechanism for safe communication with SAMSRV
* **SECURITY & SYSTEM** = accessed via internal APIs and registry, decrypted using Boot Key

