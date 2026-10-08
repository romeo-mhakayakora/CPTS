# Windows Domains and Active Directory (Intro)

> [⬅ AD Domain](../README.md) | [📁 AD Basics](./README.md) | [🏠 Dashboard](../../README.md)

| HTB Progress | Notes | Practical Labs | CPTS Confidence |
|:------------:|:-----:|:--------------:|:---------------:|
| — | Started | — | — |

**Status:** 🔄 In Progress

---

## 📌 Concepts

### Core concepts

| Term | Meaning |
|------|---------|
| Windows domain | A group of users and computers under one organization's administration |
| Active Directory (AD) | Central repository for identity and configuration of domain objects (users, computers, groups, policies) |
| Domain Controller (DC) | The server running AD services |

### Why domains exist

Problem: Managing machines individually (local accounts, per-machine config, on-site support) doesn't scale. Example: 5 computers vs. 157 computers and 320 users across 4 offices.

- **Centralised identity management:** Users are created and configured once in AD and work across the network.
- **Centralised security policy:** Policies are defined in AD and pushed to users and computers as needed.

### How authentication works

1. A user enters credentials on any domain-joined machine.
2. The machine forwards authentication to AD (the DC).
3. The DC validates the credentials. They don't need to exist locally on each machine.

Policies applied from AD can restrict what users do, such as blocking Control Panel access or removing local admin rights on university machines.

### Offsec takeaways

> My additions — key attacker perspective, not in the source text.

- **The DC is the crown jewel.** It holds the identity data for the whole domain, so compromising it means compromising everything. Most internal engagements aim at domain admin or DC access.
- **Domain credentials work across many machines.** One captured credential can enable lateral movement wherever that account has access.
- **Policy-based restrictions are not security boundaries by themselves.** Restrictions like a blocked Control Panel are often bypassable, so test them rather than assuming they hold.
- **Centralisation concentrates risk.** A misconfiguration in AD or a policy affects every machine and user it touches.

> Where this leads next: Expect upcoming material on AD objects (users, groups, OUs), Group Policy Objects (GPOs), authentication protocols (Kerberos and NetNTLM), and trust relationships between domains.

## 🧭 Methodology

<!-- Step-by-step workflow for this topic. -->

```text
Understand domain vs workgroup
  ↓
Identify DC and AD role
  ↓
Map authentication flow
  ↓
Note policy enforcement points
  ↓
Link to enumeration / attacks
```

## 🛠️ Techniques

<!-- Individual techniques with when/why to use each. -->

### Technique 1

- Description:
- When to use:
- Command:

## 💻 Commands

<!-- Copy-paste ready command reference. -->

```bash
# TODO: add commands for this topic
```

## 🧪 Labs

<!-- HTB labs / boxes practiced, what worked, what failed. -->

| Lab / Box | Key Learning | Status |
|-----------|:------------:|:------:|
| | | |

## 📇 Cheatsheet

<!-- Ultra-condensed quick reference for exam-time recall. -->

- Domain = central admin boundary | AD = identity store | DC = server running AD
- DC compromise = domain compromise
- One domain cred → lateral movement everywhere it has access

---

[⬅ AD Domain](../README.md) | [📁 AD Basics](./README.md) | [🏠 Dashboard](../../README.md)
