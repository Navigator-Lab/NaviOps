# Lesson 02 — Troubleshooting Log: GitHub SSH Push

**Status:** unresolved · **Date:** 2026-06-11
**Source:** real terminal session from this repo (`~/NaviOps`), captured live during
Step 4g (push to `Navigator-Lab/NaviOps`).

This is a **Step 5 (Verification/Troubleshooting) supplement** — real production
debugging, not a toy exercise (Top-Level Rule 2). Each bug below gives you the
**symptom**, **why it happens** (the underlying mechanism), and a **hint** toward the
diagnostic path — **not the fix command itself**. Work through them in order, run the
diagnostics the hints point at, write down what you find, then attempt the fix
yourself. This is the Step 6 "scenario-based" muscle in action, before the quiz even
starts.

---

## Bug 1 — `error: remote origin already exists`

**Symptom:**
```
$ git remote add origin git@github.com:Navigator-Lab/NaviOps.git
error: remote origin already exists.
```

**Why this happens:**
A Git repo can have multiple **remotes** (named pointers to other repo URLs), but each
**name** must be unique. `git remote add <name> <url>` *creates a new* remote named
`<name>` — it errors if that name is already taken, even if the URL you're adding is
identical to the existing one. Something earlier in this repo's history (the original
NaviOps scaffold, or an earlier attempt) already registered a remote called `origin`.

**Hint:**
- This error is **informational, not blocking** — it doesn't mean your remote is
  broken, just that `add` was the wrong subcommand for "I already have one and want to
  change it."
- Run the *read-only* inspection command shown two steps later in this transcript
  (`git remote -v`) **first**, before trying to add/change anything — what does it
  tell you about whether `origin` already points where you want it to?
- There are two different git subcommands for "remote already exists, I want to
  change its URL" vs "remove it and start over" — `git remote --help` lists both.

**Glossary:**
- **remote** — a named reference to another copy of the repository (usually on a
  server like GitHub), e.g. `origin`. A repo can have several (`origin`, `upstream`,
  etc.).
- **`origin`** — the *conventional* (not magic) name for "the main remote you cloned
  from / push to." Just a label — could be called anything.
- **`git remote add <name> <url>`** — registers a *new* remote. Fails if `<name>`
  already exists.

---

## Bug 2 — `git push -u origin main` → `Permission denied (publickey)`

**Symptom:**
```
$ git push -u origin main
git@github.com: Permission denied (publickey).
fatal: Could not read from remote repository.
```

**Why this happens:**
The remote URL `git@github.com:...` uses the **SSH protocol** (note the `git@` user
and `:` separator instead of `https://`). When Git pushes over SSH, it's really
running `ssh git@github.com ...` under the hood. GitHub's SSH server accepts a
connection only if the **client offers a public key that's registered on a GitHub
account** (Settings → SSH and GPG keys). "Permission denied (publickey)" means: SSH
connected to GitHub fine (the network/hostname is reachable), but **none of the keys
your SSH client offered are recognized by GitHub**.

This is *not* a Git problem — `git push` never even got to the "find/update the
branch" stage. It failed at the **transport/authentication layer**, one level below
Git.

**Hint:**
- This error is reproducible with **plain `ssh`**, no `git` involved at all — GitHub
  provides a special diagnostic SSH command for exactly this (used later in this same
  transcript). What does it tell you, and is the result the *same* or *different* from
  this `git push` failure?
- Two independent things determine "which key gets offered": (1) what keys exist in
  `~/.ssh/`, and (2) what keys SSH actually *tries* for a given host — those are not
  automatically the same thing.
- A fresh `ls -la ~/.ssh/` is worth doing — how many key pairs exist, and how recently
  was each one created? A very recently created key has one extra step that older,
  working keys already had done.

**Glossary:**
- **SSH protocol (git URL form `git@github.com:org/repo.git`)** vs **HTTPS form**
  (`https://github.com/org/repo.git`) — two ways to reach the same remote repo, with
  completely different auth mechanisms (SSH key vs username/token).
- **public/private key pair** — an asymmetric cryptography key pair. The **private**
  key (e.g. `id_ed25519`, no extension) never leaves your machine and must be `600`
  (Lesson 01!). The **public** key (`id_ed25519.pub`) is safe to share — you upload it
  to services like GitHub.
- **"Permission denied (publickey)"** — SSH-level rejection: the server didn't accept
  any key the client presented. This message comes from `sshd` on GitHub's side, not
  from Git.

---

## Bug 3 — `ssh -i ~/.ssh/id_NaviOps git@github.com:Navigator-Lab/NaviOps.git` → hostname resolution error

**Symptom:**
```
$ ssh -i ~/.ssh/id_NaviOps git@github.com:Navigator-Lab/NaviOps.git
ssh: Could not resolve hostname github.com:Navigator-Lab/NaviOps.git: Name or service not known
```

**Why this happens:**
This is a **syntax mix-up between two different URL styles**. `git@github.com:org/repo.git`
is **Git's "scp-like" shorthand** — it's meaningful to `git` (and to `scp`/`rsync`),
which know to split it into "host = `github.com`, path = `org/repo.git`". The plain
`ssh` command does **not** understand this shorthand the same way when given as a
single trailing argument like this — it treats the *entire string*
`github.com:Navigator-Lab/NaviOps.git` as one hostname to look up in DNS, which of
course doesn't exist as a hostname.

**Hint:**
- `ssh` is a **general-purpose remote-login tool** — its normal job is "log into a
  host and get a shell," not "talk to a git repository." What would you expect the
  *correct* arguments to plain `ssh -i <key> ...` to be, if the goal is just "test
  whether GitHub accepts this key" (not "clone this specific repo")?
- Compare this command's argument shape to the one used successfully two commands
  later in this transcript (`ssh -T git@github.com`) — what's different about what
  comes after `git@github.com`?

**Glossary:**
- **scp-like syntax** (`user@host:path`) — shorthand used by `scp`, `rsync`, and `git`
  to mean "this host, this path on that host." Not valid as a literal `ssh` connection
  target.
- **`ssh -i <file>`** — "use this specific private key file for this connection,"
  overriding SSH's default key search.
- **hostname resolution** — the step (DNS lookup) where a name like `github.com` is
  turned into an IP address, *before* any connection is attempted. "Could not resolve
  hostname" means this step failed — it never even got to authentication.

---

## Bug 4 — `git remote set-url origin ...` (no error) then `ssh -T git@github.com` → `Permission denied (publickey)` again

**Symptom:**
```
$ git remote set-url origin git@github.com:Navigator-Lab/NaviOps.git
(no output)

$ ssh -T git@github.com
git@github.com: Permission denied (publickey).
```

**Why this happens:**
`git remote set-url` succeeded silently because it did exactly what it was asked —
**it changed the remote's URL to the same value it already had**. It's a **local,
config-only** change; it can't fix an *authentication* problem because the URL was
never the problem (Bug 1 already showed `origin` pointed at the right place).

The repeated `Permission denied (publickey)` — this time from `ssh -T`, GitHub's
**official "test your SSH connection" command**, with *zero* git or remote-URL
involvement — confirms the root cause is **entirely on the SSH/key side**, isolated
from Bugs 1 and 3. `set-url` was a reasonable thing to *check*, but it was treating a
symptom (the remote) rather than the cause (the key/auth setup).

**Hint:**
- `ssh -T git@github.com` is the cleanest possible test — it removes Git, remote URLs,
  and repo paths entirely from the equation. Whatever's wrong is purely "this SSH
  client + this set of keys + this GitHub account."
- Three independent things all have to line up for `ssh -T git@github.com` to succeed:
  (1) a key pair exists locally, (2) **that exact key's public half** is uploaded to
  *this* GitHub account's settings, and (3) SSH actually **offers that key** when
  connecting to `github.com` (which depends on `ssh-agent` and/or `~/.ssh/config`).
  Which of these three would you check first, and with what command? (You already
  have a tool from Lesson 01 for inspecting file metadata...)
- If there's more than one key pair under `~/.ssh/`, and one is older than the others,
  consider: was the *newest* one ever shown to GitHub at all?

**Glossary:**
- **`ssh -T git@github.com`** — GitHub's documented connectivity test. `-T` disables
  pseudo-terminal allocation (you're not trying to get a shell — GitHub's SSH endpoint
  doesn't give you one anyway, it just identifies you and replies with a greeting).
- **`ssh-agent`** — a background process that holds decrypted private keys in memory
  so SSH doesn't have to ask for a passphrase every time. `ssh-add -l` lists what it's
  currently holding (an empty list means SSH falls back to its **default key file
  search order**).
- **`~/.ssh/config`** — per-host SSH client configuration. A `Host github.com` block
  with an `IdentityFile` line tells SSH *which* key to offer for that host —  without
  it, SSH only tries its default filenames (`id_rsa`, `id_ecdsa`, `id_ed25519`, ...),
  which may or may not include a newly generated, differently-named key.
- **key fingerprint** — a short hash that uniquely identifies a key pair
  (`ssh-keygen -lf <file>`). Used to confirm "is *this* the key GitHub has on file?"
  without comparing the full key text.

---

## Diagnostic Path (read-only — no fixes yet)

Work these in order. Each is **safe and non-destructive** — pure inspection:

1. `ls -la ~/.ssh/` — how many key pairs, which is newest? (Lesson 01: `ls -l`
   shows you ownership/permissions too — are the private keys `600`?)
2. `ssh-add -l` — what does `ssh-agent` currently know about?
3. `cat ~/.ssh/config` — is there a `Host github.com` block, and does it point at the
   key you expect?
4. `ssh-keygen -lf ~/.ssh/<each-pubkey>` — get the fingerprint of each public key.
5. On GitHub: Settings → SSH and GPG keys — which fingerprint(s) are registered, and
   on *which* account?

Once you've run these and written down what you found, you'll likely be able to name
the exact missing link yourself — that's the goal before moving to the fix.

---

## Glossary — Full List (Quick Reference)

- **`git remote`** — Local config mapping a short name (e.g. `origin`) to a repo URL
- **`origin`** — Conventional name for the primary remote
- **`git remote add <name> <url>`** — Register a new remote (errors if name exists)
- **`git remote set-url <name> <url>`** — Change an existing remote's URL
- **`git remote -v`** — List remotes with their fetch/push URLs (read-only)
- **SSH URL (`git@host:org/repo.git`)** — scp-like shorthand; auth via SSH key
- **HTTPS URL (`https://host/org/repo.git`)** — Auth via username/token, not SSH key
- **Private key (`id_*`, no extension)** — Secret half of a key pair; must be `600`
- **Public key (`id_*.pub`)** — Shareable half; uploaded to GitHub
- **`ssh -i <file>`** — Force SSH to use a specific private key
- **`ssh -T git@github.com`** — GitHub's official "test my SSH auth" command
- **"Permission denied (publickey)"** — SSH server rejected all offered keys
- **"Could not resolve hostname"** — DNS lookup of the given name failed (pre-auth)
- **`ssh-agent`** — Background process caching unlocked private keys
- **`ssh-add -l`** — List keys currently loaded in the agent
- **`~/.ssh/config`** — Per-host SSH client config (e.g. `IdentityFile`, `Host` aliases)
- **`ssh-keygen -lf <file>`** — Print a key's fingerprint
- **Key fingerprint** — Short hash identifying a key pair, used to match local↔remote

---

## Resolution (2026-06-11)

**Root cause:** SSH was never offering a key that GitHub recognizes.
- `ssh-add -l` → "The agent has no identities" — `ssh-agent` had nothing loaded.
- `~/.ssh/config` had **no `Host github.com` block** — so SSH only tried its default
  filenames (`id_rsa`, `id_ecdsa`, `id_ed25519`...), never the newly-generated
  `id_NaviOps`.
- `id_NaviOps.pub` (fingerprint `SHA256:o0ceuDSNWayhDynv0kxYfVrx9I4HTtcgP54vjwwUS9A`)
  had not yet been added to the GitHub account that owns `Navigator-Lab/NaviOps`.

**Fix — 3 steps:**

1. **Tell SSH which key to use for GitHub** — add to `~/.ssh/config`:
   ```
   Host github.com
     HostName github.com
     User git
     IdentityFile ~/.ssh/id_NaviOps
     IdentitiesOnly yes
   ```
   `IdentitiesOnly yes` stops SSH from also trying the other keys in `~/.ssh/` first
   (which would otherwise burn GitHub's auth attempts on the wrong key).

2. **Register the public key on GitHub** — copy the output of
   `cat ~/.ssh/id_NaviOps.pub` into GitHub → Settings → SSH and GPG keys → New SSH key.

3. **Verify, then push:**
   ```bash
   ssh -T git@github.com   # expect: "Hi <username>! You've successfully authenticated..."
   git push -u origin main
   git push -u origin lesson/02-git-github-fundamentals
   ```

**Bug 1 (`remote origin already exists`)** needed **no fix** — `git remote -v` showed
`origin` already pointed at the correct URL. `git remote add` was simply the wrong
subcommand for an existing remote (`set-url` is, but wasn't even necessary here).

**Bug 3 (`ssh -i ... github.com:org/repo.git` → hostname resolution error)** was a
syntax mix-up: plain `ssh` takes a **host**, not a git scp-like `host:path` string.
The correct test form is `ssh -T -i ~/.ssh/id_NaviOps git@github.com` (or, once Step 1's
config block is in place, just `ssh -T git@github.com`).
