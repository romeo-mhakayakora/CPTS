# LOCAL SECURITY ATHOURITY (LSA)

<figure><img src="../.gitbook/assets/ChatGPT Image Aug 20, 2025, 07_46_56 AM.png" alt="" width="375"><figcaption></figcaption></figure>



&#x20; Local Security Authority (LSA) and  Its Crucial Databases:

### 1.**What is LSA?**

* **Local Security Authority (LSA)** is a core Windows component that enforces security policy on a system.
* Runs as part of **LSASS.exe** (Local Security Authority Subsystem Service).
* Main responsibilities:
  * Validates user logon attempts (local and domain).
  * Manages authentication packages (NTLM, Kerberos, etc.).
  * Creates **access tokens** after logon.
  * Applies audit and security policies.
  * Stores and protects sensitive security information (secrets, cached creds, keys).

***

### 2. **The 3 Crucial Databases Managed by LSA**

#### 🔹 **1. SAM Database**

* **Location:** `HKLM\SAM`
* **Purpose:** Stores local user and group accounts.
* **Contents:**
  * Usernames
  * Password hashes (NTLM/LM)
* **Role for LSA:**
  * LSA queries the SAM to verify **local account logons**.

***

#### 🔹 **2. SECURITY Database**

* **Location:** `HKLM\SECURITY`
* **Purpose:** The main **LSA Database**.
* **Contents:**
  * **Policy Database** (audit policies, account policies, trust info)
  * **Secrets Database** (service passwords, DPAPI keys, RAS/VPN creds)
  * **Cache** (domain logon cache, NL$ secrets)
  * Kerberos keys and encryption keys
* **Role for LSA:**
  * Holds both **rules** (policies) and **sensitive material** (secrets).

***

#### 🔹 **3. SYSTEM Database**

* **Location:** `HKLM\SYSTEM`
* **Purpose:** Stores system configuration and startup information.
* **Special Role in Security:**
  * Contains the **Boot Key (SYSKEY)**.
  * This key is required to **decrypt protected data** in the SAM and SECURITY databases.
* **Role for LSA:**
  * Without SYSTEM’s boot key, LSA cannot access stored password hashes or secrets.

