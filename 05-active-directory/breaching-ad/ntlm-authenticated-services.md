# Breaching AD via NTLM Authenticated Services

> [⬅ AD Domain](../README.md) | [📁 Breaching AD](./README.md) | [🏠 Dashboard](../../README.md)

| HTB Progress | Notes | Practical Labs | CPTS Confidence |
|:------------:|:-----:|:--------------:|:---------------:|
| — | Started | — | — |

**Status:** 🔄 In Progress

---

## 📌 Concepts

### 1. Where NetNTLM shows up as an attack surface

NetNTLM authentication isn't limited to internal services; it's commonly exposed in ways reachable from outside a network. Typical examples:

- Internally-hosted **Exchange/OWA** login portals exposed to the internet.
- **RDP** services exposed to the internet.
- **VPN endpoints** integrated with AD.
- Internet-facing **web applications** using NetNTLM (often labelled "Windows Authentication").

**Why this matters:** each of these services acts as a **middleman** that forwards the client's authentication attempt to a Domain Controller as a challenge. The DC decides success or failure; the service just relays the result back. This means **any exposed NetNTLM service is effectively a remote credential-check against the DC**, usable without first having internal network access.

### 2. Use case 1: validating credentials found elsewhere

- Exposed NetNTLM services are a good place to **test credentials recovered through other means** (OSINT, breach dumps, previous engagements), since such credentials may be stale or unverified.
- A quick auth attempt against one of these services confirms whether a credential pair still works, before investing further effort.

### 3. Use case 2: password spraying

#### Why spraying, not brute force

- Most AD environments have **account lockout policies**.
- A full brute force (many passwords against one user) risks **locking accounts** and alerting defenders quickly.
- **Password spraying** flips the approach: **one password, tried across many usernames**, which stays under most per-account lockout thresholds.
- **Detection risk:** still generates many failed authentication attempts and can be picked up by monitoring, so this isn't silent.

#### What you need

- A list of **candidate usernames**.
- One or more **candidate passwords**, chosen from recon or common patterns.

#### How validity is typically detected

Exposed web apps using Windows Authentication usually return a distinct response for success vs. failure:

| Response | Meaning |
|---|---|
| **200 OK (or similar success response)** | Valid credential pair |
| **401 Unauthorized** | Invalid credential pair |

- For RDP, VPN or OWA, the equivalent signal is a successful login vs. an explicit rejection message.

#### General execution principles

- Try **one password across the full username list** per round, never several passwords against one user in sequence.
- **Space rounds out over time** (hours or days apart, aligned with the lockout reset window if known), to reduce lockout and detection risk.
- Prefer scripted, controlled attempts over tools that fire many requests in bursts, so you can throttle and log results deliberately.
- Browser-based manual testing of Windows Authentication prompts can be unreliable in some browsers; cross-check with a different browser if a login unexpectedly fails.

### 4. Outcome

- Confirming or spraying credentials against an exposed NetNTLM service yields a **first valid AD credential**, which becomes the foothold for further AD enumeration (LDAP queries, SMB access, Kerberos interaction, etc.).

---

## Strategy: Gaining Initial Access via NTLM-Authenticated Services

### When you already have leads (usernames, possible passwords)

1. **Recon:** gather valid usernames and any likely passwords through OSINT (forums, code repos, breach data, employee lists, onboarding conventions).
2. **Find NetNTLM-exposed surfaces:** OWA, RDP, VPN portals, or internet-facing web apps using Windows Authentication.
3. **Validate leads first:** test any candidate credentials against an exposed NetNTLM service before trying anything noisier.
4. **If no valid creds yet, password spray:** one password across all usernames, never many passwords per user.
5. **Throttle attempts** to reduce lockout and detection risk.
6. **On success:** treat the account as a foothold only, regardless of its privilege level, and move to AD enumeration.
7. **Repeat across other exposed services** (OWA, VPN, RDP) if one route fails, since they share the same underlying authentication weakness.

### When you have nothing (no usernames, no password lead)

#### No usernames

- **Derive a username list from naming conventions**, once you know or guess the company's format:
  - `first.last`, `flast`, `firstl`, `first` — combined with real employee names from LinkedIn, the company's team page, press releases, or conference speaker lists.
- **Enumerate usernames against the service itself**, where it responds differently for valid vs. invalid usernames independent of the password. Some login portals and related protocols (such as Kerberos pre-authentication) leak this distinction, letting you build a verified username list before spraying.
- **Check breach-dump and paste sites by email domain**, even without an OSINT hit on a specific individual, since a domain-wide search can surface employee emails nobody intentionally disclosed.

#### No password lead

- Fall back to **generic, high-probability corporate passwords**, since many organisations follow predictable patterns:
  - Seasonal/year patterns: `Summer2026!`, `Autumn2025!`
  - Company name plus a common suffix: `Companyname1!`, `CompanyName123`
  - Common default or onboarding words: `Welcome1`, `Password1`, `Changeme1`
- **Spray multiple candidate passwords, but space the rounds out over time** rather than trying several in quick succession, to stay under lockout thresholds and remain quieter.
- Only ever try **one password per round across the whole username list**, never multiple passwords per user back-to-back.

### General principle either way

An exposed NetNTLM service is usable as a **credential oracle**: it answers success or failure regardless of where the guesses came from. Without OSINT, more of the work shifts to **intelligently guessing or enumerating usernames and passwords**, and to being disciplined about pacing to avoid lockouts and detection.

### Key takeaway

The exploitable idea isn't a flaw in NetNTLM itself. It's that **any exposed service using it is effectively a remote authentication check against the DC**. Username enumeration/OSINT and password selection are the real force multipliers; the mechanism of testing credentials against the service is simple once a target surface is found.

---

## 🧭 Methodology

```text
Recon usernames/passwords (OSINT or conventions)
  ↓
Find NetNTLM-exposed surfaces (OWA / RDP / VPN / Windows Auth web)
  ↓
Validate leads → 200 OK vs 401
  ↓
Else spray: 1 password × all users, spaced rounds
  ↓
First valid cred → AD enumeration
```

## 🛠️ Techniques

### Credential Validation

- Description: Test OSINT/breach creds against exposed NetNTLM service.
- When to use: You have candidate pairs and need to confirm they're live.
- Command: Auth attempt → 200 OK = valid, 401 = invalid.

### Password Spraying

- Description: One password across many usernames per round.
- When to use: Leads exhausted, lockout policies must be respected.
- Command: Scripted, throttled rounds spaced by lockout reset window; one password per round.

## 💻 Commands

```bash
# TODO: add spraying/validation tooling (e.g. medusa/hydra/nxc/netexec) when lab material provided
```

## 🧪 Labs

| Lab / Box | Key Learning | Status |
|-----------|:------------:|:------:|
| | | |

## 📇 Cheatsheet

- Exposed NetNTLM service = remote credential oracle against the DC
- Validate: 200 OK = valid / 401 = invalid (Windows Auth)
- Spray: **1 password × all users**, rounds spaced over hours/days — never many passwords per user
- Naming conventions: `first.last`, `flast`, `firstl`, `first` | corp passwords: season+year, `Company1!`, `Welcome1`
- Success = foothold only (any priv) → enumerate

---

[⬅ AD Domain](../README.md) | [📁 Breaching AD](./README.md) | [🏠 Dashboard](../../README.md)