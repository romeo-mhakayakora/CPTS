# AD Enumeration via Microsoft Management Console (MMC)

> [⬅ AD Domain](../README.md) | [📁 Enumeration](./README.md) | [🏠 Dashboard](../../README.md)

| HTB Progress | Notes | Practical Labs | CPTS Confidence |
|:------------:|:-----:|:--------------:|:---------------:|
| — | Started | — | — |

**Status:** 🔄 In Progress

---

## 📌 Concepts

### 1. What MMC + RSAT gives you

- **MMC (Microsoft Management Console)** is a native Windows administration tool. Combined with **RSAT (Remote Server Administration Tools) AD Snap-ins**, it becomes a full graphical control panel for an Active Directory environment.
- It's the fastest way to get a **visual, holistic picture of the domain structure** without running a single enumeration script.
- Critically, MMC can be run from a **non-domain-joined Windows machine** as long as you have valid AD credentials and use the `runas /netonly` trick from the previous section to inject them.

### 2. Installing RSAT (on a non-domain Windows machine)

RSAT is a Microsoft-provided optional feature installable on any Windows machine, regardless of whether it's domain-joined:

`Settings -> Apps & Features -> Manage Optional Features -> Add a Feature -> search "RSAT" -> Install "RSAT: Active Directory Domain Services and Lightweight Directory Tools"`

No domain membership or special download is needed. Windows fetches it directly from Microsoft in the background.

### 3. Launching MMC with injected credentials

Never open MMC normally from a non-domain machine — it will have nothing to connect to. Always launch it from the `runas /netonly` spawned CMD window:

```cmd
# From your runas /netonly CMD window:
mmc.exe
```

Because it's launched from that session, all MMC network connections automatically use the injected AD credentials.

### 4. Attaching the AD snap-ins (generalised steps)

1. `File -> Add/Remove Snap-in`
2. Add all three AD snap-ins: **Active Directory Domains and Trusts**, **Active Directory Sites and Services**, **Active Directory Users and Computers**.
3. For each snap-in, right-click and point it at the target domain (Change Forest / Change Domain as appropriate). Use the **FQDN** of the target domain.
4. On **Active Directory Users and Computers**, enable `View -> Advanced Features` to expose additional attributes and object protection settings.

After this, MMC is authenticated to and browsing the live target domain.

### 5. What you can enumerate with MMC

#### Organisational structure

- The OU tree reflects how the company is organised (departments, locations, roles). Expanding the domain shows the full hierarchy of OUs — IT, HR, Executives, Contractors, etc.
- This is **instant intelligence for targeting and social engineering** — you know who's in what team before running a single tool.

#### Users

- Clicking any OU shows the users inside it.
- Clicking any user shows all their **attributes and properties**: group memberships, description fields, contact info, last logon, account flags.
- **Description fields are a high-value target.** IT admins sometimes type passwords, service notes, or sensitive information directly into a user's description field.
- Group memberships reveal **privilege level** — note anyone in Domain Admins, Server Operators, Backup Operators, etc.

#### Computers

- The Computers/Servers/Workstations OUs give you a direct **list of every domain-joined machine** without needing to scan the network.
- This eliminates blind network scanning for host discovery — the DC hands you the full asset list.

#### Group Policy Objects (GPOs)

- The **Group Policy Management** snap-in (also part of RSAT, added separately) reveals the domain's security policies.
- **Key things to read before any password spraying or account manipulation:**

| Policy | Why it matters |
|---|---|
| **Account lockout threshold** | Max failed login attempts before lockout. This is your hard limit per spray round. Stay under it. |
| **Lockout duration / reset counter** | How long until the counter resets or the account unlocks. Dictates the wait time between spray rounds. |
| **Minimum password length and complexity** | Needed before attempting any password resets or creation of new accounts. |
| **Password history** | Tells you if old passwords can be reused when changing credentials. |

If you spray without reading the lockout policy, you risk locking out the entire company and triggering immediate alerts.

#### Direct changes (if privileges allow)

- If the injected credentials belong to an account with sufficient rights, MMC isn't read-only:
  - Reset a user's password.
  - Add an account to a security group (including Domain Admins).
  - Create new user accounts.
  - Modify object attributes.

### 6. Benefits and drawbacks

| | Detail |
|---|---|
| **Best for** | Getting a fast "lay of the land" — domain structure, user attributes, group memberships, machine list, GPO policies |
| **Not suited for** | Bulk/automated enumeration across all objects (checking 10,000 users' properties one by one is impractical) |
| **Requires** | RDP access to a Windows machine, or running MMC locally on your own Windows machine |
| **Alternative for bulk data** | Command-line tools (PowerShell AD module, ldapsearch, BloodHound) — covered in later sections |

### 7. Offsec workflow: where MMC fits in an engagement

1. Obtain valid AD credentials (via any earlier breach method).
2. Configure DNS on your Windows machine to point at the DC.
3. `runas /netonly` to inject credentials.
4. Launch MMC from the spawned window.
5. Attach AD snap-ins and point them at the target domain.
6. **Use MMC to:**
   - Map the OU structure and identify key departments and roles.
   - Find high-value user accounts (DA members, service accounts, admins).
   - Get the full machine list.
   - Read description fields for accidentally stored credentials.
   - Read GPO lockout and password policies before doing anything noisy.
7. Move to command-line/automated enumeration for bulk data extraction.

### 8. Quick recall

- MMC + RSAT = native Windows GUI for live AD enumeration from any Windows machine.
- Launch MMC from a `runas /netonly` window — not directly.
- RSAT installs via Windows Optional Features. No domain membership needed.
- Use FQDNs when pointing snap-ins at the target domain.
- Enable **Advanced Features** on the AD Users and Computers snap-in to see all attributes.
- **Description fields on users and computers** frequently contain accidentally stored credentials — always check them.
- **Read GPO lockout policies before password spraying** — the lockout threshold is the number that determines how many attempts you're allowed per round.
- MMC is for orientation and targeted inspection. Use command-line tools for bulk enumeration.

## 🧭 Methodology

```text
Valid creds → DNS at DC → runas /netonly → mmc.exe
  ↓
Attach 3 AD snap-ins (+ GPM), point at FQDN, Advanced Features on
  ↓
Map OUs → users/attrs/descriptions → computers → GPO lockout policy
  ↓
Direct changes if privileged → bulk CLI enumeration next
```

## 🛠️ Techniques

### MMC Visual Enumeration (RSAT)

- Description: Browse live domain structure, attributes, memberships and GPOs via GUI.
- When to use: First orientation pass after credential injection; targeted inspection.
- Command: From `runas /netonly` window: `mmc.exe` → Add snap-ins → FQDN → Advanced Features.

### Description-Field Credential Hunting

- Description: Read user/computer description fields for accidentally stored passwords.
- When to use: During every MMC pass; high hit-rate, low effort.
- Command: ADUC → OU → user/computer Properties → description/notes fields.

## 💻 Commands

```cmd
:: From runas /netonly spawned window
mmc.exe
```

## 🧪 Labs

| Lab / Box | Key Learning | Status |
|-----------|:------------:|:------:|
| | | |

## 📇 Cheatsheet

- RSAT via Optional Features (no domain needed) → `mmc.exe` from `/netonly` window → 3 snap-ins at FQDN
- Check: OU tree, user attrs, descriptions (creds!), computers list, GPO lockout policy
- Spray only after reading lockout threshold | GUI for orientation, CLI for bulk

---

[⬅ AD Domain](../README.md) | [📁 Enumeration](./README.md) | [🏠 Dashboard](../../README.md)