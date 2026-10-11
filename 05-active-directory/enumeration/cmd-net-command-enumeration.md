# AD Enumeration via Command Prompt and the `net` Command

> [⬅ AD Domain](../README.md) | [📁 Enumeration](./README.md) | [🏠 Dashboard](../../README.md)

| HTB Progress | Notes | Practical Labs | CPTS Confidence |
|:------------:|:-----:|:--------------:|:---------------:|
| — | Started | — | — |

**Status:** 🔄 In Progress

---

## 📌 Concepts

### 1. Why CMD over other methods

CMD-based AD enumeration matters in scenarios where other methods aren't available or are too noisy:

| Scenario | Why CMD helps |
|---|---|
| **No RDP access** | No GUI needed. A text-only shell (RAT/C2 agent) is enough |
| **PowerShell is monitored** | Blue teams commonly alert on unusual PowerShell. CMD flies under the radar more often |
| **Phishing payload** | VBScript and macro languages natively support `net` commands. Quick AD recon can be embedded directly in a phishing macro, running silently before any further payload is delivered |
| **Living off the land** | `net.exe` is a legitimate Windows binary. Antivirus and EDR rarely flag it |

### 2. The critical constraint

**`net` commands only work from a domain-joined machine.** On a non-domain machine, the command defaults to the local WORKGROUP and returns nothing useful. The `runas /netonly` trick does not fix this — `net` is too legacy to pick up injected credentials.

This means `net` is primarily useful when:

- You have a foothold (shell, RAT/C2 agent) on a domain-joined endpoint.
- You're physically logged into or RDP'd to a domain-joined machine.

### 3. Core `net` commands for AD enumeration

#### List all domain users

```cmd
net user /domain
```

- Returns every user account in the domain.
- Useful for: sizing the domain, building a username list for spraying, identifying naming conventions.

#### Detailed info on a specific user

```cmd
net user <username> /domain
```

**Key fields to note:**

| Field | Offensive value |
|---|---|
| Account active | Whether the account can be used |
| Last logon | Active vs. dormant account |
| Password last set | Estimate of how "fresh" the password is |
| Password expires | Whether rotation is enforced |
| Global Group memberships | Privilege level of the account |

**Limitation:** only shows up to ~10 group memberships. For heavily privileged accounts with many group memberships, this truncates. Use PowerShell or LDAP-based tools for complete output.

#### List all domain groups

```cmd
net group /domain
```

- Returns all security groups in the domain.
- First thing to look for: high-value groups (`Domain Admins`, `Schema Admins`, `Server Operators`, `Backup Operators`, custom Tier 0/1 Admin groups).

#### List members of a specific group

```cmd
net group "<group name>" /domain
```

- Returns every member of the named group.
- Use this to identify exactly which accounts hold the most privilege — these are your priority targets for lateral movement or phishing.

#### Read the domain password policy

```cmd
net accounts /domain
```

**Key fields and their offensive meaning:**

| Field | What it tells you |
|---|---|
| **Lockout threshold** | Max failed login attempts before lockout. This is your hard limit per spray round. `Never` = no lockout risk. |
| **Lockout duration** | How long the account stays locked. Also governs how long to wait between spray rounds. |
| **Lockout observation window** | The window in which failed attempts are counted. Relevant for timing spray rounds. |
| **Minimum password length** | Informs what passwords are even valid to guess or set |
| **Maximum password age** | Whether passwords are rotated. Old max age = higher chance users have stale passwords |
| **Password history** | How many unique passwords before reuse is allowed |

**Critical note:** even with the policy in hand, a blind spray can still lock accounts if specific accounts had prior failed attempts you didn't know about. The policy tells you the threshold; it doesn't tell you where each account currently is within that threshold.

### 4. Benefits and drawbacks

| | Detail |
|---|---|
| **No extra tooling** | Built into every Windows machine |
| **Low visibility** | Often not monitored by blue teams unlike PowerShell |
| **Phishing-compatible** | VBScript/macro languages support these commands natively — instant recon embedded in a payload |
| **Domain-joined only** | Won't work from a non-domain machine regardless of credential injection |
| **Truncated output** | Group memberships cap at ~10 per user. Doesn't cover all AD attributes |

### 5. Establishing RAT/C2 access to a domain-joined machine

For `net` commands to be run remotely, you first need a shell on a domain-joined machine. That shell is typically provided by a C2 framework.

#### Delivery methods

**Phishing — most common**

- Send a malicious email with a weaponised attachment: Word/Excel document with macros, an ISO, an LNK file, or similar.
- When the victim enables macros or opens the file, the payload executes silently and the C2 agent installs itself in the background.
- Simple `net` commands can be embedded directly in the phishing macro itself, so the first thing the payload does on execution is run AD recon and send results back — before the victim notices anything.

**Malicious link**

- A link in a phishing email redirects to a page that drops and executes a payload via a browser exploit or a user-triggered download.

**Physical access / rogue device**

- Plugging a rogue device into the LAN provides network access. This can be combined with a compromised nearby endpoint for a full shell.

#### What happens after delivery

1. Payload executes on the victim's domain-joined machine.
2. C2 agent establishes an **outbound connection** back to the attacker's server. Outbound traffic is far less likely to be blocked than inbound.
3. Attacker receives a shell running in the **context of the victim's domain user account**.
4. From that shell, all `net /domain` commands work natively — no extra DNS setup or credential injection needed.
5. From the DC's perspective, it looks like a normal domain-joined computer making routine queries.

#### Common C2 frameworks

| Tool | Notes |
|---|---|
| **Cobalt Strike (Beacon)** | Industry standard for red teams and real adversaries. Beacon sleeps between check-ins to evade detection. |
| **Metasploit (Meterpreter)** | Most widely known open-source framework. Meterpreter runs entirely in memory (RAM), avoiding disk-based AV detection. |
| **Sliver / Havoc** | Modern open-source alternatives built to evade Defender and commercial AV. |

#### How agents stay hidden: process injection

All modern C2 frameworks use **process injection** — the agent hides inside a legitimate already-running process (e.g., `explorer.exe`, a browser) rather than running as a visible standalone process. No CMD window appears on the victim's screen, and from the DC it looks like normal Windows traffic.

### 6. Alternative: running the C2 agent locally on your own attacker machine via `runas`

Instead of waiting to land on a victim's machine, you can run a C2 agent **directly on your own attacker Windows machine** with AD credentials injected via `runas /netonly`:

```cmd
runas.exe /netonly /user:<domain>\<username> C:\Tools\beacon.exe
```

#### The "split personality" in this context

- **Locally:** the C2 agent runs on your own machine, completely outside the reach of the target organisation's AV and EDR.
- **Over the network:** because it was launched via `runas /netonly`, every network connection the agent makes automatically carries the injected AD credentials. The DC sees a valid domain authentication, not an outsider.

#### Why Red Teams do this instead of just typing commands manually

**Access to advanced C2 tooling**

- C2 frameworks like Cobalt Strike have point-and-click graphical dashboards that automatically map AD, draw visual relationship graphs, and extract credentials — far more capable than manually typing `net` commands into a terminal all day.

**Team collaboration**

- In a professional penetration test with multiple operators, one person sets up a Windows VM with injected credentials and a running C2 agent. All other team members log into the central C2 server and **route their attacks through that one shared gateway**, effectively sharing a single authenticated domain foothold across the whole team.

**Pivoting and tunnelling**

- C2 agents can create **invisible network tunnels**. By running the agent locally with injected credentials, other tools on Kali (LDAP scanners, database crackers, web scanners) can be forced to flow through the agent, **automatically inheriting the AD credentials** for everything they do — without needing to be on a domain-joined machine themselves.

#### Key point

This approach combines the **safety of attacking from your own controlled machine** with the **full power of a professional C2 framework and authenticated domain access**. It's one of the most practical setups for a real red team engagement where credentials have been obtained but no domain-joined foothold yet exists.

### 7. Enumeration workflow using `net`

1. **Read the password policy first** (`net accounts /domain`) before doing anything noisy. Know your lockout limits.
2. **List all users** (`net user /domain`) — build your target and spray list.
3. **List all groups** (`net group /domain`) — identify high-value groups.
4. **Drill into high-value groups** (`net group "<group>" /domain`) — find the specific accounts to target or impersonate.
5. **Profile specific accounts** (`net user <username> /domain`) — check if active, last logon, group memberships.
6. **Feed findings into next steps:** spray within the policy limits, or use the user/group list to prioritise lateral movement targets.

### 8. Quick recall

- `net user /domain` — all users.
- `net user <username> /domain` — detailed profile. Truncates at ~10 groups.
- `net group /domain` — all groups.
- `net group "<name>" /domain` — members of a specific group.
- `net accounts /domain` — password and lockout policy. **Read this before spraying.**
- CMD works on **domain-joined machines only**. Not compatible with `runas /netonly`.
- It's a living-off-the-land tool — low noise, no installation needed.
- C2 access is established via phishing (most common), malicious links, or rogue device/physical access.
- C2 agents use **outbound connections** to phone home and **process injection** to stay hidden.
- **`runas /netonly` + local C2 agent** = authenticated AD access from your own machine, full C2 tooling, team collaboration, and cross-tool credential tunnelling — no victim machine foothold required.

## 🧭 Methodology

```text
Domain-joined foothold (phish / link / rogue device → C2 shell)
   or runas /netonly + local C2 agent
  ↓
net accounts /domain (policy first!)
  ↓
net user /domain → net group /domain → drill into DA groups
  ↓
net user <user> /domain (profile) → spray / lateral targets
```

## 🛠️ Techniques

### net Command Recon

- Description: Built-in CMD enumeration of users, groups, members, password policy.
- When to use: Domain-joined shell, low-noise recon, macro-embedded recon.
- Command: `net user /domain`, `net group /domain`, `net group "<name>" /domain`, `net user <u> /domain`, `net accounts /domain`.

### Local C2 Agent via runas /netonly

- Description: Run a C2 agent on your own Windows box with injected AD creds.
- When to use: Valid creds but no domain-joined foothold; team/shared gateway setups.
- Command: `runas.exe /netonly /user:<domain>\<username> C:\Tools\beacon.exe`

## 💻 Commands

```cmd
:: Domain recon (domain-joined machine only)
net accounts /domain
net user /domain
net group /domain
net group "Domain Admins" /domain
net user <username> /domain

:: Local C2 agent with injected creds (own machine)
runas.exe /netonly /user:<domain>\<username> C:\Tools\beacon.exe
```

## 🧪 Labs

| Lab / Box | Key Learning | Status |
|-----------|:------------:|:------:|
| | | |

## 📇 Cheatsheet

- `net /domain` needs domain-joined host (not `/netonly`-injectable) | low-noise, no install
- Policy first: `net accounts /domain` → then users → groups → group members → profile
- User detail truncates ~10 groups | C2 via phishing/link/rogue device, outbound + process injection
- Own machine: `runas /netonly` + local beacon = authenticated foothold + team gateway + tunnel for Kali tools

---

[⬅ AD Domain](../README.md) | [📁 Enumeration](./README.md) | [🏠 Dashboard](../../README.md)