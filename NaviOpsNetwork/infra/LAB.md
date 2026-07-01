# NaviOpsNetwork — offline routing lab (quick start)

A real, no-hardware routing lab: two **FRR** routers + two **netshoot** hosts across three subnets.
Runs on Docker, **offline** after one image pull. Details of intent are in `README.md`.

```
 h1 ── net_a(10.10.1.0/24) ── r1 ── core(10.0.0.0/24) ── r2 ── net_b(10.10.2.0/24) ── h2
 .10                        .1        .1          .2         .1                       .10
```

## Start
```bash
./infra/bootstrap.sh pull      # one-time (internet once)
./infra/bootstrap.sh up        # r1 r2 h1 h2
./infra/bootstrap.sh status
```

## The exercise (Lessons 07–08: routing + subnetting)
By default h1 **cannot** reach h2 (different subnets, no routing yet). Make it work:

1. **Configure OSPF on r1:**
   ```bash
   docker exec -it clab-r1 vtysh
   conf t
   router ospf
    network 10.10.1.0/24 area 0
    network 10.0.0.0/24 area 0
   end
   write memory
   ```
2. **Same on r2** (its networks: `10.10.2.0/24`, `10.0.0.0/24`).
3. **Point each host at its local router** (hosts default to the docker gateway, not r1/r2):
   ```bash
   docker exec -it clab-h1 ip route replace default via 10.10.1.1
   docker exec -it clab-h2 ip route replace default via 10.10.2.1
   ```
4. **Verify (bottom-up, like `net_diag.sh`):**
   ```bash
   docker exec -it clab-r1 vtysh -c "show ip ospf neighbor"   # r2 should be FULL
   docker exec -it clab-r1 vtysh -c "show ip route ospf"      # learned 10.10.2.0/24
   docker exec -it clab-h1 ping -c3 10.10.2.10                # h1 -> h2 works
   docker exec -it clab-h1 traceroute 10.10.2.10             # path goes h1->r1->r2->h2
   ```

## Break/fix drills (NOC muscle)
- Shut r1's core interface (`docker exec clab-r1 ip link set eth1 down`) → OSPF neighbor drops → h1↔h2
  fails → diagnose with `show ip ospf neighbor` → bring it back.
- Remove a host's default route → "can reach local, not remote" → the classic L3 symptom.

## Monitoring (Lessons 21–22)
`./infra/bootstrap.sh monitoring` → add the lab gateways (`10.10.1.1`, `10.10.2.1`) as blackbox ICMP targets
in `monitoring/prometheus.yml`, reload, and build a Grafana panel on `probe_success` — a real NOC uptime board.

## Guardrails
Lab ranges only (RFC-1918). Never commit real device creds, SNMP community strings, VPN PSKs, or `.pcap`.
