# Managing AD Users, OUs and Delegation

> [⬅ AD Domain](../README.md) | [📁 AD Basics](./README.md) | [🏠 Dashboard](../../README.md)

| HTB Progress | Notes | Practical Labs | CPTS Confidence |
|:------------:|:-----:|:--------------:|:---------------:|
| — | Started | — | — |

**Status:** 🔄 In Progress

---

## 📌 Concepts

### 1. Scenario

- You are the new domain administrator.
- The AD must be updated to match the company's organisational chart. This means removing extra OUs and users, and creating missing users.
- **The chart's expected state:** Phillip leads IT support.

### 2. Deleting an OU

#### Problem

- Right-clicking an OU and choosing Delete gives an error. OUs are **protected against accidental deletion by default**.

#### Procedure

1. In ADUC, go to the **View** menu and enable **Advanced Features**. This reveals extra containers and the protection setting.
2. Right-click the OU, then choose **Properties**.
3. Open the **Object** tab and **uncheck "Protect object from accidental deletion"**.
4. Delete the OU and confirm the prompt.

#### Warning

- Deleting an OU also **deletes every user, group and OU under it**.

#### Follow-up

- After removing the extra OU (a closed department in this scenario), compare each department's users to the chart. **Create or delete users as needed** to match.

### 3. Delegation

- **Delegation** gives specific users control over specific OUs, so they can perform advanced tasks without a Domain Admin stepping in.
- **Common use case:** letting IT support reset passwords for low-privilege users.
- **Scenario:** Phillip (IT support) gets password-reset rights over the Sales, Marketing and Management OUs. The walkthrough does Sales only, and the other two are optional.

#### Procedure

1. In ADUC, right-click the target OU (for example Sales) and choose **Delegate Control**.
2. Enter the user's name (`phillip`) and click **Check Names** so Windows autocompletes it and avoids typos.
3. Click OK, then select the **password reset** task in the wizard.
4. Click Next through the remaining steps and finish.

#### Result

- Phillip can reset passwords for any user in the Sales OU.

### 4. Testing delegation as Phillip

#### Connection

- Log in via RDP using the format `THM\phillip`. The `THM\` prefix specifies the domain account rather than a local user.
- Credentials given in the lab: `phillip` / `Claire2008`.

#### Constraint

- Phillip **cannot open Active Directory Users and Computers**, so the reset must be done through **PowerShell**.

#### Commands

**Reset the password** (prompts for the new password as a secure string):

```powershell
Set-ADAccountPassword sophie -Reset -NewPassword (Read-Host -AsSecureString -Prompt 'New Password') -Verbose
```

**Force a change at next logon** (so the user doesn't keep a password you know):

```powershell
Set-ADUser -ChangePasswordAtLogon $true -Identity sophie -Verbose
```

#### Output detail worth noting

- The verbose output shows the target's **distinguished name (DN)**: `CN=Sophie,OU=Sales,OU=THM,DC=thm,DC=local`
  - `CN` = common name (the object)
  - `OU` = organizational units, from innermost to outermost
  - `DC` = domain components (`thm.local`)

### 5. Final step

- Log in as Sophie (`THM\sophie`) with the new password and retrieve the flag from her desktop.

### 6. Quick recall (Users, OUs, Delegation)

- OU delete fails by default: enable **Advanced Features**, then uncheck the **Object tab** protection.
- Deleting an OU deletes everything beneath it.
- **Delegate Control** (right-click OU) grants task-specific rights over that OU without Domain Admin.
- Delegated users can use the **ActiveDirectory PowerShell cmdlets** even without ADUC access.
- `Set-ADAccountPassword -Reset` resets a password. `Set-ADUser -ChangePasswordAtLogon $true` forces a change at next logon.
- RDP domain login format: `DOMAIN\username`.
- Computers default: non-DCs → **Computers** container, DCs → **Domain Controllers** OU — move them out for proper policy.
- Workstations (most common, no priv logons) / Servers (different policy) / DCs (most sensitive, hold all hashes).

### 7. Open items

- The source only demonstrates delegation for Sales. Repeating it for Marketing and Management is left as an optional exercise.
- If you want a more offsec-oriented layer (for example, how delegation misconfigurations show up in enumeration), tell me and I'll add it as a separate, clearly labelled section.

---

## Managing Computers in AD

### 8. Default behaviour

- Every machine that joins a domain (except DCs) lands in the **Computers** container by default.
- DCs go to the **Domain Controllers** OU, created by Windows.
- Leaving everything in Computers is poor practice, because servers and user devices usually need different policies.

### 9. Device categories

There is no golden rule for organising machines. A good starting point is to segregate by use, into at least three categories:

| Category | Description | Key points |
|---|---|---|
| **Workstations** | The device each user logs into for daily work and browsing. Most common device type in a domain. | Should never have a privileged user signed into them. |
| **Servers** | Provide services to users or other servers. Second most common. | Often need different policies from workstations. |
| **Domain Controllers** | Manage the AD domain. Third most common. | Considered the most sensitive devices in the network because they contain hashed passwords for all user accounts in the environment. |

## 🧭 Methodology

```text
Match AD to org chart (create/delete users + OUs)
  ↓
Handle OU protection (Advanced Features → uncheck)
  ↓
Delegate Control over target OU
  ↓
Test as delegated user (RDP DOMAIN\user + PowerShell)
  ↓
Force password change at next logon
```

## 🛠️ Techniques

### OU Protection Bypass (Admin)

- Description: Disable accidental-deletion protection to remove stale OUs.
- When to use: Cleaning AD to match org chart.
- Command: ADUC → View → Advanced Features → OU Properties → Object → uncheck protection → Delete.

### Delegated Password Reset (PowerShell)

- Description: Reset OU user password without ADUC / DA.
- When to use: Testing delegation as low-priv user.
- Command:
  ```powershell
  Set-ADAccountPassword sophie -Reset -NewPassword (Read-Host -AsSecureString -Prompt 'New Password') -Verbose
  Set-ADUser -ChangePasswordAtLogon $true -Identity sophie -Verbose
  ```

## 💻 Commands

```bash
# RDP as domain user
# xfreerdp /u:phillip /d:THM /v:<DC-IP>
```

```powershell
# Delegated password reset (no ADUC needed)
Set-ADAccountPassword sophie -Reset -NewPassword (Read-Host -AsSecureString -Prompt 'New Password') -Verbose
Set-ADUser -ChangePasswordAtLogon $true -Identity sophie -Verbose
```

## 🧪 Labs

| Lab / Box | Key Learning | Status |
|-----------|:------------:|:------:|
| THM / AD basics (Phillip → Sophie) | OU delete protection, Delegate Control, PowerShell reset | 🔄 |

## 📇 Cheatsheet

- OU delete blocked → Advanced Features → Object → uncheck protection (deletes subtree)
- Delegate Control = task rights over OU without DA
- `THM\user` = domain logon | `Set-ADAccountPassword -Reset` + `Set-ADUser -ChangePasswordAtLogon $true`
- Computers → **Computers** container by default, DCs → **Domain Controllers** OU — segregate Workstations / Servers / DCs (DCs hold all hashes)

---

[⬅ AD Domain](../README.md) | [📁 AD Basics](./README.md) | [🏠 Dashboard](../../README.md)