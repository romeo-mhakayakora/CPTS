# 05 — 🟦 Active Directory

> Dedicated notes for Active Directory enumeration, attacks, lateral movement and enterprise compromise.
>
> [⬅ Back to CPTS Dashboard](../README.md)

> ℹ️ Previously tracked as `03-network-security/active-directory-enumeration-attacks.md` — that file is kept for history. New detailed notes live here.

## Modules

| Module | Progress | Status | Notes |
|--------|:--------:|:------:|:-----:|
| [AD Basics](./ad-basics/README.md) | — | 🔄 | [📖](./ad-basics/README.md) |
| [Windows Domains and AD (Intro)](./ad-basics/windows-domains-intro.md) | — | 🔄 | [📖](./ad-basics/windows-domains-intro.md) |
| [AD Objects, Accounts and Organisation](./ad-basics/ad-objects-accounts-organisation.md) | — | 🔄 | [📖](./ad-basics/ad-objects-accounts-organisation.md) |
| [Managing AD Users, OUs and Delegation](./ad-basics/managing-users-ous-delegation.md) | — | 🔄 | [📖](./ad-basics/managing-users-ous-delegation.md) |
| [Group Policy Objects (GPOs)](./ad-basics/group-policy-objects.md) | — | 🔄 | [📖](./ad-basics/group-policy-objects.md) |
| [Authentication (Kerberos & NetNTLM)](./ad-basics/authentication-kerberos-netntlm.md) | — | 🔄 | [📖](./ad-basics/authentication-kerberos-netntlm.md) |
| [Trees, Forests and Trust Relationships](./ad-basics/trees-forests-trusts.md) | — | 🔄 | [📖](./ad-basics/trees-forests-trusts.md) |
| [Connecting to the Network and DNS](./ad-basics/network-connection-dns.md) | — | 🔄 | [📖](./ad-basics/network-connection-dns.md) |
| [Breaching AD](./breaching-ad/README.md) | — | 🔄 | [📖](./breaching-ad/README.md) |
| [Breaching AD (Intro) & Initial Credentials](./breaching-ad/breaching-ad-intro.md) | — | 🔄 | [📖](./breaching-ad/breaching-ad-intro.md) |
| [Breaching AD via NTLM Authenticated Services](./breaching-ad/ntlm-authenticated-services.md) | — | 🔄 | [📖](./breaching-ad/ntlm-authenticated-services.md) |
| [LDAP, Bind Credentials & Pass-back Attacks](./breaching-ad/ldap-bind-passback-attack.md) | — | 🔄 | [📖](./breaching-ad/ldap-bind-passback-attack.md) |
| [SMB, LLMNR/NBT-NS/WPAD Poisoning & Relay Attacks](./breaching-ad/smb-llmnr-relay-attacks.md) | — | 🔄 | [📖](./breaching-ad/smb-llmnr-relay-attacks.md) |
| [Credential Recovery from Configuration Files](./breaching-ad/config-file-credential-recovery.md) | — | 🔄 | [📖](./breaching-ad/config-file-credential-recovery.md) |
| [Enumeration](./enumeration.md) | — | ⬜ | [📖](./enumeration.md) |
| [Attacks](./attacks.md) | — | ⬜ | [📖](./attacks.md) |
| [Lateral Movement & Pivoting](./lateral-movement.md) | — | ⬜ | [📖](./lateral-movement.md) |

## 🎯 Domain Goal

```text
Domain Discovery
      ↓
Enumerate Users / Groups / Trusts
      ↓
Find Misconfiguration / Vulnerability
      ↓
Initial AD Foothold
      ↓
Kerberoasting / AS-REP / Password Spray
      ↓
Lateral Movement
      ↓
Privilege Escalation (DA / EA)
      ↓
Domain Compromise
      ↓
Persistence + Reporting
```

## Readiness Checklist

- [ ] Explain AD concepts (domain, forest, trusts, GPO, Kerberos, LDAP, SMB)
- [ ] Enumerate systematically (BloodHound, PowerView, ldapsearch, crackmapexec/netexec)
- [ ] Identify attack opportunities (Kerberoast, AS-REP, delegation, ACL abuse, GPO abuse)
- [ ] Execute attacks (password spray, hash cracking, ticket attacks, relay, lateral movement)
- [ ] Troubleshoot when the obvious approach fails
- [ ] Document commands and evidence
- [ ] Apply the technique in an unfamiliar environment
- [ ] Combine it with pivoting / privesc / enterprise skills

---

[⬅ Back to CPTS Dashboard](../README.md)