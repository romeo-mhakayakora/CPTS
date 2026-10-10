# SMB Authentication, LLMNR/NBT-NS/WPAD Poisoning, and NetNTLM Relay Attacks

> [⬅ AD Domain](../README.md) | [📁 Breaching AD](./README.md) | [🏠 Dashboard](../../README.md)

| HTB Progress | Notes | Practical Labs | CPTS Confidence |
|:------------:|:-----:|:--------------:|:---------------:|
| — | Started | — | — |

**Status:** 🔄 In Progress

---

## 📌 Concepts

### 1. The problem space

- Windows networks are full of services authenticating to each other constantly.
- This section focuses on **NetNTLM authentication as used by SMB** — the protocol version of what the NTLM-authenticated-services notes covered through a web application.

### 2. Server Message Block (SMB)

- **SMB** lets clients (workstations) talk to servers (file shares). It governs file sharing, remote administration, and even things like print spooler notifications.
- Older SMB versions have known weaknesses. Vulnerabilities let attackers **recover credentials** or even **gain code execution**.
- Many organisations **still run legacy SMB versions** because old systems don't support the newer, hardened ones. This keeps old attack paths alive in real environments.

#### Two exploitation paths for NetNTLM over SMB

1. **Capture and crack offline:** intercept a NetNTLM challenge/response, then crack it offline to recover the password. Slower than cracking an NTLM hash directly, since NetNTLM responses are computationally harder to crack.
2. **Relay:** stage a MITM, relaying the SMB authentication live between client and server to get an **authenticated session**, without ever cracking anything.

### 3. Why these authentication attempts end up "in the air" to catch

- Large numbers of NetNTLM exchanges happen on a network constantly (background reconnections, security tooling sweeping IP ranges, etc.).
- **Stale DNS records** mean some of these authentication attempts get misdirected and can land on a rogue device instead of their real target.

### 4. The core mechanism: DNS fallback, not DNS interception

> Clarified via Q&A (useful mental model, not verbatim source wording):

- Normally, a client resolves a hostname through standard DNS (the Domain Controller). This path is private and hard to intercept directly.
- **LLMNR, NBT-NS and WPAD are fallback broadcast protocols**, used only when:
  1. **Standard DNS fails** (typo, decommissioned server, stale record).
  2. **A short (non-FQDN) name is used.** Windows treats a short name as possibly being on the local subnet and may broadcast for it locally before, or instead of, going through full DNS resolution.
- When a fallback triggers, the client **broadcasts to the local network**: "does anyone know where `X` is?"
- Anyone listening can answer. There's no verification built into these protocols, which is the core weakness.

### 5. The three broadcast protocols Responder poisons

| Protocol | Purpose | Role here |
|---|---|---|
| **LLMNR** (Link-Local Multicast Name Resolution) | Lets hosts resolve names for other hosts on the same local network without burdening the DNS server, by broadcasting and seeing who answers | Fallback name resolution |
| **NBT-NS** (NetBIOS Name Service) | The legacy predecessor to LLMNR, doing the same job. Kept enabled by default for compatibility with old devices | Fallback name resolution |
| **WPAD** (Web Proxy Auto-Discovery) | Lets a client automatically discover which proxy server to route HTTP(S) traffic through | Fallback proxy discovery |

#### Why these are so reliably exploitable in practice

- All three are **enabled by default** in Windows and require explicit Group Policy changes to disable.
- **Human error drives them constantly:** typos in share names, employees typing short names instead of FQDNs, legacy login scripts mapping drives with short names.
- **WPAD specifically:** "Automatically detect settings" is checked by default in most browsers/OS proxy settings, so clients regularly broadcast for a proxy on their own.
- Even a "well-configured" network rarely eliminates this fully, since it depends on consistent human behaviour across every script, mapped drive, and employee action.

### 6. Responder: the tool

- **Responder** listens passively for LLMNR, NBT-NS, and WPAD broadcasts on the attacker's interface.
- When it sees one, it answers before the real target can (or when there is no real target), claiming "that's me" for the requested hostname/proxy.
- It also **spins up fake servers** (SMB, HTTP, SQL, and others) so that once a victim is tricked into connecting, there's a live service ready to **force an authentication attempt** and capture it.

#### Running it

```bash
sudo responder -I <interface>
```

#### What you capture

- A victim's SMB client connects to the attacker, thinking it reached the real resource, and sends an **NTLMv2-SSP** authentication response.
- Example output format:

```text
[SMBv2] NTLMv2-SSP Client   : <Client IP>
[SMBv2] NTLMv2-SSP Username : DOMAIN\<Username>
[SMBv2] NTLMv2-SSP Hash     : <Username>::DOMAIN:<NTLMv2-SSP Hash>
```

#### Constraint

- Responder works on a **race condition**: it has to answer before/instead of any legitimate host. This generally limits it to the **local broadcast domain / local network segment** the attacker is actually on (or a VPN segment simulating that in a lab).

#### Operational risk

- Poisoning these requests **can break legitimate traffic**: if Responder answers instead of the real host, normal authentication/connections intended for that real host will fail.
- This is **disruptive and detectable** — worth factoring into timing and scope on a real assessment, not something to run blindly for long periods without consideration.

### 7. Path 1: Capture + offline cracking

1. Leave Responder running to accumulate one or more NTLMv2-SSP hashes.
2. Save a hash to a file.
3. Crack offline with Hashcat, using hash mode **5600** (NTLMv2-SSP):

```bash
hashcat -m 5600 <hash file> <password file> --force
```

4. Any cracked hash gives you a **valid AD credential**.

**Caveat:** NetNTLM(v2) hashes are **much slower to crack** than raw NTLM hashes, so success depends heavily on password strength and wordlist quality.

### 8. Path 2: Relaying the challenge (true MITM)

Instead of capturing and cracking, you pass the live authentication attempt straight through to a real target, gaining a session without ever knowing the password.

#### Flow

1. Victim broadcasts, thinking it's resolving a real host.
2. Attacker (Responder/relay tool) answers and receives the victim's NetNTLM challenge/response.
3. Instead of saving it, the attacker **immediately forwards that response to a real target server** (could be the DC or another host), authenticating as the victim.
4. If accepted, the attacker now has an **active, authenticated session** as the victim, without ever cracking a password.

#### Requirements for relaying to work

- **SMB Signing** must be **disabled**, or enabled but **not enforced**. If signing is enforced, the relayed/modified request's signature won't validate, and the target rejects it.
- The **relayed account needs meaningful permissions** on the target server. Ideally, an account with admin rights on that server, since that's what actually gets you a foothold.
- **Without prior AD enumeration, which account you'll capture (and what it can access) is a guess.** This is why "blind" relays aren't popular — relaying an account with no useful permissions wastes the opportunity and tips off defenders for nothing.

#### Recommended sequencing (strategy, not just mechanics)

- The source explicitly recommends: **breach AD by another means first**, enumerate privileges once you have any foothold, **then** come back to relay attacks with a specific, informed target in mind (an account/server pair known to matter), rather than relaying blind.

---

## Strategy: Capitalising on This Attack Surface

### When you have internal/LAN or rogue-device access

1. **Deploy Responder early and let it run passively** while doing other recon — it costs little and captures opportunistically.
2. **Prioritize capture-and-crack if you lack AD foothold context:** grab whatever NTLMv2-SSP hashes come in, and run them against a strong wordlist/rules in Hashcat (`-m 5600`). Any crack gives a valid, usable credential.
3. **Don't blind-relay without a reason.** Relaying nets you a session, but if the relayed account has no meaningful rights on the target, you've gained nothing and generated noise.
4. **Once you have any foothold (from spraying, cracking, LDAP pass-back, etc.), enumerate AD** to learn which accounts have admin rights on which hosts. *Then* relay attacks become worth targeting deliberately — relay a specific known-privileged account to a specific known-vulnerable (unsigned SMB) target.
5. **Check SMB signing status on targets** before planning a relay. Disabled/not-enforced signing is a prerequisite; if it's enforced everywhere, relaying is a dead end and capture-and-crack becomes the better route.
6. **Weigh disruption risk.** Long poisoning runs can break legitimate connections and get noticed. Scope the duration and timing of Responder runs to the assessment's rules of engagement.
7. **Treat typos and short-name usage as your reliable entry point.** This isn't a one-time exploit of a misconfiguration; it's an ongoing byproduct of normal human behaviour and legacy scripts, so leaving Responder running over time tends to pay off even on reasonably well-administered networks.

### Key takeaway

This entire class of attack exists because **Windows silently falls back to insecure, unauthenticated broadcast protocols (LLMNR/NBT-NS/WPAD) whenever primary DNS resolution doesn't immediately succeed** — which happens constantly due to typos, short names, legacy scripts, and stale records. Responder doesn't break DNS; it simply answers the broadcasts DNS failure triggers, faster and more convincingly than silence. The real decision point for an offsec engineer is **capture-and-crack vs. relay**, and that choice should be driven by what you already know about the environment (SMB signing status, account privileges), not by which is more "advanced."

## 🧭 Methodology

```text
Internal/LAN presence (rogue device)
  ↓
Responder -I <iface> (passive, let it run)
  ↓
Capture NTLMv2-SSP → crack (-m 5600) for creds
  ↓
With foothold: enumerate → check SMB signing
  ↓
Targeted relay (privileged account → unsigned target)
```

## 🛠️ Techniques

### LLMNR/NBT-NS/WPAD Poisoning (Responder)

- Description: Answer fallback broadcasts and capture NTLMv2-SSP hashes.
- When to use: Any internal/LAN access; run passively alongside recon.
- Command: `sudo responder -I <interface>`

### Offline Cracking (NTLMv2-SSP)

- Description: Crack captured responses to recover passwords.
- When to use: Hashes captured, no relay target yet.
- Command: `hashcat -m 5600 <hash file> <password file> --force`

### NetNTLM Relay

- Description: Forward live challenge/response to a real target for a session without cracking.
- When to use: Known privileged account + unsigned-SMB target; never blind.
- Command: (relay tooling — e.g. ntlmrelayx — to be added with lab material)

## 💻 Commands

```bash
# Poison + capture
sudo responder -I <interface>

# Crack NTLMv2-SSP
hashcat -m 5600 <hash file> <password file> --force
```

## 🧪 Labs

| Lab / Box | Key Learning | Status |
|-----------|:------------:|:------:|
| | | |

## 📇 Cheatsheet

- Fallback broadcasts (LLMNR/NBT-NS/WPAD, on by default) = unauthenticated answers → Responder
- `responder -I <iface>` → NTLMv2-SSP → `hashcat -m 5600`
- Relay needs: SMB signing **not enforced** + relayed account with real rights → enumerate first, never blind
- Poisoning disrupts legit traffic — scope timing

---

[⬅ AD Domain](../README.md) | [📁 Breaching AD](./README.md) | [🏠 Dashboard](../../README.md)