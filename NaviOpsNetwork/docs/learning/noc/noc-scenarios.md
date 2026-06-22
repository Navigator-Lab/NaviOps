# Realistic NOC Scenarios — first-move playbooks

The 8 canonical network incidents a NOC sees, each with the **alert it fires as**, the **first
3 diagnostic moves**, the **likely causes**, and **when to escalate**. Each maps to a drill in
`troubleshooting-drills.md` and (when worked) a runbook in `docs/runbooks/`. These feed lesson
§6/§7 and the NOC capstone (Lesson 35).

> Linux-first commands throughout. Lab/RFC-1918 IPs only.

## 1. DNS outage
- **Fires as:** "name resolution failing", web/app reachability alerts cluster.
- **First moves:** `dig @<resolver> name` vs `dig @9.9.9.9 name`; `dig +trace name`;
  `systemctl status named`/`journalctl -u named`.
- **Likely:** forwarder unreachable, recursion broken, expired zone, firewall blocking UDP/53,
  cache poisoning (security).
- **Escalate when:** authoritative/registrar issue or upstream/ISP DNS.
- **Lesson:** 13.

## 2. DHCP failure
- **Fires as:** clients on `169.254.x.x` (APIPA), "no IP", new devices can't join.
- **First moves:** `journalctl -u dnsmasq`/lease file; check scope exhaustion;
  verify relay/`ip helper-address` on the gateway; `tcpdump -ni any port 67 or 68`.
- **Likely:** scope exhausted, server down, relay misconfig, rogue DHCP server.
- **Escalate when:** rogue server suspected (security) or server-platform failure.
- **Lesson:** 12.

## 3. High latency
- **Fires as:** `latency_monitor` p95 over threshold, slow app response.
- **First moves:** `mtr <dest>` to find the hop where latency jumps; compare to baseline;
  `ip -s link` for interface errors/queues.
- **Likely:** congestion, duplex mismatch, overloaded link, suboptimal route, bufferbloat.
- **Escalate when:** localized to a device/uplink you can't touch, or carrier path.
- **Lesson:** 18, 21.

## 4. Packet loss
- **Fires as:** intermittent failures, retransmits, choppy VoIP.
- **First moves:** `ping -c 100` loss %; `mtr` per-hop loss column; interface error counters
  (`ip -s link`, SNMP ifInErrors).
- **Likely:** bad cable/SFP, CRC errors, duplex mismatch, oversubscription, MTU black-hole.
- **Escalate when:** physical/hardware (RMA) or carrier circuit.
- **Lesson:** 18, 20.

## 5. Interface down
- **Fires as:** SNMP ifOperStatus down, link-down trap, redundancy-lost alert.
- **First moves:** `ip link show <if>`; check both ends; `ethtool <if>` (link/speed/duplex);
  recent change/maintenance?
- **Likely:** cable/SFP, admin-down, both-ends mismatch, hardware, power.
- **Escalate when:** hardware replacement or remote-site hands needed.
- **Lesson:** 17, 24.

## 6. Routing issue
- **Fires as:** one subnet unreachable, asymmetric path, blackhole.
- **First moves:** `ip route get <dest>`; `traceroute <dest>` (where does it die / loop?);
  compare routing table to intended (missing/wrong/duplicate route).
- **Likely:** missing static route, route flap, wrong metric/AD, redistribution error, default
  route lost.
- **Escalate when:** dynamic-routing (OSPF/BGP) adjacency or upstream/ISP route.
- **Lesson:** 07.

## 7. VLAN misconfiguration
- **Fires as:** hosts in a VLAN can't talk, new VLAN doesn't work, inter-VLAN broken.
- **First moves:** verify access-port VLAN; trunk **allowed-VLAN** list; **native-VLAN** match
  on both trunk ends; inter-VLAN gateway/SVI reachable.
- **Likely:** wrong access VLAN, VLAN not allowed on trunk, native-VLAN mismatch, missing SVI/
  router subinterface.
- **Escalate when:** switch config change beyond your access.
- **Lesson:** 09.

## 8. Firewall blocking traffic
- **Fires as:** "service was working, now refused/timing out", new deploy unreachable.
- **First moves:** `nft list ruleset` (or `iptables -L -v -n`) — which rule/counter is hit?;
  `tcpdump` on **both** sides (does it leave A? arrive at B?); test with `nc -vz host port`.
- **Likely:** default-deny with no allow, wrong direction/zone, stateful conntrack gap, recent
  rule change, ACL order.
- **Escalate when:** security-policy decision or change on a managed firewall.
- **Lesson:** 15.

---

## Universal first-30-seconds checklist (any alert)
1. **Scope:** one host, one segment, or site-wide? (changes severity)
2. **When:** start time → correlate with any **change/maintenance**.
3. **Layer:** bottom-up — is it L1/L2 (link), L3 (routing/IP), L4 (port/firewall), L7 (service)?
4. **Evidence:** capture the diagnostic output **into the ticket** before you change anything.
