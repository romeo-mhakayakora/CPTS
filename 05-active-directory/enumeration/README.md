# 🟦 Active Directory Enumeration

> Mapping the domain once you hold any valid credential — users, groups, trusts, SPNs and attack paths.
>
> [⬅ Back to AD Domain](../README.md) | [🏠 Dashboard](../../README.md)

## Modules

| Module | Status | Notes |
|--------|:------:|:-----:|
| [Overview](./overview.md) | ⬜ | [📖](./overview.md) |

> Planned sections (waiting for source material): LDAP enumeration, Kerberos enumeration (SPNs, AS-REP), SMB/NetExec enumeration, BloodHound collection & analysis.

## 🎯 Folder Goal

```text
Valid AD credential (any privilege)
              ↓
   Enumerate users / groups / computers
              ↓
   Map trusts / SPNs / delegation / GPOs
              ↓
   BloodHound attack paths
              ↓
   Feed into attacks / lateral movement
```

## Readiness Checklist

- [ ] Enumerate systematically (users, groups, computers, trusts, SPNs)
- [ ] Run LDAP searches with low-privileged creds
- [ ] Collect and analyse BloodHound data
- [ ] Identify Kerberoastable / AS-REP-roastable accounts
- [ ] Map delegation and GPO attack surface
- [ ] Document commands and evidence

---

[⬅ Back to AD Domain](../README.md) | [🏠 Dashboard](../../README.md)