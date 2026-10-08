# Trees, Forests and Trust Relationships

> [⬅ AD Domain](../README.md) | [📁 AD Basics](./README.md) | [🏠 Dashboard](../../README.md)

| HTB Progress | Notes | Practical Labs | CPTS Confidence |
|:------------:|:-----:|:--------------:|:---------------:|
| — | Started | — | — |

**Status:** 🔄 In Progress

---

## 📌 Concepts

### 1. Why multiple domains

A single domain is fine to start, but growth creates new needs. Examples from the source:

- Expanding to a new country with different laws and regulations, requiring different GPOs.
- Separate IT teams that must manage their own resources without interfering with each other.

This could be done with a complex OU structure and delegation, but a huge AD structure is hard to manage and prone to human error.

AD supports integrating multiple domains, so the network is partitioned into units that can be managed independently.

### 2. Trees

- Tree = domains that share the same namespace, joined together.
- Example: root domain `thm.local` with subdomains `uk.thm.local` and `us.thm.local`. Each has its own AD, computers and users.

#### Benefits

- Better control over who can access what.
- Each branch has its own DC managing only its own resources. A UK user can't manage US users.
- Domain Admins of each branch have full control over their own DCs, but not other branches' DCs.
- Policies can be configured independently per domain in the tree.

#### Enterprise Admins

- New security group introduced with trees and forests.
- Grants administrative privileges over all domains in the enterprise.
- Each domain still has its own Domain Admins (power over that single domain only).

| Group | Scope |
|---|---|
| Domain Admins | One domain |
| Enterprise Admins | All domains in the enterprise |

### 3. Forests

- Forest = the union of several trees with different namespaces in the same network.
- Example: after acquiring MHT Inc., the company has two trees (`thm.local` and the MHT tree), each managed by its own IT department.

### 4. Trust relationships

- Domains in trees and forests are joined by trust relationships.
- A trust lets you authorise a user from one domain to access resources in another. Example: a user in THM UK accessing a shared file on a server in an MHT domain.

#### One-way trust

- If Domain AAA trusts Domain BBB, a user on BBB can be authorised to access resources on AAA.
- The direction of the trust is opposite to the direction of access.

```text
AAA  --trusts-->  BBB
AAA  <--access--  BBB user
```

#### Two-way trust

- Both domains can mutually authorise users from the other.
- By default, joining domains under a tree or forest forms a two-way trust.

#### Important caveat

- A trust does not automatically grant access to all resources in the other domain.
- It only makes cross-domain authorisation possible. What is actually authorised is up to the administrator.

### 5. Quick recall

- Domain = single unit with its own DC, users and computers.
- Tree = domains sharing a namespace (`thm.local`, `uk.thm.local`, `us.thm.local`).
- Forest = multiple trees with different namespaces.
- Enterprise Admins = admin over all domains. Domain Admins = admin over one domain.
- One-way trust: AAA trusts BBB means BBB users can access AAA, so the arrow of trust points opposite to access.
- Two-way trust is the default within a tree or forest.
- Trust is not access. Authorisation is still configured separately.

## 🧭 Methodology

```text
Identify domain / tree / forest boundaries
  ↓
Map DCs per domain
  ↓
Enumerate trusts (direction, type)
  ↓
Check Enterprise Admins / Domain Admins scope
  ↓
Find cross-domain access paths
```

## 🛠️ Techniques

### Technique 1

- Description:
- When to use:
- Command:

## 💻 Commands

```bash
# TODO: trust enumeration (nltest, dsquery, BloodHound trusts) when offsec material added
```

## 🧪 Labs

| Lab / Box | Key Learning | Status |
|-----------|:------------:|:------:|
| | | |

## 📇 Cheatsheet

- Tree = shared namespace | Forest = multiple trees | Enterprise Admins = all domains
- One-way trust arrow = opposite of access direction | Trust ≠ access

---

[⬅ AD Domain](../README.md) | [📁 AD Basics](./README.md) | [🏠 Dashboard](../../README.md)