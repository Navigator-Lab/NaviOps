# Lesson 17 — Pure Practical: AWS S3, EBS & Backups

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **⚠️ Offline-first (no cloud spend).** Use **LocalStack** + `awslocal` (S3, bucket policy, versioning,
> lifecycle are modeled). **Artifact:** `scripts/aws_backup_check.sh`. Never commit real bucket
> names/ARNs. **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: a private, versioned backup bucket (fluency)

**Scenario.** `NAVI-171`. Create a bucket for backups that is private, versioned (so an overwrite/delete
is recoverable), and has a lifecycle rule to expire old versions.

**Objective.** A bucket with public access blocked, versioning ON, and a lifecycle rule — verified.

**Given / constraints.** No public access. Versioning enabled before you upload.

**Hints.**
1. `awslocal s3api create-bucket`; `put-public-access-block` (all four true).
2. `put-bucket-versioning --versioning-configuration Status=Enabled`.
3. `put-bucket-lifecycle-configuration` to expire noncurrent versions after N days.

✅ **Verify.**
```bash
awslocal s3api get-bucket-versioning --bucket <b> | grep -q Enabled && echo "VERSIONING ✅"
awslocal s3api get-public-access-block --bucket <b> | grep -q '"BlockPublicAcls": true' && echo "PRIVATE ✅"
```

**Pitfalls.**
- Enabling versioning *after* uploading — earlier objects aren't protected.
- Leaving public access unblocked (the classic S3 leak).
- No lifecycle → versioned objects accumulate forever (cost/clutter).

🎯 **Stretch.** Upload a file, overwrite it, then restore the previous version via `list-object-versions` + `get-object --version-id`.

---

## Task 2 — Ticket-driven: "the backup restore doesn't work / bucket is public" (diagnose → fix)

**Scenario.** `NAVI-172` (P2). Either restore fails ("object not found" / wrong version) or an audit
says the backup bucket is world-readable. Diagnose which and fix.

**Objective.** Make a known-good restore succeed **and** confirm the bucket isn't public — fix the
specific fault.

**Given / constraints.** Recreate: a permissive bucket policy (`Principal:*`) or a broken restore path.
Fix the real cause, don't just re-upload.

**Hints.**
1. Public? `get-bucket-policy` + `get-public-access-block`. `"Principal":"*"` with `s3:GetObject` = world-readable.
2. Restore: `list-object-versions` to find the right key/version; `get-object --version-id`.
3. Verify integrity: compare checksums (`md5sum`/ETag) of original vs restored.

✅ **Verify.**
```bash
awslocal s3api get-bucket-policy --bucket <b> 2>/dev/null | grep -q '"Principal": "\*"' && echo "PUBLIC ❌" || echo "NOT PUBLIC ✅"
awslocal s3api get-object --bucket <b> --key backup.tar.gz /tmp/r.tgz && md5sum /tmp/r.tgz   # matches source
```

**Pitfalls.**
- A backup you've never test-restored is not a backup — always verify restore.
- `"Principal":"*"` in a bucket policy = public despite "block public access" confusion.
- Restoring the wrong version because versioning wasn't consulted.

🎯 **Stretch.** Add object-lock / retention reasoning: how would you make backups immutable against ransomware?

---

## Task 3 — On-call: data-loss event — restore under pressure (synthesis)

**Scenario.** `NAVI-173` (P1, time-boxed). A critical file was deleted/overwritten. Restore the last
good copy fast, prove its integrity, and document RPO/RTO in the incident note.

**Objective.** Recover the correct version, validate it, and write an incident note capturing how much
data/time was at risk (RPO/RTO) and how to prevent recurrence.

**Given / constraints.** Simulate delete + a delete-marker (versioned bucket). Don't overwrite the
remaining good versions. `scripts/aws_backup_check.sh` should confirm backup freshness.

**Hints.**
1. Deleted in a versioned bucket leaves a **delete marker** — remove it or get the prior `version-id`.
2. `list-object-versions --prefix <key>` → identify latest non-delete-marker version → `get-object --version-id`.
3. Validate integrity (checksum), then record RPO (age of the good copy) and RTO (time to restore).

✅ **Verify.**
```bash
awslocal s3api get-object --bucket <b> --key <key> --version-id <good> /tmp/restored && echo "RESTORED ✅"
scripts/aws_backup_check.sh; echo "exit=$?"      # non-zero if newest backup older than SLA
test -f docs/learning/reports/NAVI-173-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-173-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention (+ RPO/RTO).

**Pitfalls.**
- Panicking and re-uploading over the good versions.
- Not knowing your RPO (how much data since the last backup is gone) — the whole point.
- Calling it done without a checksum-verified restore.

🎯 **Stretch.** Extend `aws_backup_check.sh` to assert versioning ON + a recent object exists, exiting non-zero on any gap — a backup SLA monitor.

---

## Done?
- [ ] All ✅ Verify pass (LocalStack) · [ ] restore verified by checksum · [ ] RPO/RTO recorded · [ ] postmortem written.
- [ ] **No real AWS spend; no public buckets; no real names committed.** → [README Step 7](./README.md).
