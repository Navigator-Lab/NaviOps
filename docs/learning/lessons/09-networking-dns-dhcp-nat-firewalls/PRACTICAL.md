# Lesson 09 — Pure Practical: DNS, DHCP, NAT & Firewalls

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** `naviops-web` / `naviops-db` on `172.28.0.0/24`. **Artifact:** `scripts/firewall_audit.sh`.
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: trace a name to an IP end to end (fluency)

**Scenario.** `NAVI-091`. Before trusting DNS in the lab you want to see exactly how a hostname
resolves and in what order the resolver consults its sources.

**Objective.** Resolve a name via `/etc/hosts` and via DNS, and explain the resolution order the box uses.

**Given / constraints.** Read-only. Show both `getent` (respects nsswitch) and `dig` (DNS only).

**Hints.**
1. `cat /etc/nsswitch.conf | grep hosts` — the order (`files dns`).
2. `getent hosts naviops-db` (uses the full stack) vs `dig +short naviops-db` (DNS only) — note when they differ.
3. Add a test entry to `/etc/hosts` and watch `getent` pick it up while `dig` ignores it.

✅ **Verify.**
```bash
getent hosts naviops-db && echo "RESOLVES ✅"
grep hosts /etc/nsswitch.conf        # you can state the order
```

**Pitfalls.**
- Assuming `dig` reflects what the app sees — apps go through nsswitch (`/etc/hosts` first).
- Editing `/etc/hosts` with a typo → silent wrong resolution.
- Confusing "no DNS server" with "wrong search domain".

🎯 **Stretch.** Trace a public name's full delegation with `dig +trace example.com` and identify the root → TLD → authoritative hops.

---

## Task 2 — Ticket-driven: "name resolution is broken" (diagnose → fix)

**Scenario.** `NAVI-092` (P2). *"Everything times out with 'could not resolve host', but the IP works
if I use it directly."* DNS-layer problem; find and fix it.

**Objective.** Restore name resolution having identified whether the fault is `resolv.conf`, the DNS
server, or nsswitch — **diagnose first**.

**Given / constraints.** Recreate: a broken `/etc/resolv.conf` (wrong/empty nameserver) or a blocked
DNS port. Fix the actual cause.

**Hints.**
1. `ping 172.28.0.11` works but `ping naviops-db` fails → resolution, not connectivity.
2. `cat /etc/resolv.conf`; test the server directly: `dig @<server> naviops-db`.
3. Is 53 reachable? `nc -vz <server> 53`. Firewall dropping DNS?

✅ **Verify.**
```bash
getent hosts naviops-db >/dev/null && echo "DNS FIXED ✅"
dig +short naviops-db @<server>      # returns an address
```

**Pitfalls.**
- Editing `/etc/resolv.conf` on a system where it's managed (systemd-resolved/NetworkManager) → your change is overwritten; fix it at the source.
- Testing only with `ping` (ICMP) and missing that DNS/UDP-53 is what's blocked.
- Wrong `search` domain making short names fail while FQDNs work.

🎯 **Stretch.** Point the box at a second nameserver and prove failover by making the first unreachable.

---

## Task 3 — On-call: a firewall change broke prod (or a port is dangerously open) (synthesis)

**Scenario.** `NAVI-093` (P1, time-boxed). Either a firewall push blocked the app port, or an audit
found a service exposed to the world. You must reconcile *intended* vs *actual* rules and fix safely.

**Objective.** Audit the live ruleset against intent, close the gap (open the needed port / close the
exposed one) **without locking yourself out**, and persist the change.

**Given / constraints.** Recreate with `nftables`/`firewalld`. Never flush all rules on a remote box
without a rollback timer. Log the before/after.

**Hints.**
1. Snapshot first: `nft list ruleset > /tmp/fw.before`. Understand default policy (accept vs drop).
2. Make the minimal change (allow app port from the app subnet only; drop the world-exposed one).
3. Safety net for remote work: schedule an auto-rollback (`sleep 300 && restore`) before applying, cancel once verified.

✅ **Verify.**
```bash
nc -vz 172.28.0.11 <appport> 2>&1 | grep -qi succeeded && echo "APP REACHABLE ✅"
nc -vz <public-if> <closed-port> 2>&1 | grep -qi refused && echo "EXPOSED PORT CLOSED ✅"
scripts/firewall_audit.sh; test -f docs/learning/reports/NAVI-093-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-093-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention.

**Pitfalls.**
- Setting default DROP on a remote host with no allow for your SSH → instant lockout (troubleshooting-drills §7).
- Making a runtime change but not persisting it → next reboot reverts.
- Opening a port `0.0.0.0/0` when only the app subnet needs it.

🎯 **Stretch.** Make `scripts/firewall_audit.sh` diff the live ruleset against a committed intended baseline and exit non-zero on drift.

---

## Done?
- [ ] All ✅ Verify pass · [ ] snapshot + rollback before firewall change · [ ] postmortem written.
- [ ] Least-exposure rules. **Redaction:** lab IPs only. → [README Step 7](./README.md).
