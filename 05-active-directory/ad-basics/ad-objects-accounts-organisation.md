# Active Directory Objects, Accounts and Organisation

> [⬅ AD Domain](../README.md) | [📁 AD Basics](./README.md) | [🏠 Dashboard](../../README.md)

| HTB Progress | Notes | Practical Labs | CPTS Confidence |
|:------------:|:-----:|:--------------:|:---------------:|
| — | Started | — | — |

**Status:** 🔄 In Progress

---

## 📌 Concepts

### 1. Active Directory Domain Service (AD DS)

- The core of any Windows domain.
- Acts as a **catalogue of all "objects"** on the network: users, groups, machines, printers, shares and others.

### 2. Security principals

A **security principal** is an object that can be authenticated by the domain and can be assigned privileges over resources (files, printers, etc.). In short, it can act upon resources in the network.

**Security principals:** users, machines, security groups.

### 3. Object types

#### Users

- One of the most common object types.
- They represent two kinds of entities:
  - **People:** employees or others who need network access.
  - **Services:** accounts for services like IIS or MSSQL. Every service needs a user to run. Service users have only the privileges needed for their specific service.

#### Machines

- A machine object is created for every computer that joins the domain.
- Machines are security principals with their own account, which has somewhat limited rights within the domain.
- The account is a **local administrator on its assigned computer**.
- It isn't meant to be used by anyone except the computer itself, but **if you have the password, you can log in with it**.
- **Password:** rotated automatically, generally 120 random characters.
- **Naming scheme:** computer name + `$`. Example: machine `DC01` has the account `DC01$`.

**What "logging in" as a machine account means:**

- It means authenticating to the network as the computer itself, not as a human.
- Normally this happens in the background. The computer uses its account and password to prove its identity to the DC, for example to fetch group policies and updates before any user logs in.
- Doing it manually requires the account's password or hash.
- It gives you that machine's permissions: local admin control of that computer, and the ability to interact with other domain resources as a trusted machine.

#### Security groups

- Assign access rights to a group instead of to individual users. Members inherit the group's privileges, which makes management easier.
- Groups are security principals, so they can hold privileges over network resources.
- Members can be **users, machines, or other groups**.

### 4. Default security groups

| Group | Official description | Plain-English meaning |
|---|---|---|
| **Domain Admins** | Administrative privileges over the entire domain. Can administer any computer, including DCs. | Full control of everything |
| **Server Operators** | Can administer DCs. Cannot change administrative group memberships. | Manage the critical servers, but can't promote anyone to admin |
| **Backup Operators** | Can access any file, ignoring its permissions. Used for backups. | Can read and copy any file |
| **Account Operators** | Can create or modify other accounts in the domain. | Manage user accounts |
| **Domain Users** | All existing user accounts in the domain. | Every normal user |
| **Domain Computers** | All existing computers in the domain. | Every joined machine |
| **Domain Controllers** | All existing DCs in the domain. | Only the AD servers |

The complete list of default groups is in the Microsoft documentation.

### 5. Organizational Units (OUs)

- **Container objects** used to classify users and machines.
- Mainly used to define sets of users with **similar policy requirements** (for example, Sales and IT get different policies).
- **A user can only be in one OU at a time.**
- OUs commonly mirror the business structure, which makes it efficient to deploy baseline policies to whole departments. They can be defined arbitrarily, though.
- **Example:** an OU named `THM` with five child OUs: IT, Management, Marketing, R&D, Sales.

### 6. Active Directory Users and Computers (ADUC)

- Tool for managing users, groups and machines.
- **Access:** log in to the Domain Controller, then run "Active Directory Users and Computers" from the Start menu.
- Shows the hierarchy of users, computers and groups, organised by OU.
- **Tasks:** create, delete or modify objects, create OUs (right-click an OU), and **reset passwords** (useful for the helpdesk).

### 7. Default containers (created automatically by Windows)

| Container | Contents |
|---|---|
| **Builtin** | Default groups available to any Windows host |
| **Computers** | Default location for any machine joining the network (can be moved) |
| **Domain Controllers** | Default OU containing the DCs |
| **Users** | Default users and groups (source text cuts off here) |

### 8. Quick recall

- AD DS = catalogue of network objects
- Security principals = users, machines, security groups
- Users = people or services
- Machine account = `COMPUTERNAME$`, 120-character auto-rotated password, local admin on its own computer
- Groups can contain users, machines, and other groups
- OUs = containers for applying policy, one OU per user
- Default containers = Builtin, Computers, Domain Controllers, Users

### 9. Verify before relying on these

These claims aren't in the original source text, and some are oversimplified:

- **"Account Operators can't touch admin accounts."** The source only says they can create or modify other accounts. Check Microsoft's documentation for the exact restrictions.
- **"Machine accounts can impersonate Domain Admins via delegation."** This is true only in specific misconfigurations (such as unconstrained delegation), not by default.
- **"Machine accounts are hidden."** They are visible in AD, and the `$` naming makes them easy to spot.

### 10. Open items

- The **Users** container description was cut off in the source. Send the rest to complete it.
- Two follow-ups were never answered: how machine account passwords or hashes are obtained, and why Backup Operators are a common target. Nothing is added here on either.

## 🧭 Methodology

```text
Identify AD DS role and DC
  ↓
Enumerate users / machines / groups
  ↓
Map OUs and default containers
  ↓
Check privileged groups membership
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

```bash
# TODO: ADUC, PowerView, ldapsearch, netexec, BloodHound collection for objects/OUs/groups
```

## 🧪 Labs

| Lab / Box | Key Learning | Status |
|-----------|:------------:|:------:|
| | | |

## 📇 Cheatsheet

- AD DS = catalogue | Principals = users, machines, groups
- `COMPUTERNAME$` = machine account, local admin on itself
- OUs = policy containers | Default = Builtin, Computers, DCs, Users

---

[⬅ AD Domain](../README.md) | [📁 AD Basics](./README.md) | [🏠 Dashboard](../../README.md)
