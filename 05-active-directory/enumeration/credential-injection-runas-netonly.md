# Credential Injection and Using Stolen AD Credentials from a Non-Domain Machine

> [⬅ AD Domain](../README.md) | [📁 Enumeration](./README.md) | [🏠 Dashboard](../../README.md)

| HTB Progress | Notes | Practical Labs | CPTS Confidence |
|:------------:|:-----:|:--------------:|:---------------:|
| — | Started | — | — |

**Status:** 🔄 In Progress

---

## 📌 Concepts

### 1. The problem this solves

During an assessment you will often find valid AD credentials before you have access to a domain-joined machine. You have the keys but no door. `runas.exe` with the `/netonly` flag solves this: it lets you inject those credentials into memory on any Windows machine you control and use them for all outgoing network connections, without ever joining the domain.

**Why Windows over Kali for this:** Linux tools can get you far in AD enumeration, but Windows lets you use native, built-in mechanisms that blend in with normal traffic and access things Linux tools can't reach natively (SQL Studio, native Kerberos, Windows-authenticated web apps, etc.).

### 2. Prerequisites before you can do anything

| Requirement | Why | How to verify |
|---|---|---|
| **Network line-of-sight to the DC** | Credentials are verified against the DC | `ping <DC IP>` |
| **DC's IP address** | Needed to configure DNS | From DHCP, OSINT, or port scan for 53/88/389/445 |
| **DNS pointing at the DC** | Without it, hostnames (FQDNs) don't resolve | `nslookup <domain>` returns DC's IP |
| **Valid AD credentials** | The credentials being injected | Confirmed by successfully listing SYSVOL |
| **Local admin on your machine** | Ensures tools spawned from the session have local privileges | Run your initial CMD as Administrator |

#### Finding the DC's IP when it isn't given to you

- If physically on the LAN, **DHCP may hand it to you automatically** as the default DNS server.
- Otherwise, scan for a host with **ports 53 (DNS), 88 (Kerberos), and 389 (LDAP)** open simultaneously — that machine is almost always the DC.

### 3. Configuring DNS on Windows to point at the DC

DNS must be set before running `runas`, because without it the FQDN in the `/user` parameter can't resolve.

```powershell
# Run in PowerShell — replace interface name and DC IP as needed
$dnsip = "<DC IP>"
$index = Get-NetAdapter -Name 'Ethernet' | Select-Object -ExpandProperty 'ifIndex'
Set-DnsClientServerAddress -InterfaceIndex $index -ServerAddresses $dnsip
```

- Replace `'Ethernet'` with whatever interface name connects you to the target network (`Get-NetAdapter` to list them).
- Verify it worked:

```cmd
nslookup <target domain>
```

Should resolve to the DC's IP.

### 4. Injecting credentials with runas

```cmd
runas.exe /netonly /user:<FQDN domain>\<username> cmd.exe
```

**Parameter breakdown:**

| Parameter | Purpose |
|---|---|
| `/netonly` | Use these credentials for **network connections only**. Local commands still run as your own local user. Credentials are NOT verified against the DC at this point, so any password is accepted here. |
| `/user:<domain>\<username>` | Use the **FQDN** of the domain, not just the NetBIOS name. Avoids resolution issues. |
| `cmd.exe` | Opens a new CMD window with credentials loaded. Any process you launch from this window inherits the injected credentials for all network communication. |

#### Key behaviour

- **Locally:** your normal user account. File access, tool execution against local disk = your local context.
- **Over the network:** every outgoing connection automatically uses the injected AD credentials. This includes SQL Server Studio, network share access, LDAP tools, NTLM-authenticated web apps — anything launched from that CMD window.
- **You won't know if the password is correct** until you try to connect to something. The DC verifies credentials at connection time, not at the `runas` prompt.

#### Local admin tip

Run the first CMD as Administrator before executing `runas`. This injects an admin token into the spawned window, ensuring local tools that need elevated privileges work. This does **not** give you network-level admin — only local.

### 5. Verifying credentials work: listing SYSVOL

SYSVOL is the go-to verification target because **every valid AD account, regardless of privilege level, can read it.** If you can list it, the credentials are valid.

```cmd
dir \\<target domain FQDN>\SYSVOL\
```

- Success: directory listing is returned. Credentials are valid and working.
- Failure (Access Denied): wrong password, disabled account, or DNS not working.

#### What SYSVOL is

- A shared folder on every DC.
- Stores **GPOs, domain scripts, and logon/startup scripts** pushed to all domain-joined machines.
- **Secondary value:** IT admins frequently store scripts with hardcoded credentials in SYSVOL. Enumerating its contents is worthwhile beyond just credential verification.

### 6. Hostname vs IP: controlling which auth protocol is used

This is an important operational detail with stealth implications.

| You type | Auth protocol used | Why |
|---|---|---|
| `\\domain.fqdn\share` | **Kerberos** (default) | Kerberos requires a hostname to embed in its ticket |
| `\\<DC IP>\share` | **NTLM** (fallback) | Kerberos can't work with a bare IP, so Windows falls back to NTLM |

#### When this matters on a red team

- Some organisations actively monitor for **Kerberos-based attacks** (Pass-the-Hash, OverPass-the-Hash). They may have alerts on unusual Kerberos ticket requests.
- **Deliberately using the IP instead of the hostname forces NTLM**, bypassing Kerberos detection entirely.
- You still get full access. You just came in through a different door that fewer people are watching.
- The inverse is also true: if NTLM is being monitored or blocked, using the hostname to force Kerberos may work better.
- **Knowing which protocol to force, and when, is a stealth decision**, not just a technical one.

### 7. Quick recall

- `runas /netonly` = inject AD creds into a non-domain Windows machine for **network-only use**.
- DNS must point at the DC **before** running `runas`, or FQDN resolution fails.
- `/netonly` accepts any password at the prompt — verify creds separately via SYSVOL listing.
- All tools and processes **launched from the spawned CMD** inherit the injected credentials for network connections.
- SYSVOL readable by all AD users = universal credential test AND a secondary loot target (scripts may contain creds).
- **Hostname = Kerberos. IP = NTLM.** Swap between them based on what the defender is watching.
- DC IP is Step 1. Without it, nothing else works.

### 8. Engagement checklist (pre-enumeration, non-domain Windows machine)

1. Obtain DC IP (DHCP, scan for 53/88/389/445).
2. Point local DNS at the DC (PowerShell `Set-DnsClientServerAddress`).
3. Confirm DNS works (`nslookup <domain>`).
4. Run initial CMD as Administrator.
5. `runas /netonly /user:<FQDN>\<user> cmd.exe` with obtained credentials.
6. From the spawned window: `dir \\<domain FQDN>\SYSVOL\` to confirm credentials work.
7. While in SYSVOL, enumerate scripts and GPO content for additional credentials.
8. Proceed to AD enumeration tools from the same spawned CMD window.

## 🧭 Methodology

```text
DC IP (DHCP / scan 53+88+389) → DNS at DC → nslookup check
  ↓
CMD as Admin → runas /netonly /user:<FQDN>\<user> cmd.exe
  ↓
dir \\<FQDN>\SYSVOL\ (verify creds + loot scripts)
  ↓
Hostname = Kerberos / IP = NTLM (stealth choice)
  ↓
Enumerate AD from spawned window
```

## 🛠️ Techniques

### Credential Injection (runas /netonly)

- Description: Use stolen AD creds for network auth from a non-domain Windows host.
- When to use: Valid creds in hand, no domain-joined machine available.
- Command: `runas.exe /netonly /user:<FQDN>\<user> cmd.exe` → verify with `dir \\<FQDN>\SYSVOL\`.

### Protocol Forcing (Hostname vs IP)

- Description: Choose Kerberos or NTLM per connection for stealth.
- When to use: Defender monitors one protocol; use the other door.
- Command: `\\fqdn\share` = Kerberos, `\\<IP>\share` = NTLM.

## 💻 Commands

```powershell
# DNS at DC (PowerShell, admin)
$dnsip = "<DC IP>"
$index = Get-NetAdapter -Name 'Ethernet' | Select-Object -ExpandProperty 'ifIndex'
Set-DnsClientServerAddress -InterfaceIndex $index -ServerAddresses $dnsip
```

```cmd
:: Inject creds
runas.exe /netonly /user:<FQDN domain>\<username> cmd.exe

:: Verify via SYSVOL (from spawned window)
dir \\<target domain FQDN>\SYSVOL\
nslookup <target domain>
```

## 🧪 Labs

| Lab / Box | Key Learning | Status |
|-----------|:------------:|:------:|
| | | |

## 📇 Cheatsheet

- `runas /netonly` + DNS-at-DC first → spawned CMD inherits creds for network
- Verify: `dir \\<FQDN>\SYSVOL\` (all users can read; loot scripts too)
- Hostname = Kerberos, IP = NTLM — pick per defender monitoring
- DC IP via DHCP or scan 53/88/389

---

[⬅ AD Domain](../README.md) | [📁 Enumeration](./README.md) | [🏠 Dashboard](../../README.md)