# Connecting to the Network and DNS Troubleshooting

> [⬅ AD Domain](../README.md) | [📁 AD Basics](./README.md) | [🏠 Dashboard](../../README.md)

| HTB Progress | Notes | Practical Labs | CPTS Confidence |
|:------------:|:-----:|:--------------:|:---------------:|
| — | Started | — | — |

**Status:** 🔄 In Progress

---

## 📌 Concepts

### 1. Why DNS matters in AD

- Windows networks use **DNS to resolve hostnames to IPs**.
- **Kerberos relies on DNS** to create tickets. Tickets can't be associated with IPs, so DNS is a must.
- The DC also acts as the **DNS server** for the domain.
- **Rule of thumb:** when a tool or task isn't working, the first question is **"Is my DNS working?"** DNS changing silently has cost hours on real assessments.

### 2. Two ways to handle DNS: `/etc/hosts` vs DC as resolver

They are not two versions of the same thing. **Pointing your DNS at the DC is the better option.**

| | `/etc/hosts` | `/etc/resolv.conf` (pointing at the DC) |
|---|---|---|
| What it does | Hardcodes individual hostname-to-IP entries | Sends all DNS queries to the DC's DNS server |
| Effort | One line per host, added by hand | Set once |
| Scale | Infeasible at 10,000+ hosts | Works the same for 5 hosts or 10,000 |
| Stays current | No. Stale if IPs change | Yes. The DC's records are the source of truth |
| New or unknown hosts | Won't resolve until you add them | Resolve automatically |

#### Why pointing at the DC works

- The DC is the DNS server for the domain, so it already holds records for every domain-joined host.
- You don't need to know the hosts in advance. Querying the DC finds them.
- This is the "debug DNS until it works" option recommended.

#### Why the DC's entry must be first

> My explanation. The source only says to make it the first entry.

- The resolver asks nameservers **in the order listed**.
- If a public DNS (such as `1.1.1.1`) is first, it answers internal names with "doesn't exist" or a wrong answer. That counts as an answer, so the resolver **never falls through to the DC**.
- The DC is only asked if the first server is unreachable or times out.
- With the DC first, internal names resolve correctly. External names like `tryhackme.com` still resolve because the DC forwards what it doesn't know.

#### When to use each

- **Normal approach:** configure DNS to use the DC.
- **`/etc/hosts`:** a quick workaround for a handful of hosts, or when you can't change DNS.

#### Practical caveat

- On many systems `resolv.conf` is **managed by another service** (NetworkManager on Kali, dnsmasq on the AttackBox), which can **overwrite manual edits**. That's why DNS is configured through those tools rather than by editing the file directly.
- The AttackBox DNS reset every ~3 hours is an example of this.

### 3. Connecting to the network

#### Web AttackBox

- Connected automatically if started from the room page.
- Verify with `ping` against the DC (`THMDC.za.tryhackme.com`).
- DNS still needs manual configuration.

#### Own attack machine (OpenVPN)

1. Download the `.ovpn` config from the access page (network tab, select the VPN server).
2. Connect:

```bash
sudo openvpn breachingad.ovpn
```

3. **"Initialization Sequence Completed"** means you're connected. The access page should show a green tick next to Connected and your internal IP.
4. Configure DNS (below), since the VPN doesn't set it up.

#### Note your VPN IP

- Run `ifconfig` or `ip a` and record the IP of the **`breachad` network adapter**.
- Use this IP and interface when performing attacks.

### 4. Configuring DNS

#### AttackBox

```bash
sed -i '1s|^|nameserver <THMDCIP>\n|' /etc/resolv-dnsmasq
systemctl restart dnsmasq
```

- Replace `<THMDCIP>` with the DC's IP. The `\n` puts the entry on its own line at the top of the file.
- Test:

```bash
nslookup thmdc.za.tryhackme.com
```

- It should resolve to the DC's IP.
- **DNS may reset roughly every 3 hours**, so rerun the command. If the AttackBox is terminated, redo all DNS steps.

#### Kali VM (Network Manager)

1. `Network Manager -> Advanced Network Configuration -> Your Connection -> IPv4 Settings`
2. Set the DNS to the **THMDC IP**.
3. Add a **second DNS** (such as `1.1.1.1`) so you keep internet access.
4. Restart and test:

```bash
sudo systemctl restart NetworkManager
```

#### Other operating systems

- Look up the equivalent configuration for your OS.

### 5. Opsec note

- The DC **logs DNS requests**, even though it isn't otherwise used here.
- If you use your own machine, the logs may include your **device hostname**. For example, a Kali box named `kali` will be logged as `kali`.
- On real engagements, consider setting a neutral hostname.

### 6. DNS debugging steps

1. **Redo the configuration** for your machine type.
2. **`ping <THM DC IP>`** — verifies the network is active.
   - No response means the network isn't active. If the room page says it's running and you still get nothing, contact support. Waiting for the network timer to expire and restarting also fixes it.
3. **`nslookup za.tryhackme.com <THM DC IP>`** — verifies the DNS server on the DC is working.
   - If ping worked but this fails, contact support and try the network reset button.
4. **`nslookup tryhackme.com`** — compare with step 3.
   - A different response than step 3 means your DNS config is wrong. Redo the configuration.
   - **Common Kali issue:** the DC's entry is second in `/etc/resolv.conf`. **Make it the first entry.**

| Test | What it proves |
|---|---|
| `ping <DC IP>` | Network and routing work |
| `nslookup za.tryhackme.com <DC IP>` | DC's DNS service is up |
| `nslookup tryhackme.com` | Your system is actually using the DC for DNS |

### 7. Quick recall

- **DNS is required for AD testing** because Kerberos needs hostnames.
- `/etc/hosts` = manual list, doesn't scale. **DC as DNS server = automatic, scales, stays current.**
- The DC's entry goes **first**, or a public DNS answers instead and internal names fail.
- AttackBox: `sed` into `/etc/resolv-dnsmasq`, then `systemctl restart dnsmasq`.
- Kali: set the DC IP as DNS in Network Manager, plus a secondary like `1.1.1.1`.
- `resolv.conf` may be overwritten by NetworkManager or dnsmasq, so configure through them.
- Verify with `ping`, then `nslookup <domain> <DC IP>`, then `nslookup <external domain>`.
- **First thought when something breaks: is my DNS working?**
- Record your `breachad` adapter IP for attacks.
- The DC logs DNS queries, so your hostname may be recorded.

### 8. Open items

- The room is rated **medium** and assumes some AD familiarity.

## 🧭 Methodology

```text
Connect (AttackBox or OpenVPN) → record breachad IP
  ↓
Set DNS: DC first, public DNS second
  ↓
ping <DC IP> → nslookup <domain> <DC IP> → nslookup <external>
  ↓
If broken: redo config (NetworkManager / dnsmasq), check entry order
```

## 🛠️ Techniques

### DC-first DNS (Network Manager)

- Description: Point resolver at DC with fallback to public DNS.
- When to use: Kali / own VM on VPN.
- Command: Network Manager → IPv4 → DNS = `<DC IP>, 1.1.1.1` → `sudo systemctl restart NetworkManager`

### AttackBox DNS via dnsmasq

- Description: Prepend DC nameserver, restart dnsmasq.
- When to use: THM AttackBox (resets ~every 3h).
- Command:
  ```bash
  sed -i '1s|^|nameserver <THMDCIP>\n|' /etc/resolv-dnsmasq
  systemctl restart dnsmasq
  ```

## 💻 Commands

```bash
# OpenVPN connect
sudo openvpn breachingad.ovpn

# VPN IP
ip a   # note breachad adapter IP

# AttackBox DNS
sed -i '1s|^|nameserver <THMDCIP>\n|' /etc/resolv-dnsmasq
systemctl restart dnsmasq

# Kali DNS
sudo systemctl restart NetworkManager

# Verify
ping <DC IP>
nslookup za.tryhackme.com <DC IP>
nslookup tryhackme.com
nslookup thmdc.za.tryhackme.com
```

## 🧪 Labs

| Lab / Box | Key Learning | Status |
|-----------|:------------:|:------:|
| THM AD room (medium) | DNS-first debugging, AttackBox reset, DC as resolver | 🔄 |

## 📇 Cheatsheet

- Kerberos needs DNS → DC is DNS server → DC entry **first**
- AttackBox: `sed` + `restart dnsmasq` (resets ~3h) | Kali: NetworkManager DNS = DC, 1.1.1.1
- Debug: ping DC → nslookup domain @DC → nslookup external | logs record your hostname

---

[⬅ AD Domain](../README.md) | [📁 AD Basics](./README.md) | [🏠 Dashboard](../../README.md)