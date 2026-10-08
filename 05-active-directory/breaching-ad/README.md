# 🟦 Breaching Active Directory

> Getting the first valid AD credentials — initial access via OSINT, phishing and network-facing services.
>
> [⬅ Back to AD Domain](../README.md) | [🏠 Dashboard](../../README.md)

## Modules

| Module | Status | Notes |
|--------|:------:|:-----:|
| [Breaching AD (Intro) & Initial Credentials via OSINT/Phishing](./breaching-ad-intro.md) | 🔄 | [📖](./breaching-ad-intro.md) |
| [Breaching AD via NTLM Authenticated Services](./ntlm-authenticated-services.md) | 🔄 | [📖](./ntlm-authenticated-services.md) |
| [LDAP, Bind Credentials & Pass-back Attacks](./ldap-bind-passback-attack.md) | 🔄 | [📖](./ldap-bind-passback-attack.md) |

> Planned sections (waiting for source material): Authentication relays, Microsoft Deployment Toolkit (MDT), Configuration files.

## 🎯 Folder Goal

```text
OSINT / Phishing / Network exposure
              ↓
      First valid AD credential
              ↓
   Validate it (NTLM auth services)
              ↓
   Feed into enumeration / attacks
```

## Readiness Checklist

- [ ] Explain why AD is the prime target (IAM for the estate)
- [ ] Run OSINT credential discovery (forums, GitHub, breach data) and validate findings
- [ ] Deliver a phishing attack path (credential page or RAT) conceptually
- [ ] Test credential validity against NTLM-authenticated services
- [ ] Combine with LDAP/relay/MDT/config-file techniques as covered
- [ ] Document commands and evidence

---

[⬅ Back to AD Domain](../README.md) | [🏠 Dashboard](../../README.md)