# Troubleshooting Drills — NaviOpsNetwork

Break-it-then-fix-it drills, one per canonical NOC scenario (`noc/noc-scenarios.md`). Each
lesson's §8 cross-links the relevant drill; doing the drill produces a `docs/runbooks/`
incident report (the §9 evidence). **Linux-first, lab/RFC-1918 ranges only.** Run these on a
host/VM you own — never a third party (`navi.project.md` danger zones).

> Format per drill: **Break** (how to induce it safely) → **Symptom** → **Diagnose** (the
> commands) → **Fix** → **Verify** → **Runbook**. Always capture diagnostic output *before*
> fixing (you need it for the RCA).

## Drill 1 — DNS outage  *(Lesson 13)*
- **Break:** point `/etc/resolv.conf` at an unreachable resolver, or block UDP/53 with nftables.
- **Symptom:** `curl https://example.com` fails name resolution; `ping 1.1.1.1` works (so it's
  DNS, not connectivity).
- **Diagnose:** `dig example.com` (timeout/SERVFAIL?) → `dig @9.9.9.9 example.com` (works? then
  it's *your* resolver) → `dig +trace example.com` → check firewall `nft list ruleset`.
- **Fix:** restore resolver / allow UDP+TCP 53.
- **Verify:** `dig example.com` returns an answer; `systemd-resolve --statistics` (or `resolvectl`).
- **Runbook:** `docs/runbooks/incident-dns-outage.md`.

## Drill 2 — DHCP failure  *(Lesson 12)*
- **Break:** stop `dnsmasq`, or shrink the scope to 0 free leases.
- **Symptom:** client gets `169.254.x.x` (APIPA); `ip addr` shows no lease.
- **Diagnose:** `journalctl -u dnsmasq`; `tcpdump -ni any port 67 or 68` (see DISCOVER with no
  OFFER); check lease file / scope.
- **Fix:** restart service / expand scope / fix relay.
- **Verify:** client `dhclient -v <if>` gets an address in-range; lease appears in the lease file.
- **Runbook:** `docs/runbooks/incident-dhcp-failure.md`.

## Drill 3 — High latency  *(Lesson 18, 21)*
- **Break:** `tc qdisc add dev <if> root netem delay 150ms` to inject latency.
- **Symptom:** apps slow; `latency_monitor.sh` p95 over threshold.
- **Diagnose:** `mtr <dest>` (which hop jumps?); `ping` RTT vs baseline; `tc qdisc show`.
- **Fix:** `tc qdisc del dev <if> root netem`.
- **Verify:** RTT back to baseline; `mtr` clean.
- **Runbook:** `docs/runbooks/incident-high-latency.md`.

## Drill 4 — Packet loss  *(Lesson 18, 20)*
- **Break:** `tc qdisc add dev <if> root netem loss 10%`.
- **Symptom:** intermittent failures, TCP retransmits.
- **Diagnose:** `ping -c 100` (loss %); `mtr` per-hop loss; `tcpdump` shows retransmits;
  `ip -s link` error counters.
- **Fix:** `tc qdisc del dev <if> root netem`.
- **Verify:** 0% loss over `ping -c 100`.
- **Runbook:** `docs/runbooks/incident-packet-loss.md`.

## Drill 5 — Interface down  *(Lesson 17, 24)*
- **Break:** `ip link set <if> down` (on a VM with another path / console).
- **Symptom:** link-down; SNMP ifOperStatus down; routes via that iface gone.
- **Diagnose:** `ip link show <if>`; `ethtool <if>`; `journalctl -k | grep <if>`.
- **Fix:** `ip link set <if> up`.
- **Verify:** `ip link` shows `state UP`; routes restored; reachability returns.
- **Runbook:** `docs/runbooks/incident-iface-down.md`.

## Drill 6 — Routing issue  *(Lesson 07)*
- **Break:** `ip route del default` or add a wrong/blackhole route
  (`ip route add 10.0.20.0/24 via 10.0.0.254`).
- **Symptom:** one subnet/internet unreachable; `ping gateway` may still work.
- **Diagnose:** `ip route get <dest>` (which route is chosen?); `traceroute <dest>` (where it
  dies); compare table to intended.
- **Fix:** restore the correct route / default.
- **Verify:** `ip route get <dest>` shows the right next-hop; reachability returns.
- **Runbook:** `docs/runbooks/incident-routing.md`.

## Drill 7 — VLAN misconfiguration  *(Lesson 09)*
- **Break:** on a Linux VLAN lab, assign a host to the wrong VLAN id, or omit the VLAN from the
  bridge's tagged set.
- **Symptom:** hosts that should share a VLAN can't reach each other; inter-VLAN broken.
- **Diagnose:** `bridge vlan show`; `ip -d link show <vlan-if>` (VLAN id); verify trunk/native
  config on both ends.
- **Fix:** correct the VLAN id / allowed set.
- **Verify:** intra-VLAN ping works; `bridge vlan show` matches design.
- **Runbook:** `docs/runbooks/incident-vlan-misconfig.md`.

## Drill 8 — Firewall blocking traffic  *(Lesson 15)*
- **Break:** `nft add rule inet filter input tcp dport 8080 drop` (block a known-good service).
- **Symptom:** service was reachable, now times out / refused.
- **Diagnose:** `nft list ruleset` (which rule + counter increments?); `tcpdump` both sides
  (leaves A? arrives B?); `nc -vz host 8080`.
- **Fix:** remove/correct the rule.
- **Verify:** `nc -vz host 8080` succeeds; counter no longer increments on the drop.
- **Runbook:** `docs/runbooks/incident-firewall-block.md`.

---

## Interview value
These 8 drills *are* the CompTIA Network+ Domain 5.0 (Troubleshooting, 24%) practice set and
the most common NOC interview scenario questions ("X is broken — what do you check first?").
Doing them, capturing the evidence, and writing the runbook is the difference between "I read
about it" and "here's my incident report."
