# Lesson 13 — Ansible Fundamentals

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–12. Marks the start of
> automating everything you've done **manually** in Lessons 03–10 — Ansible is
> where the "why idempotency matters" lessons (03 Q3, 06 Q6) pay off directly.

---

## Step 1 — Concept

### What it is

**Ansible** is an agentless configuration-management and automation tool. You
describe the **desired state** of one or more servers in YAML files
(**playbooks**), and Ansible connects over SSH (no agent to install on targets)
and makes each target match that state.

### Why it exists

Everything you've done by hand so far — hardening a server (Lesson 10),
configuring SSH (Lesson 07), setting up cron jobs (Lesson 06), installing
packages — works for **one** server. Real environments have dozens, hundreds,
or thousands of servers. Doing this manually doesn't scale, isn't repeatable,
and configuration **drifts** (server #47 gets a manual fix that's never applied
to the other 99). Ansible turns your manual runbooks into **code** that runs
identically across any number of servers.

### What problem it solves

| Problem | Ansible solution |
|---|---|
| "Apply the Lesson 10 hardening checklist to 50 servers" | One playbook, run against an inventory of 50 hosts |
| "Server #23 has a different `sshd_config` than the others — why?" | Configuration as code — drift becomes visible (diff against playbook) |
| "Re-running my setup script breaks things the second time" | Ansible modules are **idempotent** — safe to run repeatedly |
| "New server provisioning takes a day of manual steps" | `ansible-playbook site.yml -l newserver` |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** An **inventory** file lists target hosts (by IP/hostname),
  optionally grouped (`[webservers]`, `[databases]`). **Ad-hoc commands** run a
  single module against hosts without a playbook:
  `ansible webservers -m ping`, `ansible all -m shell -a "df -h"`. A
  **playbook** is a YAML file with a list of **plays**, each targeting a group of
  hosts and containing a list of **tasks** (each task = one module call).
- **Level 2 — SysAdmin:** Per [Red Hat's Good Practices for Ansible](https://redhat-cop.github.io/automation-good-practices/)
  and [env0's playbook guide](https://www.env0.com/blog/ansible-playbooks-step-by-step-guide):
  **idempotency** is the core principle — most `ansible.builtin` modules
  (`apt`, `yum`, `lineinfile`, `copy`, `service`) are idempotent: `apt` with
  `state: present` won't reinstall an already-installed package; `lineinfile`
  won't re-edit a line that already matches. This is *exactly* the idempotency
  concept from Lesson 03 (Q3) and Lesson 06 (Q6) — Ansible playbooks describe
  **desired state**, and Ansible only makes **changes when needed** (a task
  reports `changed` vs `ok`). **Roles** organize reusable automation
  (`roles/hardening/tasks/main.yml`, `roles/hardening/handlers/main.yml`) — a
  role packages tasks, handlers (e.g., "restart sshd if config changed"),
  templates, and default variables for one concern, reusable across playbooks.
  **`group_vars/`** and **`host_vars/`** hold variables scoped to inventory
  groups/hosts — e.g., `group_vars/webservers.yml` sets `http_port: 8080` for
  all web servers. **Ansible Vault** encrypts secrets (passwords, keys) so they
  can be committed to git safely (`ansible-vault encrypt secrets.yml`).
  **`ansible-lint`** statically checks playbooks for anti-patterns (using
  `command`/`shell` where a proper module exists, missing task names,
  deprecated syntax).
- **Level 3 — Systems/Kernel (Lens D):** Ansible is "agentless" because each
  task is executed by **copying a small Python script (the module) to the
  target over SSH, running it, and parsing its JSON output, then deleting it**
  — no persistent daemon runs on targets (contrast with Puppet/Chef agents).
  This is why Python must be present on managed nodes (`ansible_python_interpreter`).
  The SSH connection itself relies on everything from Lesson 07 (key-based
  auth) — Ansible's default connection plugin is literally `ssh`, running
  commands as the configured remote user, optionally escalating with
  `become: true` (≈ `sudo`).

### Analogy (Lens B)

- **Ansible playbook** = a recipe written for "make sure the kitchen ends up in
  this state" rather than "do these steps in order regardless of current
  state" — if the oven is already preheated, the recipe doesn't preheat it
  again (idempotency); if it's not, it does. Compare to a shell script, which
  is more like "always do steps 1-10 in order" (Lesson 03's non-idempotent
  scripts) — re-running it might preheat an already-hot oven, wasting energy or
  causing harm.
- **Inventory groups** = a building's floor directory — "all servers on floor 2
  (webservers) get policy A; floor 3 (databases) gets policy B" — and
  `group_vars`/`host_vars` are like floor-specific vs. room-specific notices
  pinned to those directories.
- **Roles** = standardized job descriptions/checklists ("the hardening role" =
  a checklist that any server can have applied, regardless of what else is on
  it) — reusable across many different "buildings" (playbooks/projects).

The recipe analogy holds well, but breaks down for **agentless SSH execution**
(Level 3) — there's no real-world equivalent of "the recipe walks itself into
each kitchen, executes itself, reports back, and leaves no trace of having been
there."

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
ansible all -i inventory.ini -m ping                      # connectivity check
ansible webservers -i inventory.ini -m shell -a "uptime"  # ad-hoc command
ansible-playbook -i inventory.ini site.yml                 # run a playbook
ansible-playbook -i inventory.ini site.yml --check         # dry-run (no changes made)
ansible-playbook -i inventory.ini site.yml --diff          # show what would change
ansible-lint site.yml                                       # lint for best practices
ansible-vault encrypt group_vars/all/secrets.yml            # encrypt secrets
```

**Real production scenarios:**
1. **Fleet-wide hardening** — apply Lesson 10's hardening checklist as an
   `ansible-hardening`-style role across every server, with `--check` run first
   in CI to catch drift.
2. **New server onboarding** — `ansible-playbook site.yml -l newserver01`
   brings a fresh VM to the same state as the rest of the fleet in minutes.
3. **Patch management** — `ansible all -m apt -a "upgrade=dist update_cache=yes"
   --become` (with `--check` first!) across all hosts.

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Using `command`/`shell` modules for everything | Not idempotent — every run shows `changed`, breaks `--check` mode, harder to reason about | Use proper modules (`apt`, `copy`, `lineinfile`, `service`, etc.) — `ansible-lint` flags this |
| Hardcoding secrets in playbooks | Secrets in git history forever | `ansible-vault` from day one |
| No `--check`/`--diff` before running on production | Surprise changes across the whole fleet | Always dry-run first, especially for new/edited playbooks |
| One giant playbook with no roles | Unmaintainable, not reusable | Break into roles by concern (hardening, webserver, monitoring) |
| Missing task `name:` fields | Output is unreadable (`TASK [shell]` instead of `TASK [Install nginx]`), `ansible-lint` flags it | Always name tasks descriptively |

### When NOT to use Ansible

- Real-time orchestration/auto-scaling reacting to load — Ansible is
  **push-based** and run on-demand/scheduled, not a continuously running
  control loop (that's Kubernetes controllers' domain).
- Managing Windows-heavy environments exclusively — possible (WinRM) but
  Ansible's strongest fit is Linux/Unix via SSH.

### Interview Angle

**Question:** "You need to roll out a security patch across 50 servers tonight.
How do you make sure it doesn't break production, and how do you know the
playbook is actually idempotent?"

A junior answer jumps straight to `ansible-playbook site.yml -m apt -a
"upgrade=dist"` against all hosts. A senior answer leads with `--check --diff`
first to preview changes without applying them, runs against a small `-l`
subset before the full fleet, and explains idempotency concretely: running the
playbook twice should report `changed=0` the second time. They'd also flag
that `shell`/`command` modules break this guarantee — every run shows
`changed`, so proper modules (`apt`, `service`, `lineinfile`) are required for
`--check` mode to mean anything. The senior framing is "prove nothing changes
on a re-run," not "did the command succeed."

---

## Step 3 — Alternatives

| Tool | Use case |
|---|---|
| **Ansible** (this lesson) | Agentless, YAML, huge module library, gentle learning curve — most common entry point for SysAdmin automation |
| **Puppet / Chef** | Agent-based, more mature in some enterprises, steeper learning curve (Ruby DSL) |
| **Terraform** (Lesson 20) | **Provisions infrastructure** (creates the VM/server itself); Ansible **configures** what's already provisioned — often used together (Terraform creates, Ansible configures) |
| **Shell scripts** (Lessons 03-10) | Fine for single-host, one-off tasks; don't scale to fleets and aren't idempotent by default |

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Write an Ansible playbook that automates a piece of Lesson 10's
hardening checklist (or Lesson 06's cron/backup setup) against your lab VM(s).

### Lens C — Manual → Automated → Why

**Manual** (Lesson 10): SSH into each server, manually edit
`/etc/sysctl.d/99-hardening.conf`, run `sysctl -p`, check `auditd` status —
repeat per server, hope you didn't forget one.

**Automated (`playbooks/hardening.yml`):**
```yaml
---
- name: Apply NaviOps baseline hardening
  hosts: all
  become: true
  vars:
    sysctl_settings:
      net.ipv4.ip_forward: 0
      net.ipv4.conf.all.accept_redirects: 0
      net.ipv4.tcp_syncookies: 1

  tasks:
    - name: Apply hardened sysctl parameters
      ansible.posix.sysctl:
        name: "{{ item.key }}"
        value: "{{ item.value }}"
        sysctl_file: /etc/sysctl.d/99-hardening.conf
        reload: true
      loop: "{{ sysctl_settings | dict2items }}"

    - name: Ensure auditd is installed and running
      ansible.builtin.package:
        name: auditd
        state: present

    - name: Ensure auditd service is enabled and running
      ansible.builtin.service:
        name: auditd
        state: started
        enabled: true

    - name: Ensure SSH root login is disabled
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^#?PermitRootLogin'
        line: 'PermitRootLogin no'
      notify: Restart sshd

  handlers:
    - name: Restart sshd
      ansible.builtin.service:
        name: sshd
        state: restarted
```

**Inventory (`inventory.ini`):**
```ini
[lab]
vm-alma ansible_host=10.0.x.x ansible_user=sys-ctl

[lab:vars]
ansible_python_interpreter=/usr/bin/python3
```

**Why this matters:** every task here is **idempotent** — run it 10 times,
only the first run reports `changed` (assuming the system was previously
unhardened); subsequent runs report `ok`. This is the direct payoff of Lessons
03/06's idempotency discussions, now enforced by the tool itself rather than
by careful script-writing.

### What to build, step by step

1. Install Ansible on your control machine (the one running playbooks, not
   necessarily the target).
2. Write `inventory.ini` with your lab VM(s) (use `10.0.x.x` placeholders if
   committing).
3. Run `ansible lab -i inventory.ini -m ping` — confirm SSH connectivity works
   (this is Lesson 07's SSH key auth in action).
4. Write `playbooks/hardening.yml` per the structure above (adapt to what your
   VM's distro supports — `auditd` package name differs between
   AlmaLinux/Ubuntu).
5. Run with `--check --diff` first — review what *would* change.
6. Run for real: `ansible-playbook -i inventory.ini playbooks/hardening.yml`.
7. Run it **again** — confirm the second run shows 0 `changed` tasks (proof of
   idempotency).
8. `ansible-lint playbooks/hardening.yml` — fix any warnings.
9. Commit `inventory.ini` (redacted IPs) and `playbooks/hardening.yml` on
   `lesson/13-ansible-fundamentals`.

---

## Step 5 — Verification

```bash
ansible lab -i inventory.ini -m ping

ansible-playbook -i inventory.ini playbooks/hardening.yml --check --diff
ansible-playbook -i inventory.ini playbooks/hardening.yml
ansible-playbook -i inventory.ini playbooks/hardening.yml   # second run

ansible-lint playbooks/hardening.yml
```

Second run's recap line should show `changed=0` for all hosts — this is your
idempotency proof.

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `ansible ... -m ping` fails: "UNREACHABLE" | SSH key/connectivity issue | Test `ssh` manually first (Lesson 07); check `ansible_user`/`ansible_host` |
| "python: command not found" on target | Minimal OS image without Python | `ansible_python_interpreter=/usr/bin/python3` in inventory, or install Python first via `raw` module |
| `become` fails with permission error | User doesn't have passwordless sudo | Configure `sudoers` for the Ansible user, or use `--ask-become-pass` |
| Second run still shows `changed` | A task uses `command`/`shell` (not idempotent), or `lineinfile` regex doesn't match existing line | Use proper modules; test `regexp` carefully |
| `ansible-lint` errors about missing `name:` | Style/best-practice violation | Add descriptive `name:` to every task |

### Redaction check ✅

`inventory.ini` real IPs → `10.0.x.x`; don't commit any vault password files or
unencrypted secrets.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** What does **idempotent** mean for an Ansible task, and why does it
matter when running a playbook against 100 servers? (Tie back to Lesson 03 Q3
and Lesson 06 Q6.)

> **Your answer:**

**Q2.** **Scenario:** Your playbook uses
`shell: "echo 'PermitRootLogin no' >> /etc/ssh/sshd_config"`. What's wrong with
this approach (two issues), and what module/approach should you use instead?

> **Your answer:**

**Q3.** What is `--check` mode, and why would you always run it before applying
a new/edited playbook to production?

> **Your answer:**

**Q4.** Explain the difference between an **inventory**, a **playbook**, and a
**role**. How do they relate to each other?

> **Your answer:**

**Q5.** How does Ansible Vault help with the "secrets in git" problem from
Lesson 12 (Q6)? What command would you run before committing a file containing
a database password?

> **Your answer:**

**Q6.** Why is Ansible described as "agentless," and what does it actually do
under the hood when it runs a task against a remote host? (Tie back to Lesson
07's SSH.)

> **Your answer:**

---

## Step 7 — Reflection

*(Fill in after the quiz)*

- What did you learn?
- What confused you?
- What would you do differently?

---

## Step 8 — Search Keywords For Further Understanding

**Core**
- `ansible idempotency explained`
- `ansible playbook vs role vs inventory`
- `ansible check mode diff dry run`
- `ansible vault encrypt secrets`

**Tools**
- `ansible-lint best practices`
- `ansible group_vars host_vars`
- `ansible handlers notify explained`

**Going further (future lessons)**
- `ansible aws ec2 dynamic inventory`
- `github actions ansible-playbook ci`
- `terraform plus ansible workflow`

---

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 14 — GitHub
Actions CI Basics**.

---

*Lesson 13 written by Navi v28 · 2026-06-11 · WebSearch sources:
[Red Hat Good Practices for Ansible](https://redhat-cop.github.io/automation-good-practices/),
[env0 Ansible Playbooks Guide 2026](https://www.env0.com/blog/ansible-playbooks-step-by-step-guide),
[Ansible Playbooks Official Docs](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_intro.html),
[MakeAutomation Top 10 Ansible Best Practices 2026](https://makeautomation.co/ansible-best-practices/)*
