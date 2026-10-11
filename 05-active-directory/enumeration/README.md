# 🟦 Active Directory Enumeration

> Mapping the domain once you hold any valid credential — users, groups, trusts, SPNs and attack paths.
>
> [⬅ Back to AD Domain](../README.md) | [🏠 Dashboard](../../README.md)

## Modules

| Module | Status | Notes |
|--------|:------:|:-----:|
| [Overview](./overview.md) | ⬜ | [📖](./overview.md) |
| [Credential Injection & Joining AD from Outside](./credential-injection-runas-netonly.md) | 🔄 | [📖](./credential-injection-runas-netonly.md) |
| [Enumeration via MMC & RSAT](./mmc-rsat-enumeration.md) | 🔄 | [📖](./mmc-rsat-enumeration.md) |
| [Enumeration via CMD & `net` Command](./cmd-net-command-enumeration.md) | 🔄 | [📖](./cmd-net-command-enumeration.md) |
| [Enumeration via PowerShell](./powershell-ad-enumeration.md) | 🔄 | [📖](./powershell-ad-enumeration.md) |
| [Enumeration via BloodHound & SharpHound](./bloodhound-sharphound.md) | 🔄 | [📖](./bloodhound-sharphound.md) |
| [HTB AD Machines (IppSec Walkthroughs)](./htb-ad-machines-ippsec.md) | 🔄 | [📖](./htb-ad-machines-ippsec.md) |

> Planned sections (waiting for source material): LDAP enumeration, Kerberos enumeration (SPNs, AS-REP), SMB/NetExec enumeration.

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