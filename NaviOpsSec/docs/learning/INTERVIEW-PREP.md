# NaviOpsSec — Interview Prep (SOC / Security Analyst)

The interview-grade question bank for the roles this platform targets. Every lesson's §Quiz is a
slice of this; here it's consolidated by theme with the **what a strong answer hits** notes. Use
it to rehearse out loud — and to answer with *your own artifacts* as proof.

> The single best interview move on this platform: when asked a concept, **answer it, then point
> to the artifact you built** ("…and I have a Wazuh rule + runbook for exactly that in
> `lessons/19`"). That's what separates you from a candidate who only studied.

## 1. Fundamentals & vocabulary
- Explain the **CIA triad** with a real trade-off (availability vs confidentiality).
  *Strong answer:* defines each, gives a concrete control for each, names a real tension.
- **Threat vs vulnerability vs risk vs exploit** — define and relate (risk = threat × vuln ×
  impact).
- **IOC vs IOA vs TTP**, and why TTPs sit higher on the **Pyramid of Pain**.
- **Defense in depth** — name layers on a Linux server.

## 2. Frameworks
- Walk an intrusion through the **Cyber Kill Chain** *and* map the same steps to **MITRE
  ATT&CK** tactics. *Strong answer:* shows you use ATT&CK for detection coverage, not as trivia.
- What's the **Diamond Model** and when do you reach for it vs the kill chain?
- How do you measure **ATT&CK coverage** and find detection gaps?

## 3. Linux investigation (the platform's edge)
- "A host is acting strange. **First five commands?**" *Strong answer:* `ps`/`ps auxf` + `/proc`,
  `ss -tunap`, `last`/`lastb`/`who`, `journalctl`/`auth.log` grep, `find` for recent/SUID files,
  and *says why each* (process tree → network → logins → logs → persistence).
- How do you read `auditd` records, and what would you watch with `auditctl -w`?
- Find **failed SSH logins** by source IP from the logs — give the one-liner. (`grep "Failed
  password" … | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn`.)
- How do you spot a **reverse shell** / unexpected outbound connection on a box?

## 4. SIEM & detection (Wazuh)
- What does a **SIEM** do, end to end (collection → normalization → correlation → alert)?
- In **Wazuh**, what's the difference between a **decoder** and a **rule**? How do rule
  **levels/groups/frequency** work, and how do you test with `wazuh-logtest`?
- Write/explain a detection for **brute force** — and how you'd **tune the false positives**.
- What is a **Sigma** rule and why does portable detection content matter?
- "Your detection is noisy. How do you decide threshold vs allowlist vs context enrichment?"

## 5. Alert triage & investigation
- Walk your **triage decision tree**: alert → TP/FP? → severity → scope → escalate or close.
- What makes an alert a **true positive**? How do you **scope** it (one host vs many)?
- How do you build an **attack timeline** and extract **IOCs** to pivot on?
- "You have 40 alerts and one analyst. **How do you prioritize?**"

## 6. Incident response
- The **NIST 800-61** lifecycle — name the phases and what you do in each.
- **Short-term vs long-term containment** — give an example of each and the trade-off
  (preserve evidence vs stop the bleeding).
- Why **preserve evidence before containment**, and what attacker technique threatens it
  (T1070 indicator removal / log tampering)?
- What goes in a **technical report** vs an **executive summary**, and who reads each?

## 7. Scenario rounds (rehearse end-to-end, out loud)
- "**SSH brute force then a successful login** from the same IP — walk me through detection →
  investigation → containment → report."
- "**A new admin user appeared** at 03:00. What do you do?" (T1136 — check who created it,
  correlate the session, look for persistence, scope, contain.)
- "**A web server's access log shows `../../etc/passwd` and `UNION SELECT`.** Triage it."
- "**A host is beaconing to one external IP every 60s.** What do you suspect and do?"
- The **capstone**: "You're told a Linux server is compromised. Take it from here." (This is
  literally Lesson 35 — rehearse it from your own report.)

## 8. Behavioral / fit
- "Tell me about a time you investigated something." → *use a real lesson investigation.*
- "How do you keep up with threats?" → threat intel feeds, ATT&CK updates, your build log.
- "Why Blue Team / SOC?" → the defender's craft, operations, the artifact-backed story.

## How to practice
Each lesson's graded quiz + Professional-Answer comparison *is* a rehearsal. Do them out loud.
For the scenario rounds, narrate from the actual runbook/incident report you wrote — interviewers
can tell the difference between memorized theory and "I did this."
