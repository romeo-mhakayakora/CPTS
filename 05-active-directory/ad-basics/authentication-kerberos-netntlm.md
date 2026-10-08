# Authentication Methods in Windows Domains

> [⬅ AD Domain](../README.md) | [📁 AD Basics](./README.md) | [🏠 Dashboard](../../README.md)

| HTB Progress | Notes | Practical Labs | CPTS Confidence |
|:------------:|:-----:|:--------------:|:---------------:|
| — | Started | — | — |

**Status:** 🔄 In Progress

---

## 📌 Concepts

### 1. Overview

- All domain credentials are stored on the Domain Controllers.
- When a user authenticates to a service with domain credentials, the service must ask the DC to verify them.
- Two protocols are used for network authentication:

| Protocol | Status |
|---|---|
| Kerberos | Default in any recent version of Windows and any recent domain |
| NetNTLM | Legacy protocol kept for compatibility. Considered obsolete, but most networks have both enabled |

### 2. Kerberos

- Users receive tickets, which act as proof of a previous authentication.
- Presenting a ticket to a service shows you've already authenticated to the network.

#### Key terms

| Term | Meaning |
|---|---|
| KDC (Key Distribution Center) | Service, usually on the DC, that creates Kerberos tickets |
| TGT (Ticket Granting Ticket) | Lets the user request further tickets without re-sending credentials |
| Session Key | Given to the user with the TGT, needed to generate the following requests |
| krbtgt account | Account whose password hash encrypts the TGT |
| TGS (Ticket Granting Service ticket) | Ticket valid only for one specific service |
| SPN (Service Principal Name) | Identifies the service and server name the user wants to access |
| Service Session Key | Given with the TGS, needed to authenticate to the service |
| Service Owner | The user or machine account the service runs under |

#### Authentication flow

**Step 1: Get a TGT (user to KDC)**

- The user sends their username and a timestamp, encrypted with a key derived from their password.
- The KDC returns a TGT and a Session Key.
- The TGT is encrypted with the krbtgt account's password hash, so the user cannot read its contents.
- The TGT contains a copy of the Session Key, so the KDC doesn't need to store it. It can recover it by decrypting the TGT.

**Step 2: Get a TGS (user to KDC)**

The user sends:

- Their username and a timestamp, encrypted with the Session Key
- The TGT
- The SPN of the target service

- The KDC returns a TGS and a Service Session Key.
- The TGS is encrypted with a key derived from the Service Owner's hash.
- The TGS contains a copy of the Service Session Key, so the Service Owner can get it by decrypting the TGS.

**Step 3: Authenticate to the service (user to service)**

- The user sends the TGS to the service.
- The service decrypts it with its configured account's password hash and validates the Service Session Key.
- The connection is established.

**Flow summary**

```text
User --(username + timestamp enc. with password-derived key)--> KDC
User <--(TGT [enc. with krbtgt hash] + Session Key)------------ KDC

User --(username + timestamp enc. with Session Key + TGT + SPN)--> KDC
User <--(TGS [enc. with Service Owner hash] + Service Session Key)- KDC

User --(TGS)--> Service
Service decrypts TGS with its own account hash, validates Service Session Key
```

**Why the TGT step exists**

- A ticket is needed to get more tickets so users can request service tickets without passing their credentials every time.

### 3. NetNTLM Authentication

#### Overview

- NetNTLM is the legacy protocol, kept for compatibility.
- It works as a challenge-response mechanism.
- The user's password (or hash) is never transmitted over the network.

#### Authentication flow (domain account)

1. **Request:** the client sends an authentication request to the server it wants to access.
2. **Challenge:** the server generates a random number and sends it to the client as a challenge.
3. **Response:** the client combines its NTLM password hash with the challenge (and other known data) to generate a response, and sends it back to the server.
4. **Forward:** the server forwards the challenge and the response to the Domain Controller for verification.
5. **Verification:** the DC uses the challenge to recalculate the response and compares it to the one the client sent.
   - Match: the client is authenticated.
   - No match: access is denied.
   - The result is sent back to the server.
6. **Result:** the server forwards the authentication result to the client.

**Flow summary**

```text
Client --(auth request)--------------------------> Server
Client <--(random challenge)----------------------- Server
Client --(response = NTLM hash + challenge + data)-> Server
Server --(challenge + response)-------------------> DC
Server <--(authenticated / denied)----------------- DC
Client <--(result)--------------------------------- Server
```

> Note: The described process applies when using a domain account. If a local account is used, the server can verify the response to the challenge itself without requiring interaction with the domain controller since it has the password hash stored locally on its SAM.

#### Local accounts

- If a local account is used, the server verifies the response itself, with no DC involved.
- This works because the server has the password hash stored locally in its SAM.

### 4. Kerberos vs NetNTLM

| | Kerberos | NetNTLM |
|---|---|---|
| Status | Default, modern | Legacy, kept for compatibility |
| Model | Ticket-based (TGT, TGS) | Challenge-response |
| Who verifies | Service validates the TGS with its own account's hash | DC recalculates the response (domain accounts) or the server checks the SAM (local accounts) |
| Credential on the wire | Encrypted timestamps and tickets | Only the challenge response |

### 5. Why Kerberos Became the Preferred Protocol

> Note: The source only says Kerberos is the default and NetNTLM is legacy and "obsolete." The reasons below are additions from general knowledge, except where marked as source-derived.

#### Reasons from the source's own flows

- **Reusable proof of identity:** After one login, the user holds a TGT and can request service tickets without passing credentials each time. NetNTLM runs a full challenge-response for each authentication.
- **Less load on the DC per connection:** In NetNTLM, the server forwards the challenge and response to the DC every time. In Kerberos, once the client has a TGS, the service validates it itself with its own account's hash, with no DC call at that step.
- **Secrets stay out of the exchange:** In Kerberos, the user's password-derived key only proves identity to the KDC. After that, session keys and tickets do the work.

#### Reasons from general knowledge

| Factor | Kerberos | NetNTLM |
|---|---|---|
| Mutual authentication | Can verify both client and server | Authenticates the client only. The client can't confirm the server is genuine |
| Cryptography | Supports modern encryption, including AES | Based on the older NT hash (MD4-derived, unsalted) and challenge responses that are weaker against offline cracking |
| Ticket lifetime | Tickets are time-limited and timestamped, which limits replay | No ticket concept, and responses can be captured and relayed |
| Single sign-on | Built around ticket reuse | Each service access needs its own exchange |
| Delegation | Supports controlled delegation of identity to services | Limited |
| Standardisation | Open standard (RFC 4120), widely implemented | Microsoft proprietary |

#### Why NetNTLM is still around

- **Compatibility:** older systems and applications only support it.
- **Fallback:** Kerberos needs working name resolution and valid SPNs, so access by IP address or to non-domain systems often falls back to NetNTLM.
- **Local accounts and workgroups:** there's no KDC, so NetNTLM is used.
- **Legacy configs:** many networks never disabled it, which is why most networks have both enabled.

> Important caveat: "Preferred" doesn't mean "immune." Kerberos has its own attack classes, and NetNTLM has well-known weaknesses such as relaying and offline cracking of captured responses.

### 6. Server Spoofing Issue

> Yes — in NetNTLM the server issues a challenge and the client answers it, but nothing makes the server prove it is the real one. That's a server spoofing problem.

#### Why NetNTLM is exposed to this

- **One-way authentication:** only the client proves itself. A rogue server can accept the connection, send a challenge, and receive a valid response, and the client has no means of knowing the server is fake.
- **The response is usable:** the captured response (NetNTLM hash) can be cracked offline or relayed to a real server.
- **Relay works because the server is just a middleman:** it forwards the challenge and response to the DC. An attacker sitting in that position can pass your response on to another target and authenticate as you.

#### How Kerberos addresses it

- **Mutual authentication:** the service can prove it is genuine because only the real service holds the key needed to decrypt the TGS. A fake server can't complete the exchange.
- **Tickets are bound to an SPN:** a TGS is issued for one specific service, so it isn't valid against a different one.
- **Timestamps and short lifetimes limit replay.**

> Caveat: Kerberos doesn't remove spoofing risk entirely. It relies on correct SPNs and name resolution, and it can fall back to NetNTLM when those fail, which keeps the weakness alive in practice.

### 7. Quick recall

- Credentials live on the DC, and services ask the DC to verify them.
- Kerberos = default and ticket-based. NetNTLM = legacy, but often still enabled.
- KDC (on the DC) issues tickets.
- TGT is encrypted with the krbtgt hash, and the user can't read it.
- TGS is encrypted with the Service Owner's hash, and it is specific to one service (identified by its SPN).
- Session Key is used to request a TGS. Service Session Key is used to authenticate to the service.
- NetNTLM = legacy challenge-response: server issues random challenge, client answers with NTLM hash + challenge, DC recalculates (domain) or server checks SAM (local). Password/hash never sent, only response.
- Kerberos preferred: tickets (reuse/SSO), no DC call per service check, mutual auth, stronger crypto, time-limited tickets.
- NetNTLM persists: compatibility, IP-based access, local/workgroup accounts. Legacy ≠ gone.
- NetNTLM = client-only auth → rogue server possible → cracking + relay. Kerberos = mutual auth, SPN-bound tickets. Fallback keeps issue relevant.

### 8. Open items

- NetNTLM "other known data" in the response is not detailed in source — not added.
- Offsec layer (which account's hash matters at each step, relay/cracking details) can be added as separate labelled section on request.

## 🧭 Methodology

```text
Identify auth protocol (Kerberos vs NetNTLM / fallback)
  ↓
Map Kerberos flow (TGT → TGS → service, SPN, hashes)
  ↓
Map NetNTLM flow (request → challenge → response → DC/SAM)
  ↓
Check spoofing / relay exposure
```

## 🛠️ Techniques

### Technique 1

- Description:
- When to use:
- Command:

## 💻 Commands

```bash
# TODO: Kerberos / NetNTLM enumeration and attack commands (to be added with offsec material)
```

## 🧪 Labs

| Lab / Box | Key Learning | Status |
|-----------|:------------:|:------:|
| | | |

## 📇 Cheatsheet

- Kerberos: TGT (krbtgt) → TGS (service hash, SPN-bound) → service validates itself
- NetNTLM: challenge → response (NTLM hash + challenge) → DC recalculates / SAM checks
- Fallback + relay = why both matter

---

[⬅ AD Domain](../README.md) | [📁 AD Basics](./README.md) | [🏠 Dashboard](../../README.md)