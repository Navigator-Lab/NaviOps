# Lesson 17 — AWS S3, EBS & Backups

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–16. Directly extends Lesson
> 06's `backup.sh` (local tar+retention) to cloud storage.

---

## Step 1 — Concept

### What it is

**S3 (Simple Storage Service)** = AWS's object storage — store/retrieve any
amount of data (files, "objects") via API/CLI, organized into **buckets**.
**EBS (Elastic Block Store)** = virtual hard drives attached to EC2 instances —
block storage, like a disk you `mount` (Lesson 07's LVM concepts apply
directly). **Snapshots** = point-in-time backups of EBS volumes, stored in S3
under the hood.

### Why it exists

Lesson 06's `backup.sh` writes `.tar.gz` archives to local disk — but if the
**entire server** is destroyed (hardware failure, accidental termination), local
backups are destroyed too. S3 provides durable (designed for 99.999999999% —
"11 nines" — durability), off-instance storage. EBS gives EC2 instances
persistent disks that survive instance stop/restart (unlike "instance store"
volumes, which are ephemeral) — and snapshots let you back up entire disks,
not just files.

### What problem it solves

- **"My EC2 instance was terminated and I lost everything on its disk"** — EBS volume (persists independently) + snapshots
- **"I need to store backups somewhere that survives the loss of the server itself"** — S3 bucket
- **"Old backups are piling up and costing money"** — S3 Lifecycle policies (auto-transition/expire)
- **"I accidentally overwrote/deleted an important file in S3"** — S3 Versioning
- **"Backups for compliance need to be kept 1 year but rarely accessed"** — S3 Glacier (cheap, slow-retrieval archive tier)

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** `aws s3 cp localfile.tar.gz s3://my-bucket/backups/`
  uploads a file. `aws s3 ls s3://my-bucket/` lists contents. An **EBS volume**
  is created with an instance (the "root volume") or attached separately;
  `lsblk`/`mount` (Lesson 07) work on it exactly like a local disk.
- **Level 2 — SysAdmin:** Per [AWS's S3 lifecycle docs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)
  and [AWS's versioning docs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html):
  **S3 Storage Classes** trade cost vs. retrieval speed/availability —
  `S3 Standard` (frequent access), `S3 Standard-IA` (infrequent access, cheaper
  storage, retrieval fee), `S3 Glacier` (archive, very cheap, retrieval takes
  minutes-hours). **Lifecycle policies** automate **transitions** (e.g., move
  to Standard-IA after 30 days, Glacier after 90, **expire** after 1 year) —
  this is the cloud-scale version of Lesson 06's `backup.sh` retention logic
  (`tail -n +8 | xargs rm`), but declarative and managed by AWS. **Versioning**
  keeps every version of an object — critical for "undo accidental
  delete/overwrite," but per [Eon's S3 cost guide](https://www.eon.io/blog/cut-aws-s3-costs),
  you must **explicitly handle non-current versions** with lifecycle rules too,
  or old versions accumulate cost forever (a very common real-world S3 cost
  surprise). **EBS snapshots** are **incremental** (after the first full
  snapshot, subsequent snapshots only store changed blocks) — analogous to
  Lesson 06's "keep last N backups" but AWS-managed and block-level.
- **Level 3 — Systems/Kernel (Lens D):** EBS volumes are **network-attached
  block devices** — from the EC2 instance's perspective, an EBS volume appears
  as a block device (`/dev/xvdf`, etc.) that you partition/format/mount exactly
  like a local disk (Lesson 07's `mkfs`/`mount`/`/etc/fstab`) — but the actual
  storage lives on AWS's network storage infrastructure, not physically inside
  the instance. This is why EBS volumes can be **detached from one instance and
  reattached to another** — the data isn't tied to the physical host running
  your instance. S3, by contrast, is **not a filesystem** — it's an object
  store accessed via HTTP API (PUT/GET/DELETE on objects identified by keys);
  tools like `s3fs` can *mount* S3 as a filesystem, but this is an abstraction
  layer with very different performance characteristics than a real block
  device.

### Analogy (Lens B)

- **EBS** = a removable hard drive you can plug into any computer (instance) —
  unplug it from one, plug it into another, the data is still there. **Instance
  store** (ephemeral) = a hard drive soldered into the computer's motherboard —
  if the computer dies, the drive's data is gone.
- **S3** = a vast, infinitely-scalable warehouse with a check-in/check-out
  desk (API) — you don't get "a shelf," you get "store this labeled box, I'll
  ask for it by label later." There's no "browsing the warehouse" the way you'd
  browse a filesystem's directory tree (though prefixes simulate folders).
- **S3 Lifecycle policies** = an automatic warehouse policy: "move boxes
  untouched for 30 days to the cheaper, slightly-slower-to-retrieve back room
  (Standard-IA); after 90 days, move to the off-site archive (Glacier); after a
  year, shred them (expire)" — exactly Lesson 06's retention logic, automated
  by the warehouse itself.
- **Versioning** = the warehouse keeps every previous version of a box's
  contents whenever you "replace" it — useful for undo, but you need a policy
  for "how many old versions to keep" or the warehouse fills up with history.

The "warehouse" analogy holds well but breaks down for **S3's consistency
model and "11 nines" durability** — there's no physical-warehouse equivalent of
"this box's contents are replicated across multiple physically-separate
facilities automatically, with mathematically quantified durability."

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
# S3
aws s3 mb s3://naviops-backups-<unique-suffix>     # create bucket (names are globally unique)
aws s3 cp /home/sys-ctl/backups/naviops-docs_*.tar.gz s3://naviops-backups-<suffix>/
aws s3 ls s3://naviops-backups-<suffix>/ --recursive --human-readable
aws s3 sync /home/sys-ctl/backups/ s3://naviops-backups-<suffix>/   # sync local dir to bucket

# EBS
lsblk                                # see attached block devices (Lesson 07)
aws ec2 create-snapshot --volume-id <VOL_ID> --description "naviops-backup"
aws ec2 describe-snapshots --owner-ids self
```

**Real production scenarios:**
1. **Off-site backup** — extend Lesson 06's `backup.sh` to also `aws s3 cp` the
   archive after creating it.
2. **Database backup strategy** — nightly EBS snapshot of the database volume +
   logical dumps (`pg_dump`) uploaded to S3 with lifecycle rules.
3. **Disaster recovery drill** — "if this instance disappeared right now, could
   you restore from the latest S3 backup/EBS snapshot onto a new instance?"
   (this is literally what an interviewer might ask).

### Common mistakes

- **Backups stored only on the same instance/volume they back up** — A single failure (instance termination, volume corruption) loses both data AND backup
  **Fix:** Always store backups in a **different** failure domain (S3, different region for critical data)
- **Enabling versioning without lifecycle rules for old versions** — Storage costs grow unboundedly as old versions accumulate
  **Fix:** Pair versioning with lifecycle rules expiring non-current versions after N days
- **S3 bucket with public read access by accident** — Data breach — a very common real-world incident category
  **Fix:** Block public access at the bucket level unless explicitly required (e.g., static website hosting)
- **Forgetting to test restoring from a backup** — "We have backups" but they've never been verified to actually restore
  **Fix:** Periodically test restore (this lesson's Step 5)
- **Leaving unattached EBS volumes/old snapshots around** — Ongoing storage charges for data nobody uses
  **Fix:** Periodic audit (extend `hardening_audit.sh`/`disk_report.sh` patterns)

### When NOT to over-engineer

- For a learning project, one S3 bucket with a simple lifecycle rule (expire
  after 30-90 days) is sufficient — multi-region replication, Glacier Deep
  Archive, etc. are enterprise-scale concerns.

### Interview Angle

**Scenario:** "Our EC2 instance was terminated overnight and we lost all its
data. We do have nightly backups — but to a directory on that same instance's
EBS volume. What went wrong, and what's your fix?"

A junior answer says "we need backups" — but they already had backups; the
flaw is **where** they lived. A senior answer names the actual failure: the
backup and the data shared the same failure domain, so the one event
(termination) destroyed both. The fix is concrete and matches this lesson's
pattern — extend `backup.sh` with `aws s3 cp` to push the verified `.tar.gz`
off-instance after the local `tar -tzf` check, add an S3 lifecycle policy
(transition to Standard-IA at 30 days, expire at 90) so cost doesn't grow
unbounded, and periodically run a restore drill (`aws s3 cp` back down, `tar
-tzf`) — because an untested backup isn't a backup, it's an assumption.

---

## Step 3 — Alternatives

| Topic | Alternative | Note |
|---|---|---|
| S3 (this lesson) | **EFS** (Elastic File System — a real NFS filesystem, shared across instances) | EFS for shared file access between multiple instances; S3 for object/backup storage |
| Manual `aws s3 cp` | **AWS Backup** (managed backup service) | Centralizes backup policies across EBS/RDS/etc — more relevant at scale |
| EBS snapshots | **AMI** (full instance image, includes EBS snapshots + launch config) | AMIs back up "the whole instance recipe," snapshots back up "one disk" |

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Extend Lesson 06's `scripts/backup.sh` to upload backups to S3 with a
lifecycle policy, and practice an EBS snapshot + restore cycle.

### Lens C — Manual → Automated → Why

**Manual (Lesson 06):** `backup.sh` creates a local `.tar.gz` and prunes old
local archives.

**Automated — extend your Lesson 06 `backup.sh` yourself.** You already have the
local create → verify → retain logic; the new requirement is one off-instance step:

- Add an `S3_BUCKET` variable (e.g. `s3://naviops-backups-<unique-suffix>` — keep the
  real name out of git).
- **After** the local archive is created **and verified** (the `tar -tzf` check),
  `aws s3 cp "$ARCHIVE" "${S3_BUCKET}/"` to push an off-instance copy.
- Keep your existing local retention prune (7 most recent).

Ordering matters again: verify locally, then upload, then prune — so a corrupt archive
never replaces a good off-site copy. Implement the `aws s3 cp` line into your own
script; don't paste a fresh one.

**S3 Lifecycle policy (`infra/aws/s3-lifecycle.json`):**
```json
{
  "Rules": [
    {
      "ID": "naviops-backup-retention",
      "Status": "Enabled",
      "Filter": { "Prefix": "" },
      "Transitions": [
        { "Days": 30, "StorageClass": "STANDARD_IA" }
      ],
      "Expiration": { "Days": 90 }
    }
  ]
}
```

```bash
aws s3api put-bucket-lifecycle-configuration \
  --bucket naviops-backups-<unique-suffix> \
  --lifecycle-configuration file://infra/aws/s3-lifecycle.json
```

**Why this matters:** per [AWS's lifecycle examples](https://docs.aws.amazon.com/AmazonS3/latest/userguide/lifecycle-configuration-examples.html),
this is the **standard pattern** — local retention (fast restore for recent
issues) + cloud retention with cost-optimized tiering (durable, long-term) +
automatic expiration (no manual cleanup needed, no unbounded cost growth).

### What to build, step by step

1. Create an S3 bucket (globally unique name) — block public access (default).
2. Update `scripts/backup.sh` to also `aws s3 cp` the archive (per above).
3. Create `infra/aws/s3-lifecycle.json` and apply it with
   `put-bucket-lifecycle-configuration`.
4. **EBS snapshot practice** (on your Lesson 16 EC2 instance, if still
   running, or skip if terminated — note this in your reflection):
   - `aws ec2 create-snapshot --volume-id <VOL_ID> --description "test"`.
   - `aws ec2 describe-snapshots --owner-ids self` — confirm it completed.
   - (Optional, costs apply) Create a new volume from the snapshot, attach to
     a test instance, mount it (Lesson 07), verify data.
5. Document your S3/EBS setup in `docs/aws/storage-design.md` (redacted bucket
   names/account IDs).
6. Commit `scripts/backup.sh` (updated), `infra/aws/s3-lifecycle.json`, and
   `docs/aws/storage-design.md` on `lesson/17-aws-s3-ebs-backups`.

---

## Step 5 — Verification

```bash
# Run the updated backup script
./scripts/backup.sh
aws s3 ls s3://naviops-backups-<unique-suffix>/ --human-readable

# Confirm lifecycle policy applied
aws s3api get-bucket-lifecycle-configuration --bucket naviops-backups-<unique-suffix>

# Restore drill: download and verify a backup from S3
aws s3 cp s3://naviops-backups-<unique-suffix>/naviops-docs_<timestamp>.tar.gz /tmp/
tar -tzf /tmp/naviops-docs_<timestamp>.tar.gz | head
```

### Troubleshooting

- **`aws s3 mb` fails: "BucketAlreadyExists"** — Bucket names are **globally unique** across all AWS accounts
  **Fix:** Add a unique suffix (e.g., your account ID or a random string)
- **`aws s3 cp` fails: "Access Denied"** — IAM user/role lacks `s3:PutObject` permission on this bucket
  **Fix:** Attach a policy granting `s3:PutObject`/`s3:GetObject`/`s3:ListBucket` on the specific bucket ARN (Lesson 15's least-privilege practice)
- **Lifecycle rule doesn't seem to apply** — Transitions/expirations take up to 24-48h to execute, not instant
  **Fix:** This is expected AWS behavior — verify the *configuration* is correct, don't expect immediate object movement
- **Snapshot stuck "pending" for a long time** — Normal for large volumes (incremental after first)
  **Fix:** Wait; `describe-snapshots` shows progress percentage

### Redaction check ✅

Bucket names often include account-related strings — use
`naviops-backups-<unique-suffix>` placeholders in committed docs; never commit
real bucket names that reveal your account ID.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** What's the difference between S3 (object storage) and EBS (block
storage)? Give an example of when you'd use each.

> **Your answer:**

**Q2.** **Scenario:** Your team enabled S3 versioning 6 months ago for an
important bucket, but never added lifecycle rules for non-current versions.
What's likely happened to storage costs, and how do you fix it going forward?

> **Your answer:**

**Q3.** Explain why "backups stored on the same volume/instance they protect"
is a critical flaw — tie this back to the "defense in depth" / "single point of
failure" thinking from Lesson 10.

> **Your answer:**

**Q4.** What does an S3 Lifecycle policy do, and how is it conceptually similar
to the retention logic in Lesson 06's `backup.sh`?

> **Your answer:**

**Q5.** Why are EBS snapshots described as "incremental"? What does this mean
for the time/cost of the 2nd, 3rd, etc. snapshot of the same volume vs. the
1st?

> **Your answer:**

**Q6.** You're asked in an interview: "How would you verify your backups
actually work?" What's your answer, based on Step 5 of this lesson?

> **Your answer:**

---

## Step 7 — Reflection

*(Fill in after the quiz)*

- What did you learn?
- What confused you?
- What would you do differently?

---

## Lens E — Attacker & Defender (Red / Blue)

> Red/Blue framing (Gate Rule **Lens E**, D14). Build *both* mindsets: know how the
> tools in this lesson are abused, and how a defender detects and stops them.
> Frameworks: [GTFOBins](https://gtfobins.github.io/) · [MITRE ATT&CK](https://attack.mitre.org/) · [LOLBAS](https://lolbas-project.github.io/).

**🔴 Attacker (how it's abused — Step 2):** Misconfigured **public S3 buckets** are one of the most common real-world breaches; attackers also target backups directly (ransomware, snapshot exfiltration). ATT&CK **T1530** (Data from Cloud Storage), **T1486** (Data Encrypted for Impact).

**🔵 Defender (detect & harden — Step 5):** **Block Public Access** account-wide, enforce bucket policies + default encryption, enable **versioning + MFA delete**, follow 3-2-1 with at least one immutable/offline copy, and turn on access logging to detect mass reads.

## Step 8 — Search Keywords For Further Understanding

**Core**
- `s3 vs ebs vs efs explained`
- `s3 lifecycle policy transitions expiration`
- `s3 versioning cost non-current versions`
- `ebs snapshot incremental explained`

**Tools**
- `aws s3 cp sync cli examples`
- `aws s3api put-bucket-lifecycle-configuration`
- `aws ec2 create-snapshot describe-snapshots`

**Going further (future lessons)**
- `aws cloudwatch s3 metrics monitoring`
- `aws backup service vs manual snapshots`
- `terraform aws_s3_bucket_lifecycle_configuration`

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `public s3 bucket data breach`, `MITRE ATT&CK T1530 data from cloud storage`, `s3 bucket misconfiguration`, `ransomware cloud backups T1486`
- 🔵 **Blue (defender):** `s3 block public access`, `s3 versioning mfa delete`, `3-2-1 backup immutable offline`, `s3 default encryption`

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 18 — AWS
CloudWatch & Monitoring/Alerting**.

---

*Lesson 17 written by Navi v28 · 2026-06-11 · WebSearch sources:
[AWS S3 Object Lifecycle Management](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html),
[AWS S3 Versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html),
[AWS S3 Lifecycle Configuration Examples](https://docs.aws.amazon.com/AmazonS3/latest/userguide/lifecycle-configuration-examples.html),
[Eon Cut AWS S3 Costs (Versioning + Lifecycle)](https://www.eon.io/blog/cut-aws-s3-costs)*
