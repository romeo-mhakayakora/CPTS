# AD Enumeration via BloodHound and SharpHound

> [⬅ AD Domain](../README.md) | [📁 Enumeration](./README.md) | [🏠 Dashboard](../../README.md)

| HTB Progress | Notes | Practical Labs | CPTS Confidence |
|:------------:|:-----:|:--------------:|:---------------:|
| — | Started | — | — |

**Status:** 🔄 In Progress

---

## 📌 Concepts

### 1. Why BloodHound changed everything

> "Defenders think in lists. Attackers think in graphs."

- Before BloodHound, defenders maintained flat lists (Domain Admins list, host list, user list). These miss the **relationships between objects**.
- BloodHound maps the entire AD environment as an **interconnected graph** where every node is an AD object and every edge is a relationship or permission.
- Each edge is a **potential attack path**. BloodHound surfaces multi-hop paths that no list-based approach would find.
- Microsoft recognised its power and built their own version into Advanced Threat Protection.

#### The two-stage attack BloodHound enabled

1. **Stage 1:** Deploy a noisy phishing payload purely to collect AD enumeration data. The blue team detects and contains it, but the **data is already exfiltrated**.
2. **Stage 2:** Analyse the data offline, map the exact attack path in graph format, then execute a second, targeted breach following the pre-mapped path. The goal is often reached **before the blue team receives their first alert**.

### 2. SharpHound vs BloodHound

They are not the same tool:

| Tool | Role |
|---|---|
| **SharpHound** | The **collector**. Runs against the domain, enumerates AD data, outputs a ZIP of JSON files. |
| **BloodHound** | The **GUI**. Ingests SharpHound's ZIP and renders the AD environment as an interactive attack graph. |

**Version matching is critical.** SharpHound and BloodHound versions must match. Old SharpHound output may not be ingestible by a newer BloodHound version.

### 3. SharpHound collectors

| Collector | Notes |
|---|---|
| `SharpHound.exe` | Windows executable. Most straightforward to run. |
| `SharpHound.ps1` | PowerShell script. Latest releases have stopped shipping this, but older versions exist. **Best for RATs** — can be loaded directly into memory, bypassing on-disk AV detection entirely. |
| `AzureHound.ps1` | Enumerates Azure AD environments. BloodHound ingests this to find attack paths in cloud identity and access configurations. |

### 4. Running SharpHound

#### General command

```cmd
SharpHound.exe --CollectionMethods <Methods> --Domain <target domain FQDN> --ExcludeDCs
```

#### Key parameters

| Parameter | Purpose |
|---|---|
| `--CollectionMethods` | What to collect. `All` for a full first run. `Session` for follow-up runs capturing new active sessions without re-enumerating the full structure. `Default` for a balanced option. |
| `--Domain` | Target domain FQDN. Can be set to a parent or trusted domain to enumerate across trust boundaries. |
| `--ExcludeDCs` | Instructs SharpHound not to directly touch Domain Controllers. Significantly reduces the chance of triggering an alert. Always use this. |

Full parameter reference: https://bloodhound.readthedocs.io

#### Output

- Produces a **timestamped ZIP file** in the working directory containing JSON files per object type.
- Small domain (~2000 objects): approximately 1 minute.
- Large enterprise domains: can take hours on the first full run.

### 5. Detection risk and how to reduce it

- **SharpHound is well-known and commonly signature-detected** by AV and EDR on disk.
- **Best approach:** run SharpHound from a **non-domain Windows machine you control**, with AV disabled or exceptions set, using `runas /netonly` to inject AD credentials.
- **For RAT-based delivery:** use `SharpHound.ps1` loaded directly into memory — no disk write, bypasses on-disk AV scanning. Combine with Unmanaged PowerShell for maximum stealth.
- `--ExcludeDCs` always reduces alert likelihood by avoiding direct DC contact.

### 6. Transferring results to your attack machine

```bash
scp <AD username>@<target host FQDN>:C:/Users/<AD username>/Documents/<ZIP filename> .
```

| Part | Meaning |
|---|---|
| `scp` | Secure Copy Protocol — transfers files over an encrypted SSH connection |
| `<user>@<host>` | Authenticate to the remote Windows host as the AD user |
| `:C:/Users/.../<ZIP>` | Colon separates the host from the remote file path on the Windows machine |
| `.` (trailing dot) | Save the file in your **current working directory** on the Linux machine |

You'll be prompted for the AD user's password. The ZIP lands locally, ready for BloodHound.

### 7. Setting up BloodHound

BloodHound uses **Neo4j** as its backend graph database.

```bash
# Terminal 1: start the database
neo4j console start

# Terminal 2: launch BloodHound
bloodhound --no-sandbox
```

- Default Neo4j credentials: `neo4j:neo4j`
- Authenticate in the BloodHound GUI with these credentials.
- **Drag and drop the SharpHound ZIP** directly onto the BloodHound GUI to import.
- Importing a new SharpHound run **cumulatively adds** to existing data rather than replacing it.

### 8. What BloodHound shows: node information

Each AD object is a **node**. Clicking a node reveals:

| Section | What it gives you |
|---|---|
| **Overview** | Active sessions, whether the account can reach high-value targets |
| **Node Properties** | Display name, title, basic AD attributes |
| **Extra Properties** | Distinguished name, creation date, detailed attributes |
| **Group Membership** | All groups the account belongs to |
| **Local Admin Rights** | Domain-joined hosts where this account has local admin |
| **Execution Rights** | RDP access, PS Remoting, DCOM, and other special privileges |
| **Outbound Control Rights** | AD objects this account can modify |
| **Inbound Control Rights** | AD objects that can modify this account |

Click the number next to any category to expand it fully.

### 9. Attack paths: the core capability

BloodHound finds the **shortest path** between any two nodes across all possible edges.

#### Path searching

- Click the **path icon**.
- Set a **Start Node** (your current compromised account or position).
- Set an **End Node** (your target — Domain Admins group, a high-value server, a specific user).
- BloodHound calculates and displays the exact chain of steps and hops.

#### What edges represent

Edges are permissions, sessions, group memberships, or protocol-level relationships:

- Member of a group
- Local admin rights on a host
- RDP access to a machine
- `GenericAll`, `GenericWrite`, or `WriteDACL` over an AD object
- Active session on a host (credential harvesting opportunity)

Each edge type has documented exploitation techniques in BloodHound's own documentation.

#### Nested groups matter

A user can effectively be a Domain Admin through **nested group membership** without appearing directly in the Domain Admins group. BloodHound surfaces this automatically — it's something list-based enumeration consistently misses.

#### Pre-built analysis queries

BloodHound ships with built-in queries under the Analysis tab:

- Find all Domain Admins
- Find shortest paths to Domain Admins
- Find computers where Domain Admins are logged in
- Find principals with DCSync rights
- Find AS-REP roastable users
- Find Kerberoastable users

These provide immediate actionable intelligence without manual query building.

### 10. Reading an attack path: worked example

BloodHound might surface a path like this:

```text
Your account (Domain Users)
  → Domain Users can RDP into WORKSTATION01
  → T1_ADMIN has an active session on WORKSTATION01 (broke tiering model)
  → RDP in, escalate local privileges
  → Run Mimikatz → capture T1_ADMIN's NTLM hash
  → T1_ADMIN is member of Tier 1 Admins
  → Tier 1 Admins have admin rights over all servers
```

No list-based tool surfaces this chain. BloodHound maps it in seconds. Real paths in enterprise environments can span many more hops.

### 11. Session data strategy

- AD **structure** (users, groups, OUs, ACLs) changes infrequently.
- **Active sessions change constantly** throughout the working day.
- SharpHound produces a point-in-time snapshot, so session data goes stale quickly.

#### Recommended cadence on an engagement

| Run | Timing | Collection method | Reason |
|---|---|---|---|
| **Initial** | Start of assessment | `All` | Full structure enumeration |
| **Session run 1** | ~10:00 | `Session` | Users starting work, sessions active |
| **Session run 2** | ~14:00 | `Session` | Users back from lunch, new sessions |

- Clear stale data before importing new session runs: `Database Info -> Clear Session Information`.
- Session-only runs are significantly faster than full runs since they don't re-enumerate the entire AD structure.

### 12. Benefits and drawbacks

| | Detail |
|---|---|
| **Visualises full attack surface** | Relationships and paths no manual enumeration finds |
| **Pre-built queries** | Common attack paths in seconds |
| **Graph-based thinking** | Multi-hop paths that list-based tools miss |
| **Works across trust boundaries** | Can enumerate parent/child and trusted domains |
| **Azure support** | AzureHound extends coverage to cloud environments |
| **SharpHound is detectable** | Well-known signatures. AV and EDR commonly flag it on disk. |
| **Version dependency** | Versions must match or ingestion fails |
| **Point-in-time snapshot** | Session data goes stale. Requires repeated runs. |

### 13. Quick recall

- BloodHound = GUI graph tool. SharpHound = collector. Both are needed.
- Versions must match.
- `--CollectionMethods All` for first run. `Session` for follow-up runs. `--ExcludeDCs` always.
- Run SharpHound from a **controlled non-domain machine** with AV disabled, using `runas /netonly`. Or load `SharpHound.ps1` into memory via RAT.
- Transfer results: `scp <user>@<host>:<remote path> .`
- Start Neo4j first, then BloodHound. Default credentials: `neo4j:neo4j`.
- Drag and drop the ZIP into BloodHound to import.
- Path search: Start Node = your position. End Node = your target.
- Nested group membership can give effective DA rights without appearing directly in Domain Admins. BloodHound catches this; lists don't.
- Session data: `All` once at start, `Session` at 10:00 and 14:00. Clear old session data before each import.
- Pre-built analysis queries cover the most common attack paths immediately on import.

## 🧭 Methodology

```text
SharpHound.exe --CollectionMethods All --Domain <FQDN> --ExcludeDCs
  ↓
scp ZIP to attack box
  ↓
neo4j console start → bloodhound --no-sandbox → import ZIP
  ↓
Path search: Start = your account → End = Domain Admins
  ↓
Session runs (10:00 / 14:00) → clear old sessions → re-import
  ↓
Execute mapped attack path
```

## 🛠️ Techniques

### SharpHound Collection

- Description: Enumerate AD into JSON ZIP for graph analysis.
- When to use: Any foothold; first full run then session runs.
- Command: `SharpHound.exe --CollectionMethods All --Domain <FQDN> --ExcludeDCs`

### BloodHound Path Analysis

- Description: Map shortest attack path between two nodes.
- When to use: After importing SharpHound data.
- Command: BloodHound GUI → path icon → Start Node → End Node.

### Stealth Collection (RAT)

- Description: Load SharpHound.ps1 into memory to avoid on-disk AV.
- When to use: Delivery via C2 on a monitored host.
- Command: `SharpHound.ps1` via Unmanaged PowerShell + `--ExcludeDCs`.

## 💻 Commands

```cmd
:: Collect (from controlled non-domain machine via runas /netonly)
SharpHound.exe --CollectionMethods All --Domain <target FQDN> --ExcludeDCs
SharpHound.exe --CollectionMethods Session --Domain <target FQDN> --ExcludeDCs
```

```bash
# Transfer results
scp <AD user>@<target host FQDN>:C:/Users/<AD user>/Documents/<ZIP> .

# BloodHound setup
neo4j console start
bloodhound --no-sandbox
```

## 🧪 Labs

| Lab / Box | Key Learning | Status |
|-----------|:------------:|:------:|
| | | |

## 📇 Cheatsheet

- SharpHound (collector) → ZIP → BloodHound (GUI, Neo4j backend) | versions must match
- `--CollectionMethods All` first, `Session` at 10:00/14:00 | `--ExcludeDCs` always
- Stealth: own machine + AV off + `runas /netonly`, or `SharpHound.ps1` in-memory via RAT
- Path search Start→End | nested groups = hidden DA | pre-built Analysis queries
- Session data stale fast → clear + re-import

---

[⬅ AD Domain](../README.md) | [📁 Enumeration](./README.md) | [🏠 Dashboard](../../README.md)