# Breaching Active Directory (Intro) and Initial Credentials via OSINT and Phishing

> [⬅ AD Domain](../README.md) | [📁 Breaching AD](./README.md) | [🏠 Dashboard](../../README.md)

| HTB Progress | Notes | Practical Labs | CPTS Confidence |
|:------------:|:-----:|:--------------:|:---------------:|
| — | Started | — | — |

**Status:** 🔄 In Progress

---

## 📌 Concepts

### 1. Why AD is the target

- AD is used by roughly **90% of Global Fortune 1000 companies**. If an estate uses Windows, you're almost guaranteed to find AD.
- It's the dominant suite for managing Windows domain networks.
- It handles **Identity and Access Management for the entire estate**, so it "holds the keys to the kingdom" and is a very likely target.
- Prerequisite: the AD basics material.

### 2. Goal of this phase: initial access

- Before exploiting misconfigurations for **privilege escalation, lateral movement and goal execution**, you need **initial access**: a first set of **valid AD credentials**.
- **Privilege level doesn't matter** at this stage. Even a low-privileged account works, because the aim is just to **authenticate to AD** so you can do further enumeration.
- The attack surface for getting that first credential set is usually large.

#### Techniques covered in this phase

| Technique | Notes |
|---|---|
| NTLM authenticated services | Also useful for testing whether credentials are valid |
| LDAP bind credentials | |
| Authentication relays | |
| Microsoft Deployment Toolkit (MDT) | |
| Configuration files | |

- The list is **not exhaustive**, since new methods are discovered constantly.
- **Delivery:** target **internet-facing systems**, or **implant a rogue device** on the organisation's network.

### 3. OSINT

**Definition:** discovering information that has been **publicly disclosed**.

#### How AD credentials leak publicly

| Source | Example |
|---|---|
| **Public forums** | Users post questions on Stack Overflow and include credentials |
| **Code repositories** | Developers upload scripts to GitHub with **hardcoded credentials** |
| **Past breaches** | Employees signed up to external sites with **work accounts**, so their credentials appear in breach data |

#### Breach-check platforms

- **HaveIBeenPwned**
- **DeHashed**
- Both let you check whether someone's information (such as a work email) appeared in a known public breach.

#### Key caveat

- OSINT data can be **outdated**, so found credentials must be **validated**.
- NTLM authenticated services is a good way to test whether credentials are still valid.
- Further reading: Red Team OSINT (Red Team Recon) room.

### 4. Phishing

**Two common approaches:**

1. Entice users to **enter credentials on a malicious web page**.
2. Entice users to **run an application** that installs a **Remote Access Trojan (RAT)** in the background.

#### Why it's effective

- The RAT runs **in the user's context**, so you can **immediately impersonate that user's AD account**.
- This is why phishing is a major topic for both **red and blue teams**.
- Further reading: the TryHackMe phishing module.

### 5. Quick recall

- Goal: **any valid AD credential**, not necessarily a privileged one.
- AD = identity for the whole estate, hence the prime target.
- Two entry paths covered here: **OSINT** (forums, GitHub, breach data) and **phishing** (credential harvesting page or RAT).
- **Always validate** OSINT-found credentials, since they may be stale.
- Credential validation route: NTLM authenticated services (next section).
- Access routes: **internet-facing systems** or a **rogue device** on the internal network.

### 6. Open items

- The five listed techniques are only named here. Each will be added as separate notes when source material arrives.
- Question prompts and overlapping intro text from the source were skipped/merged.

## 🧭 Methodology

```text
OSINT / Phishing / Network exposure
  ↓
First valid AD credential (any privilege level)
  ↓
Validate via NTLM authenticated services
  ↓
Proceed to enumeration
```

## 🛠️ Techniques

### OSINT Credential Discovery

- Description: Find leaked work credentials in forums, repos, breach data.
- When to use: First step before touching the network.
- Command: GitHub hardcoded-cred search; HaveIBeenPwned / DeHashed with work emails.

### Phishing (credential page / RAT)

- Description: Harvest creds or run a RAT in user context to impersonate the AD account.
- When to use: OSINT dry and targets need a human element.
- Command: (lab-specific — see phishing module notes)

## 💻 Commands

```bash
# TODO: credential validation against NTLM auth services (next section)
```

## 🧪 Labs

| Lab / Box | Key Learning | Status |
|-----------|:------------:|:------:|
| | | |

## 📇 Cheatsheet

- Breach AD = get **any** valid cred (low priv OK) → validate → enumerate
- OSINT leaks: forums / GitHub / breach data → validate before use
- Phishing: fake login page **or** RAT → impersonate user
- Delivery: internet-facing systems or rogue device on LAN

---

[⬅ AD Domain](../README.md) | [📁 Breaching AD](./README.md) | [🏠 Dashboard](../../README.md)