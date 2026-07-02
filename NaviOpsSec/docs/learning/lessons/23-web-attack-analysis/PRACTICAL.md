# Lesson 23 — Pure Practical: Web Attack Analysis

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** run a simple web server on `siem-victim` + feed access logs to Wazuh. **Rules:**
> evidence before verdict, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: spot common web attacks in access logs (fluency)

**Scenario.** `SOC-231`. Learn the signatures of SQLi, XSS, path traversal, and scanners in web logs.

**Objective.** Identify each attack class in a sample/generated access log.

**Given / constraints.** Generate suspicious requests (`curl` with `../`, `' OR 1=1`, `<script>`). Match
patterns.

**Hints.**
1. Traversal: `../`/`%2e%2e`. SQLi: `UNION SELECT`, `' OR`. XSS: `<script>`. Scanners: odd UA, /admin probes.
2. `grep -iE "union|<script>|\.\./" access.log`.
3. Note request, source, likely class.

✅ **Verify.**
```bash
docker exec siem-victim sh -c 'grep -iE "union|<script>|\.\./|/admin" /var/log/*access* 2>/dev/null | head' | grep -q . && echo "WEB ATTACKS SPOTTED ✅"
```

**Pitfalls.**
- URL-encoding hiding the payload (`%2e`, `%27`).
- Case sensitivity missing `UNION`/`union`.
- 200 vs 4xx — did the attack succeed?

🎯 **Stretch.** Distinguish a probe (404s) from a successful attack (200 + unusual response size).

---

## Task 2 — Ticket-driven: "web alert — did the attack succeed?" (diagnose → verdict)

**Scenario.** `SOC-232` (P2). A WAF/log alert fired on a web request. Decide: blocked probe vs successful
exploitation.

**Objective.** A verdict on success/failure backed by status codes, response sizes, and follow-on activity.

**Given / constraints.** Evidence-based. Look beyond the single request.

**Hints.**
1. Status code + response size for the malicious request.
2. Follow-on: did the source then access something new?
3. Verdict + action.

✅ **Verify.**
```bash
grep -qiE 'succeeded|blocked|verdict' docs/learning/reports/SOC-232-verdict.md && echo "VERDICT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-232-verdict.md`: request · status/size · follow-on · verdict · action.

**Pitfalls.**
- Assuming a matched signature = successful compromise.
- Ignoring the response (200 + data = success).
- Not checking what the source did next.

🎯 **Stretch.** Map to OWASP category + MITRE technique.

---

## Task 3 — On-call: web app under active attack (synthesis)

**Scenario.** `SOC-233` (P1, time-boxed). Sustained web attacks (scanning → exploitation attempts).
Detect, determine impact, contain the source, and write an IR note.

**Objective.** Confirm scope + impact, contain, and document with IoCs + affected endpoints.

**Given / constraints.** Generate a campaign. Contain by rule; preserve logs.

**Hints.**
1. Scope: which endpoints, which payloads, success indicators.
2. Contain: block the source / WAF rule.
3. IR note: impact, IoCs, MITRE, remediation (patch/validate input).

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-233-web-attack.md && grep -qiE 'ioc|endpoint|containment' docs/learning/reports/SOC-233-web-attack.md && echo "IR NOTE ✅"
```

**Deliverable.** `docs/learning/reports/SOC-233-web-attack.md`: scope · impact · IoCs · containment · remediation · MITRE.

**Pitfalls.**
- Blocking one payload while the campaign continues on others.
- No impact assessment (did anything succeed?).
- No app-side remediation (only blocking the source).

🎯 **Stretch.** Write a detection rule for the specific payload family seen.

---

## Done?
- [ ] All ✅ Verify pass · [ ] success-vs-probe determined · [ ] IR note with IoCs + remediation.
- [ ] **Guardrails:** lab only; fake payloads/sources. → [README Reflection](./README.md).
