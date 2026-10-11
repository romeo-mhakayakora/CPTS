# AD Enumeration via PowerShell

> [⬅ AD Domain](../README.md) | [📁 Enumeration](./README.md) | [🏠 Dashboard](../../README.md)

| HTB Progress | Notes | Practical Labs | CPTS Confidence |
|:------------:|:-----:|:--------------:|:---------------:|
| — | Started | — | — |

**Status:** 🔄 In Progress

---

## 📌 Concepts

### 1. PowerShell vs CMD for AD enumeration

PowerShell is the upgrade to CMD. It gives access to **cmdlets** (`.NET` classes that perform specific functions), which return far richer and more structured output than `net` commands. The AD-RSAT tooling installs **50+ AD-specific cmdlets**.

| | CMD (`net`) | PowerShell (AD cmdlets) |
|---|---|---|
| Output detail | Basic, truncated at ~10 groups | Full, all attributes available |
| Works from non-domain machine | No | Yes, via `-Server` parameter |
| Filtering / scripting | None | Full filter, pipeline, and custom cmdlet support |
| Blue team visibility | Low | **Heavily monitored** |
| Can modify AD objects | No | Yes |

### 2. Key advantage: works from a non-domain machine

Unlike `net` commands, PowerShell AD cmdlets accept a `-Server` parameter that points directly at the target DC. Combined with the `runas /netonly` trick, you can run full AD enumeration from your own non-domain Windows machine without needing a foothold on a domain-joined host.

### 3. Core cmdlets

#### Upgrade to a PowerShell terminal (from SSH or CMD)

```powershell
powershell
```

#### Enumerate a specific user

```powershell
Get-ADUser -Identity <username> -Server <DC FQDN> -Properties *
```

- `-Identity` — the account to query.
- `-Properties *` — return all attributes, not just the defaults.
- `-Server` — point at the target DC. Required on non-domain machines.

**Key attributes to look for:**

| Attribute | Offensive value |
|---|---|
| `DistinguishedName` | Full position in the AD tree |
| `Department` | Organisational placement |
| `BadPwdCount` | Prior failed logins — critical for spraying |
| `PasswordLastSet` | How fresh the password is |
| `AccountExpirationDate` | Whether the account is expiring |
| `Description` | Sometimes contains accidentally stored passwords |

#### Filter users by pattern

```powershell
Get-ADUser -Filter 'Name -like "*stevens"' -Server <DC FQDN> | Format-Table Name,SamAccountName -A
```

- `-Filter` accepts AD query syntax for flexible searches.
- Pipeline to `Format-Table` for clean, readable output.

#### Enumerate a group

```powershell
Get-ADGroup -Identity <group name> -Server <DC FQDN>
```

#### Enumerate group members

```powershell
Get-ADGroupMember -Identity <group name> -Server <DC FQDN>
```

- Returns all members with their DN, object class and SID.
- Use for any high-value group: `Domain Admins`, `Backup Operators`, `Server Operators`, etc.

#### Search all AD objects by a condition

```powershell
Get-ADObject -Filter '<attribute> -gt <value>' -Server <DC FQDN>
```

**Example: find recently changed objects (useful for spotting recent admin activity)**

```powershell
$ChangeDate = New-Object DateTime(2022, 02, 28, 12, 00, 00)
Get-ADObject -Filter 'whenChanged -gt $ChangeDate' -includeDeletedObjects -Server <DC FQDN>
```

**Example: find accounts with prior failed login attempts (critical before spraying)**

```powershell
Get-ADObject -Filter 'badPwdCount -gt 0' -Server <DC FQDN>
```

- **This is one of the most important pre-spray checks.** Accounts already at `badPwdCount > 0` are closer to lockout than the domain policy threshold alone suggests. Exclude these from your spray round or you risk locking them.

#### Get domain-level information

```powershell
Get-ADDomain -Server <DC FQDN>
```

- Returns domain structure: child domains, containers, DN root, DNS root, DC container.
- Useful for mapping scope at the start of an engagement.

#### Modify AD objects (requires sufficient privileges)

```powershell
Set-ADAccountPassword -Identity <username> -Server <DC FQDN> `
  -OldPassword (ConvertTo-SecureString -AsPlaintext "<old>" -force) `
  -NewPassword (ConvertTo-SecureString -AsPlainText "<new>" -Force)
```

- AD-RSAT cmdlets can also **create or modify** objects, not just read them.
- Detailed exploitation use (adding users to groups, creating accounts) is covered in later AD exploitation material.

### 4. Detection risk and blue team considerations

PowerShell is the **most monitored attack surface** on a modern Windows endpoint. Two primary detection mechanisms:

#### AMSI (Anti-Malware Scan Interface)

- A security layer built directly into PowerShell.
- Scans every script or command **before it runs**.
- Recognises known offensive tools (BloodHound, PowerView, etc.) by signature and kills them, alerting the blue team.

#### Script Block Logging

- Windows records **every PowerShell command** run on the machine into a permanent log.
- If the blue team reviews logs, they see your exact commands in plaintext.
- Enabled by Group Policy — common in mature environments.

### 5. Using PowerShell through a RAT/C2 agent

You can run PowerShell AD cmdlets through a C2 shell on a compromised endpoint. The RAT executes PowerShell in the background without opening a visible window on the victim's screen. However, the detection mechanisms above still apply.

#### The bypass: Unmanaged PowerShell

- Running `powershell.exe` directly triggers AMSI and logging.
- Advanced C2 frameworks instead load the **raw PowerShell engine directly into memory inside a legitimate already-running process** (e.g., a browser, `notepad.exe`).
- Because `powershell.exe` never actually opens, the security guards watching for it are bypassed.
- This technique is called **Unmanaged PowerShell** or **PowerShell without `powershell.exe`**.
- Without this or an equivalent bypass, using PowerShell through a RAT on a monitored network risks triggering every alarm in the environment.

### 6. Alternative: running the C2 agent locally on your own attacker machine via `runas`

Instead of waiting to land on a victim's machine, you can run a C2 agent **directly on your own attacker Windows machine** with AD credentials injected via `runas /netonly`:

```cmd
runas.exe /netonly /user:<domain>\<username> C:\Tools\beacon.exe
```

#### The "split personality" in this context

- **Locally:** the C2 agent runs on your own machine, completely outside the reach of the target organisation's AV and EDR.
- **Over the network:** because it was launched via `runas /netonly`, every network connection the agent makes automatically carries the injected AD credentials. The DC sees a valid domain authentication, not an outsider.
- All PowerShell cmdlets run through this agent automatically inherit the injected credentials for the `-Server` connection, so you don't need to be on a domain-joined machine.

#### Why Red Teams do this instead of just typing commands manually

**Access to advanced C2 tooling**

- C2 frameworks like Cobalt Strike have point-and-click graphical dashboards that automatically map AD, draw visual relationship graphs, and extract credentials — far more capable than manually typing PowerShell cmdlets into a terminal all day.

**Team collaboration**

- In a professional penetration test with multiple operators, one person sets up a Windows VM with injected credentials and a running C2 agent. All other team members log into the central C2 server and **route their attacks through that one shared gateway**, effectively sharing a single authenticated domain foothold across the whole team.

**Pivoting and tunnelling**

- C2 agents can create **invisible network tunnels**. By running the agent locally with injected credentials, other tools on Kali (LDAP scanners, database crackers, web scanners) can be forced to flow through the agent, **automatically inheriting the AD credentials** for everything they do — without needing to be on a domain-joined machine themselves.

#### Key point

This approach combines the **safety of attacking from your own controlled machine** with the **full power of a professional C2 framework, authenticated domain access, and PowerShell enumeration capabilities**. It is one of the most practical setups for a real red team engagement where credentials have been obtained but no domain-joined foothold yet exists.

### 7. Benefits and drawbacks

| | Detail |
|---|---|
| **Richer data** | Returns all attributes, not truncated like `net` |
| **Works from non-domain machine** | `-Server` parameter + `runas /netonly` |
| **Filterable and scriptable** | Custom filters, pipelines, and your own cmdlets |
| **Can modify AD objects** | Reset passwords, add to groups, create accounts |
| **Heavily monitored** | AMSI and Script Block Logging are standard in mature environments |
| **Requires RSAT or third-party scripts** | Not available out of the box without tooling installed |

### 8. Enumeration workflow

1. Point PowerShell at the target DC with `-Server <DC FQDN>`.
2. **`Get-ADDomain`** — map the domain structure and scope.
3. **`Get-ADObject -Filter 'badPwdCount -gt 0'`** — identify accounts already accumulating failed attempts before doing anything noisy.
4. **`Get-ADUser -Filter * -Properties *`** — full user list with all attributes. Check description fields for stored credentials.
5. **`Get-ADGroup`** + **`Get-ADGroupMember`** — enumerate high-value groups and their members.
6. **`Get-ADObject -Filter 'whenChanged -gt $date'`** — identify recent changes that may indicate active admin sessions or recent privilege modifications.
7. Feed findings into spraying, lateral movement planning, or targeted phishing.

### 9. Quick recall

- PowerShell AD cmdlets are installed with RSAT. 50+ available.
- Key cmdlets: `Get-ADUser`, `Get-ADGroup`, `Get-ADGroupMember`, `Get-ADObject`, `Get-ADDomain`.
- Use `-Server <DC FQDN>` to target the DC from a non-domain machine.
- Use `-Properties *` to return all attributes.
- **Check `badPwdCount > 0` before spraying** — exclude those accounts from the round.
- **PowerShell is heavily monitored** — AMSI blocks known tools, Script Block Logging records everything.
- Through a RAT/C2, use **Unmanaged PowerShell** (engine loaded into a legitimate process) to avoid triggering `powershell.exe`-based detections.
- **`runas /netonly` + local C2 agent** = authenticated AD access from your own machine, full C2 tooling, team collaboration, and cross-tool credential tunnelling — no victim machine foothold required.
- Full reference: https://docs.microsoft.com/en-us/powershell/module/activedirectory

## 🧭 Methodology

```text
RSAT AD-RSAT installed → powershell
  ↓
-Server <DC FQDN> (+ runas /netonly for non-domain machine)
  ↓
Get-ADDomain (scope) → badPwdCount > 0 check → Get-ADUser -Filter * -Properties *
  ↓
Get-ADGroup / Get-ADGroupMember (high-value) → whenChanged recent-activity check
  ↓
Feed into spray / lateral / phishing
```

## 🛠️ Techniques

### PowerShell AD Cmdlet Enumeration

- Description: Full-attribute AD queries from non-domain machines via `-Server`.
- When to use: Need rich, filterable data; creds + RSAT available.
- Command: `Get-ADUser -Identity <u> -Server <DC FQDN> -Properties *`, `Get-ADGroupMember`, `Get-ADObject -Filter ...`.

### Pre-spray badPwdCount Check

- Description: Exclude accounts near lockout from spray rounds.
- When to use: Before any password spraying.
- Command: `Get-ADObject -Filter 'badPwdCount -gt 0' -Server <DC FQDN>`

### Unmanaged PowerShell (via C2)

- Description: Load PS engine into a legit process to bypass AMSI/`powershell.exe` detection.
- When to use: PowerShell needed on a monitored host through a C2.
- Command: C2 feature (e.g., Cobalt Strike's `powerpick`) — never raw `powershell.exe`.

## 💻 Commands

```powershell
# Terminal
powershell

# Core enumeration (non-domain machine: add -Server <DC FQDN>)
Get-ADDomain -Server <DC FQDN>
Get-ADObject -Filter 'badPwdCount -gt 0' -Server <DC FQDN>
Get-ADUser -Filter * -Properties * -Server <DC FQDN>
Get-ADUser -Identity <username> -Server <DC FQDN> -Properties *
Get-ADGroup -Identity <group> -Server <DC FQDN>
Get-ADGroupMember -Identity <group> -Server <DC FQDN>

# Recent changes
$ChangeDate = New-Object DateTime(2022, 02, 28, 12, 00, 00)
Get-ADObject -Filter 'whenChanged -gt $ChangeDate' -includeDeletedObjects -Server <DC FQDN>

# Local C2 agent with injected creds (own machine)
runas.exe /netonly /user:<domain>\<username> C:\Tools\beacon.exe
```

## 🧪 Labs

| Lab / Box | Key Learning | Status |
|-----------|:------------:|:------:|
| | | |

## 📇 Cheatsheet

- 50+ AD cmdlets via RSAT | `-Server <DC FQDN>` works off-domain (with `/netonly`)
- `Get-ADUser -Properties *` / `Get-ADGroupMember` / `Get-ADObject -Filter` / `Get-ADDomain`
- **`badPwdCount > 0` before spraying** | description fields = creds
- Heavily monitored: AMSI + Script Block Logging → Unmanaged PowerShell via C2
- `runas /netonly` + local beacon = full PS enum from own machine

---

[⬅ AD Domain](../README.md) | [📁 Enumeration](./README.md) | [🏠 Dashboard](../../README.md)