# Root Cause Analysis — NOC Module

RCA finds **why** an incident happened so it doesn't recur — distinct from the **fix** (restore
service now). NOC does fast RCA during the incident and deeper RCA in the post-incident review.

## Method 1 — Fault-domain isolation (the network-native method)

Bisect the path to localize the fault domain — this is `mtr`/`traceroute` thinking:

```
client ──[L2]──► access-sw ──[trunk]──► dist-sw ──[L3]──► router ──► WAN ──► server
   │                 │                      │              │
 works?           works?                 works?         works?
   └──────── narrow the boundary where "works" flips to "fails" ────────┘
```

Ask at each hop: is it L1 (link/cable), L2 (switching/VLAN), L3 (routing/IP), L4 (port/firewall),
or L7 (service)? The bottom-up method (Lesson 18) *is* fault-domain isolation by layer.

## Method 2 — 5 Whys

```
Symptom: users can't reach the web app.
  Why? → DNS isn't resolving the app name.
  Why? → the recursive resolver returns SERVFAIL.
  Why? → its upstream forwarder is unreachable.
  Why? → a firewall rule change blocked UDP/53 to the forwarder.
  Why? → the change wasn't tested against DNS before rollout.  ← ROOT CAUSE
Fix (now): allow UDP/53 to forwarder. Prevent (RCA): add DNS check to change checklist.
```

## Method 3 — Fishbone (Ishikawa) for messy incidents

Categories to brainstorm causes under: **Device · Link/Physical · Config · Service ·
External (ISP/cloud) · Change/Human**. Useful when the cause isn't on one path.

## RCA output (the post-incident review)

| Field | Content |
|---|---|
| Summary | one line: what broke, impact, duration |
| Timeline | detect → ack → diagnose → fix → verify (with timestamps) |
| Root cause | the *why*, not the symptom |
| Trigger | what set it off (a change, a failure, load) |
| Resolution | what restored service |
| Prevention | the action item so it can't recur (and its owner) |
| Detection gap | could we have caught it sooner? (alert/threshold to add) |

## Blameless principle
RCA targets **systems and process**, not people. "The change wasn't tested" → add a test gate,
don't blame the changer. This is both healthier and more effective (people surface causes
honestly).

## Lab tie-in
Every incident runbook in `docs/runbooks/` ends with an RCA block. Lesson 26 formalizes it;
the troubleshooting drills feed real timelines.
