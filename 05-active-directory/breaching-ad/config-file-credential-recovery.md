# Credential Recovery from Configuration Files

> [⬅ AD Domain](../README.md) | [📁 Breaching AD](./README.md) | [🏠 Dashboard](../../README.md)

| HTB Progress | Notes | Practical Labs | CPTS Confidence |
|:------------:|:-----:|:--------------:|:---------------:|
| — | Started | — | — |

**Status:** 🔄 In Progress

---

## 📌 Concepts

### 1. Why configuration files matter post-breach

- Once you have a foothold on any host inside a network, **configuration files are a primary loot target**.
- Many applications and services must authenticate to the domain during both installation and runtime. Those credentials have to be stored somewhere, and that somewhere is almost always a config file, database, or registry key — often with weak or well-known encryption, or in plaintext.
- This isn't a niche technique. It's a **standard post-exploitation step** that should be part of every host-level methodology.

### 2. Categories of config files worth targeting

| Category | Examples |
|---|---|
| **Web application config files** | `web.config`, `.env`, `database.yml`, `settings.py`, `config.php` |
| **Service configuration files** | Any service needing to authenticate to AD or a database to function |
| **Registry keys** | Credentials stored by installers or applications in the Windows registry |
| **Centrally deployed applications** | Endpoint security tools, management agents, monitoring agents — anything pushed from a central orchestrator |

**Automation:** tools like **Seatbelt** can enumerate many of these locations automatically on a Windows host.

### 3. The core concept: centrally deployed applications

- Applications deployed centrally across a network (endpoint security tools, monitoring agents, patch management systems) need to authenticate to an orchestrator or domain during installation and continued operation.
- Those credentials are embedded somewhere on the host so the application can use them at runtime — **without a human typing them in each time**.
- This means **every host running that application is a potential source of those credentials**, not just the server it connects back to.

### 4. General methodology for config file credential recovery

#### Step 1: identify what's running on the host

- List installed applications, running services, and scheduled tasks.
- Focus on anything that would need to authenticate outward (to AD, to a central server, to a database).
- Tools: `tasklist`, `services.msc`, `wmic product get name`, Seatbelt, or manual enumeration.

#### Step 2: locate the credential store

- Each application stores its credentials differently. Common patterns:
  - **Flat config files** (XML, JSON, INI, YAML) with plaintext or encoded credentials.
  - **SQLite or other embedded databases** (look for `.db` files in the application's data directory).
  - **Registry keys** written during installation.
  - **`ProgramData`** directories — a frequent location for application data on Windows that many assessors overlook (`C:\ProgramData\<VendorName>\`).

#### Step 3: extract and read the credential store

- If it's a readable text file, read it directly.
- If it's a SQLite database, copy it off the host and inspect it with **sqlitebrowser** or the `sqlite3` CLI:

```bash
sqlitebrowser <file>.db
# or
sqlite3 <file>.db ".tables"
sqlite3 <file>.db "SELECT * FROM <table>;"
```

- Transferring a file off a Windows host with SSH access:

```bash
scp <user>@<host>:C:/<path>/<file> .
```

#### Step 4: handle encryption

- Many applications encrypt stored credentials, but often use:
  - **Known, static encryption keys** baked into the application (the McAfee `ma.db` case is a direct example of this pattern).
  - **Weak or reversible encoding** (Base64, XOR with a fixed key).
  - **DPAPI** (Windows Data Protection API) — tied to the user or machine context, recoverable if you have the right access.
- **Check if a public decryption tool or known key already exists for the application** before trying to reverse engineer the encryption yourself. Endpoint security tools, VPN clients, and management agents are frequently researched and have known decryption methods publicly documented.

#### Step 5: use recovered credentials

- Recovered credentials are typically **AD service account credentials**, valid domain-wide.
- Use them for further AD enumeration, lateral movement, or privilege escalation — even a low-privileged service account opens up LDAP enumeration.

### 5. General offsec principle

- The security model behind most config-file credential storage is: *protect the location and access to the file, not the credential itself*.
- The moment you have local access to the host, that model collapses. This is exactly why **any foothold, however low-privileged, is worth fully exploiting before moving on** — the credentials to breach further may already be sitting on the host you're on.

### 6. Quick recall

- **Post-breach, always enumerate config files** — don't treat a foothold as just a pivot point.
- Locations to always check: `ProgramData`, application install directories, service config files, registry.
- Centrally deployed apps (endpoint security, patch management, monitoring agents) nearly always embed AD credentials.
- Encrypted ≠ safe. Many vendors use known, static keys or weak encoding. Check for existing public tooling before assuming the encryption is a blocker.
- A recovered service account credential, even a read-only one, is enough to enumerate the entire LDAP tree.
- **Seatbelt** automates much of this enumeration on Windows hosts.

### 7. Open items

- The source covers McAfee Enterprise as the worked example. The principle applies equally to any vendor: **the pattern (application stores encrypted creds in a known location with a known key) repeats across many enterprise products**. Build your methodology around the pattern, not the specific vendor.
- DPAPI-protected credentials on Windows (used by browsers, credential manager, and many applications) follow a different recovery path — worth covering separately if that material comes up.

## 🧭 Methodology

```text
Foothold on host
  ↓
Enumerate apps/services/tasks (Seatbelt, tasklist, wmic)
  ↓
Locate credential store (configs, .db, registry, ProgramData)
  ↓
Extract (read / sqlitebrowser / scp off host)
  ↓
Decrypt (known static key / weak encoding / DPAPI tooling)
  ↓
Use AD service creds → enumerate / move laterally
```

## 🛠️ Techniques

### Config File Enumeration (Seatbelt)

- Description: Automatically enumerate credential stores on a Windows host.
- When to use: Every post-breach foothold, before pivoting on.
- Command: Run Seatbelt; manually check `C:\ProgramData\<Vendor>\`, install dirs, service configs, registry.

### SQLite Credential Extraction

- Description: Copy embedded app databases off-host and query them.
- When to use: App stores creds in `.db` files.
- Command:
  ```bash
  scp <user>@<host>:C:/<path>/<file>.db .
  sqlite3 <file>.db ".tables"
  sqlite3 <file>.db "SELECT * FROM <table>;"
  ```

## 💻 Commands

```bash
# Host recon (Windows)
tasklist
wmic product get name

# SQLite inspection
sqlitebrowser <file>.db
sqlite3 <file>.db ".tables"
sqlite3 <file>.db "SELECT * FROM <table>;"

# Exfil over SSH
scp <user>@<host>:C:/<path>/<file> .
```

## 🧪 Labs

| Lab / Box | Key Learning | Status |
|-----------|:------------:|:------:|
| McAfee Enterprise example (ma.db, known static key) | Pattern: known-location + known-key encrypted store | 🔄 |

## 📇 Cheatsheet

- Foothold → configs first: `ProgramData`, install dirs, registry, `.db` files
- Centrally deployed apps = embedded AD creds on every host
- Encrypted ≠ safe: static keys / weak encoding / DPAPI — check public tooling first
- Even read-only service creds → full LDAP enumeration

---

[⬅ AD Domain](../README.md) | [📁 Breaching AD](./README.md) | [🏠 Dashboard](../../README.md)