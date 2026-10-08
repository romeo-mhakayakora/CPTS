# Group Policy Objects (GPOs)

> [⬅ AD Domain](../README.md) | [📁 AD Basics](./README.md) | [🏠 Dashboard](../../README.md)

| HTB Progress | Notes | Practical Labs | CPTS Confidence |
|:------------:|:-----:|:--------------:|:---------------:|
| — | Started | — | — |

**Status:** 🔄 In Progress

---

## 📌 Concepts

### 1. What GPOs are

- OUs exist so that **different policies can be deployed per OU**, pushing different configurations and security baselines by department or device type.
- **GPO** = a collection of settings that can be applied to OUs.
- A GPO can hold policies for **users**, **computers**, or both, setting a baseline on specific machines and identities.

### 2. Group Policy Management tool

- Open it from the Start menu.
- It shows the full OU hierarchy.
- **Workflow:** create a GPO under *Group Policy Objects*, then **link** it to the OU where it should apply.

#### Default GPOs

| GPO | Linked to |
|---|---|
| Default Domain Policy | `thm.local` (whole domain) |
| RDP Policy | `thm.local` (whole domain) |
| Default Domain Controllers Policy | Domain Controllers OU only |

#### Inheritance

- A GPO applies to the **linked OU and all sub-OUs under it**. For example, Sales is still affected by the Default Domain Policy.
- **Computer Configuration settings are ignored** on OUs that contain only users, so a computer-targeted GPO linked at the root domain is safe to inherit everywhere.

### 3. Anatomy of a GPO

- **Scope tab:** shows where the GPO is linked in AD.
- **Security Filtering:** restricts a GPO to specific users or computers under an OU. The default is the **Authenticated Users** group (all users and PCs).
- **Settings tab:** shows the actual contents. Each GPO has two sections:
  - **Computer Configuration:** applies to computers only.
  - **User Configuration:** applies to users only.
- The Default Domain Policy contains only Computer Configuration, with basic domain settings such as **password and account lockout policies**.
- In the editor, double-click a policy and read the **Explain tab** for details.

### 4. Editing a GPO

- Right-click the GPO and choose **Edit**.
- Example path for password policy: `Computer Configuration -> Policies -> Windows Settings -> Security Settings -> Account Policies -> Password Policy`
- Settings in a domain-wide GPO affect **all computers** in the domain.
- Example setting: **Minimum password length**.
- A policy that restricts user access (for example, prohibiting Control Panel access) lives under **User Configuration**.

### 5. GPO distribution

- GPOs are distributed through the **SYSVOL** network share, stored on the DC.
- Domain users should normally have access to SYSVOL to sync their GPOs periodically.
- **Default path:** `C:\Windows\SYSVOL\sysvol\` on each DC.
- **Sync delay:** changes can take **up to 2 hours** to reach computers.
- **Force an immediate sync** on a specific computer:

```powershell
gpupdate /force
```

### 6. Quick recall

- GPO = set of user and computer settings, **linked to OUs** and inherited by sub-OUs.
- Tool: **Group Policy Management**. Create the GPO, then link it.
- **Security Filtering** defaults to Authenticated Users.
- Distributed via **SYSVOL** (`C:\Windows\SYSVOL\sysvol\`), refreshed up to every 2 hours.
- Force a refresh: `gpupdate /force`.
- **User Configuration** targets users. **Computer Configuration** targets machines and is ignored on user-only OUs.
- If a GPO doesn't seem to apply, run `gpupdate /force`.

## 🧭 Methodology

```text
Map OU hierarchy
  ↓
Create GPO → Link to target OU
  ↓
Scope + Security Filtering check
  ↓
Edit User vs Computer Configuration
  ↓
Verify via SYSVOL / gpupdate /force
```

## 🛠️ Techniques

### GPO Enumeration

- Description: Identify linked GPOs, inheritance and filtering.
- When to use: Mapping policy attack surface.
- Command: Group Policy Management → Scope / Settings tabs; `gpresult /r` on host.

### Force Policy Refresh

- Description: Apply pending GPO immediately for testing.
- When to use: GPO change not yet synced.
- Command:
  ```powershell
  gpupdate /force
  ```

## 💻 Commands

```powershell
# Force GPO sync on host
gpupdate /force

# Show applied GPOs
gpresult /r
```

```bash
# SYSVOL share (from Linux, for enumeration)
# smbclient //DC-IP/SYSVOL -U 'THM\user'
# ls C:\Windows\SYSVOL\sysvol\  # on DC
```

## 🧪 Labs

| Lab / Box | Key Learning | Status |
|-----------|:------------:|:------:|
| | | |

## 📇 Cheatsheet

- GPO linked to OU → inherits to sub-OUs | Filtering default Authenticated Users
- User vs Computer Configuration | SYSVOL `C:\Windows\SYSVOL\sysvol\` | `gpupdate /force`

---

[⬅ AD Domain](../README.md) | [📁 AD Basics](./README.md) | [🏠 Dashboard](../../README.md)