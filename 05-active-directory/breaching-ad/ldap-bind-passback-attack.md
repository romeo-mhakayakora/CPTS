# LDAP, LDAP Bind Credentials, and LDAP Pass-back Attacks

> [⬅ AD Domain](../README.md) | [📁 Breaching AD](./README.md) | [🏠 Dashboard](../../README.md)

| HTB Progress | Notes | Practical Labs | CPTS Confidence |
|:------------:|:-----:|:--------------:|:---------------:|
| — | Started | — | — |

**Status:** 🔄 In Progress

---

## 📌 Concepts

### 1. What LDAP actually is

- **LDAP (Lightweight Directory Access Protocol)** is not a database query language like SQL. It's an **open, vendor-neutral protocol** for talking to a **directory service** — essentially a structured "phonebook."
- In a Windows environment, **Active Directory is the directory; LDAP is the language used to talk to it.** The Domain Controller stores and exposes AD data (users, computers, groups, password hashes, attributes) through an LDAP interface.
- **Why this matters offensively:** because LDAP is an open standard, *any* OS or application — Linux, macOS, third-party appliances — can authenticate against and query a Windows DC without being domain-joined or even running Windows. This is also why you can attack AD directly from Kali using `ldapsearch`, BloodHound, NetExec, etc., without ever touching a Windows host.

#### The DC's dual role

- To a Windows client: full DC duties (Kerberos, GPO enforcement, etc.).
- To everything else (printers, VPNs, Linux web apps, firewalls): a standard LDAP server answering bind/search requests.
- This dual exposure is a core reason AD has such a large attack surface: Microsoft has to keep the LDAP door open for interoperability.

### 2. How the LDAP protocol works

#### Data structure (the tree)

- Objects (users, computers, groups) sit in a hierarchical tree, addressed by a **Distinguished Name (DN)**:
  - `DC` (Domain Component) — the root, e.g. `DC=thm,DC=local`
  - `OU` (Organizational Unit) — branches, e.g. `OU=IT_Department`
  - `CN` (Common Name) — the actual object, e.g. `CN=Romeo`
- Full example: `CN=Romeo,OU=IT_Department,DC=thm,DC=local`

#### Protocol operations

| Operation | Purpose |
|---|---|
| **Bind** | Authenticate to the LDAP server (the "login") |
| **Search** | Query the tree with filters |
| **Modify/Add/Delete** | Change objects (requires privilege) |
| **Unbind** | Close the connection |

#### Typical flow for an app using LDAP auth

1. User submits credentials to the app.
2. The app performs an **LDAP Bind** to the DC using those credentials.
3. If successful, the app may run an **LDAP Search** to pull group memberships/attributes and decide access.

#### Why this is a huge enumeration target

- By default, **any valid authenticated user can read most of the LDAP tree.**
- With just one valid (even low-privileged) credential, you can run **LDAP Searches** to:
  - List all users and computers
  - Identify Domain Admins and privileged group members
  - Read computer/user description fields (sometimes containing accidentally stored passwords)
  - Map the entire org structure for further targeting
- This activity is generally called **LDAP enumeration**, and it's usually a direct next step after any AD foothold is obtained.

### 3. LDAP Bind Credentials (application-stored AD creds)

- Many third-party (non-Microsoft) applications integrate with AD via LDAP authentication: GitLab, Jenkins, custom web apps, printers, VPNs, Wi-Fi controllers, firewalls.
- Unlike NTLM-based auth (where the app just forwards a challenge), **LDAP authentication requires the application itself to hold a set of AD credentials** — a "service account" — which it uses to bind to the DC first, then verify the end user.
- **This is the key offensive angle:** because the app must store usable AD credentials somewhere, recovering *that* credential set becomes a goal in itself, separate from attacking the end users.

#### Attack avenue 1: configuration file recovery

- If you get a foothold on the host running the LDAP-integrated app (e.g. a GitLab server), the bind credentials are often sitting in a **configuration file, frequently in plaintext**.
- The underlying assumption many vendors make: *security relies on protecting the location/access to the config file, not on encrypting its contents.* That assumption breaks the moment you get host access.
- General takeaway: **whenever you land on a host running an LDAP/AD-integrated service, checking its config files for stored credentials should be routine.**

#### Attack avenue 2: exposed services, same patterns as NTLM

- If an LDAP-authenticated app is internet-facing, the same credential validation / password spraying approaches used against NTLM services apply here too.

### 4. LDAP Bind attack vectors (general)

| Vector | Idea |
|---|---|
| **Cleartext sniffing (Simple Bind)** | Unencrypted LDAP (port 389) with Simple Bind sends credentials in plaintext. Capturable with a sniffer on the local network or path. |
| **LDAP/NTLM relaying** | Poison name resolution (e.g. LLMNR/NBT-NS, Responder) to trick a system into authenticating to your box, then relay that authentication to the DC's LDAP service to perform actions as the victim. |
| **Anonymous binds** | Misconfigured DCs sometimes accept a bind with no credentials, handing out read access to parts of the tree for free. |
| **Post-bind abuse** | No hijacking needed — bind with *any* valid credentials (however obtained) and run searches to enumerate the whole domain. |

**General principle:** if you can intercept a bind, you get credentials. If you can perform a bind (any valid creds), you get a license to enumerate everything.

---

### 5. ⭐ LDAP Pass-back Attack — the major attack in this section

**This is the headline technique here.** Everything above (what LDAP is, how binds work, why bind credentials matter) exists to set up *why* this attack is so effective: it is the most practical, repeatable way to turn LDAP's trust model into a stolen AD credential, usually requiring nothing more than internal network access and a misconfigured device.

#### Concept

- A technique against **network devices with LDAP integration** — most commonly **printers**, but also Wi-Fi controllers and firewalls — typically performed once you have a foothold on the **internal network** (e.g. a rogue device plugged into a boardroom port).
- These devices hold a bind credential internally (to look up/authenticate users) but **hide the password field** in their web UI.

#### Why it works

- Device admin interfaces are frequently left on **default credentials** (`admin:admin`, `admin:password`), or sometimes require no authentication at all.
- You can't read the stored LDAP password directly, but you **can edit the LDAP server address** the device points to.
- The device typically offers a **"Test Settings" / "Test Connection"** button, which forces it to immediately attempt an LDAP bind to whatever server is configured.

#### Attack procedure (generalized)

1. Access the device's admin interface (default creds, or no auth at all).
2. Locate the LDAP configuration section — note the existing (legitimate) LDAP server address and the bind username (often visible even if the password isn't).
3. Stand up a **rogue LDAP listener** on your attack box.
4. Change the device's configured LDAP server IP to your own.
5. Trigger "Test Settings" to force the device to bind to your rogue server.
6. Capture the bind attempt.

#### The catch: authentication method negotiation

- A naive netcat listener on port 389 won't get you the credentials. Before sending them, the client negotiates the **strongest mutually supported auth mechanism** with the server (`supportedSASLMechanisms` etc.). If a secure mechanism is negotiated, the password may never be sent in cleartext — sometimes not sent over the network at all.
- **Fix:** stand up a real rogue LDAP server (e.g. OpenLDAP) and **deliberately downgrade** its supported SASL mechanisms to only the weakest ones (`PLAIN`, `LOGIN`). This forces the client to fall back to plaintext-equivalent auth.

#### Generalized rogue LDAP server setup (OpenLDAP example)

```bash
sudo apt-get update && sudo apt-get -y install slapd ldap-utils && sudo systemctl enable slapd
sudo dpkg-reconfigure -p low slapd
```

- Configure the DNS domain name and organisation name to match the **target's domain** (so the DN format lines up).
- Restrict supported SASL mechanisms via an LDIF patch:

```text
# olcSaslSecProps.ldif
dn: cn=config
replace: olcSaslSecProps
olcSaslSecProps: noanonymous,minssf=0,passcred
```

- `noanonymous`: disallow anonymous bind mechanisms
- `minssf=0`: minimum security strength factor of 0 — i.e., no required protection
- Apply it:

```bash
sudo ldapmodify -Y EXTERNAL -H ldapi:// -f ./olcSaslSecProps.ldif && sudo service slapd restart
```

- Verify the downgrade worked:

```bash
ldapsearch -H ldap:// -x -LLL -s base -b "" supportedSASLMechanisms
```

Expect only `PLAIN` and `LOGIN` listed.

#### Capturing the credential

- Once the rogue server only offers weak mechanisms, triggering "Test Settings" again causes the bind attempt to carry credentials in a now-crackable/cleartext-equivalent form.
- If the device's own error handling swallows the response, fall back to a packet capture on the relevant interface:

```bash
sudo tcpdump -SX -i <interface> tcp port 389
```

- The bind payload will contain the full DN (`domain\service_account`) and the password in plaintext.

#### Why this is so dangerous

- The recovered account is a **real AD credential**, usable for further authentication and enumeration.
- IT admins frequently take shortcuts: instead of scoping the device's service account to **read-only, minimal rights**, they sometimes reuse **powerful admin accounts** just to get the integration working quickly. If that's the case here, a "just a printer" compromise becomes a much bigger win.

---

### 6. Offsec takeaways / general strategy

1. **The LDAP pass-back attack is the primary, go-to technique in this category** — treat it as a standard check on any engagement where you get internal/physical network access: find network devices with LDAP integration (printers first) and test for default creds plus an editable LDAP server field.
2. **Any LDAP-integrated third-party system or appliance is a potential credential source** — not just the DC itself. Printers, VPNs, firewalls, CI/CD tools, ticketing systems, Wi-Fi controllers.
3. **Config files are a first-class secondary target** on any host running an LDAP-integrated app, since bind credentials are frequently stored in plaintext there.
4. **Device admin panels with default creds are common low-effort entry points**, especially on hardware (printers, controllers) that IT rarely hardens — this is exactly what makes the pass-back attack so reliable.
5. **A pass-back attack doesn't need you to break encryption** — it just needs you to control what server the victim device talks to, and force it to negotiate down to a weak auth mechanism.
6. Getting one set of LDAP bind credentials, however low-privileged, is enough to pivot into full **LDAP enumeration**: users, groups, Domain Admins, and misconfigured accounts to chase next.
7. This class of attack generally requires **some level of internal/physical network access** (rogue device, LAN presence) since it depends on redirecting traffic to your own listener — unlike NTLM service attacks, which can sometimes be done purely from the internet.

## 🧭 Methodology

```text
Internal foothold (rogue device / LAN presence)
  ↓
Find LDAP-integrated devices (printers first, default creds)
  ↓
Rogue LDAP server (downgraded SASL: PLAIN/LOGIN only)
  ↓
Repoint device LDAP server → yours → Test Settings
  ↓
Capture bind (tcpdump fallback) → AD credential
  ↓
LDAP enumeration with recovered creds
```

## 🛠️ Techniques

### LDAP Pass-back

- Description: Redirect a device's LDAP bind to your rogue server and capture the service account credential.
- When to use: Internal network access + device with editable LDAP server field.
- Command: OpenLDAP with `olcSaslSecProps: noanonymous,minssf=0,passcred` → verify `supportedSASLMechanisms` → `tcpdump -SX -i <iface> tcp port 389`.

### Config File Bind Credential Recovery

- Description: Read plaintext AD bind creds from LDAP-integrated app configs.
- When to use: Foothold on host running GitLab/Jenkins/custom LDAP app.
- Command: Inspect app config files for bind DN + password.

## 💻 Commands

```bash
# Rogue LDAP server (OpenLDAP)
sudo apt-get update && sudo apt-get -y install slapd ldap-utils && sudo systemctl enable slapd
sudo dpkg-reconfigure -p low slapd
sudo ldapmodify -Y EXTERNAL -H ldapi:// -f ./olcSaslSecProps.ldif && sudo service slapd restart
ldapsearch -H ldap:// -x -LLL -s base -b "" supportedSASLMechanisms

# Capture bind
sudo tcpdump -SX -i <interface> tcp port 389

# LDAP enumeration with recovered creds
# ldapsearch -x -H ldap://<DC-IP> -D '<bind-DN>' -w '<password>' -b 'DC=thm,DC=local' '(objectClass=user)'
```

## 🧪 Labs

| Lab / Box | Key Learning | Status |
|-----------|:------------:|:------:|
| | | |

## 📇 Cheatsheet

- AD = directory, LDAP = language | DN = `CN=..,OU=..,DC=..,DC=..`
- Any valid bind = full-tree read → enumerate users, DAs, descriptions
- Pass-back: default-creds device → repoint LDAP → rogue server (PLAIN/LOGIN only) → Test → tcpdump 389
- Config files on LDAP-app hosts = plaintext bind creds | service accounts sometimes over-privileged

---

[⬅ AD Domain](../README.md) | [📁 Breaching AD](./README.md) | [🏠 Dashboard](../../README.md)