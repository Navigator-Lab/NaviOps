---
name: ADR-P02-EXP-TerminalGlossary
status: Accepted
date: 2026-04-19
version: 1.0
description: >
  Phase 8 specification for the Navi EXP report protocol — Terminal Command Glossary.
  MANDATORY on every EXP report. Defines format, extraction rules, sorting, and
  Unix Concepts block. Supersedes no prior file; extends ADR-P02 v22.3+.
---

# ADR-P02 Extension — Phase 8: Terminal Command Glossary

## What Is Phase 8

**Phase 8 — Terminal Command Glossary** is the final section of every EXP report.

It is generated **LAST** — after all other phases are written — so it can capture every terminal command that appeared anywhere in the report: Mirror Test, Phase 0 constitutional commands, Phase 1 diagnostics, Phase 2 search queries, Phase 3–6 bash blocks, Phase 7, and the report header itself.

**Placement**: Phase 8 goes AFTER Phase 7 (Reference Index) and BEFORE the Navi footer line.

---

## Enforcement Rules (Immutable)

1. **MANDATORY** — Phase 8 runs on every EXP report. No exceptions. A report missing Phase 8 is **INCOMPLETE**.
2. **Generated LAST** — write Phase 8 only after all other phases are fully written so no command is missed.
3. **Extract from the entire document** — scan Mirror Test, Phase 0–7, evidence blocks, diagnostics, bash blocks, inline code, shell snippets, verification steps, and worked examples.
4. **If zero terminal commands appear anywhere in the report**, write:
   > No terminal commands were used in this report.
5. **Do not fabricate** — every row must correspond to an actual command that appeared in the report.

---

## Format

### Table Header

```markdown
## 🖥️ Phase 8 — Terminal Command Glossary

| Command | Flags / Form Used | What it does (plain English) |
|---|---|---|
```

### Column Definitions

| Column | Rule |
|---|---|
| **Command** | The base command name only (e.g., `grep`, `python3`, `node`). No flags here. |
| **Flags / Form Used** | Exact flags and sub-commands as they appeared in the report (e.g., `grep -rn "pattern" path/`). If used multiple times with different flags, use the most specific/complex form; add a second row if the flags differ meaningfully. |
| **What it does (plain English)** | Exactly ONE sentence. Explain what the command does AND why it was used in this specific report. Max 20 words per cell. No jargon without an inline definition. Write for a beginner Linux user. |

### Sorting Rule

Sort all rows **alphabetically by the base command name** (column 1), case-insensitive, A → Z.

### Multiple-Row Rule

If the same base command was used with meaningfully different flags or sub-commands (e.g., `pip install` vs `pip list --outdated`), add a **separate row** for each distinct form.

---

## Key Unix Concepts Block

After the table, always add:

```markdown
### 🔑 Key Unix Concepts Used in This Report

- **[concept]**: [1–2 sentence plain-English explanation of what it is and why it matters]
```

Include **3–5 bullet points** covering Unix concepts that were used heavily or repeatedly in the report. Common candidates:

| Concept | When to include |
|---|---|
| Pipe `\|` | When commands were chained with `\|` |
| Redirection `2>&1` / `>` | When stderr/stdout was redirected |
| `grep` patterns / regex | When grep was used with patterns |
| `awk` basics | When awk was used |
| `sed` in-place editing | When sed -i was used |
| Environment variables `$VAR` | When env vars featured heavily |
| Exit codes `$?` | When return codes were checked |
| Here-doc `<< EOF` | When heredocs appeared |
| Background processes `&` | When processes were backgrounded |
| Subshell `$()` | When command substitution appeared |

---

## Worked Example

The following example shows what a correct Phase 8 looks like for a hypothetical EXP report about a generic web/service codebase.

---

### Example Report Commands (scattered through Phases 0–7)

```bash
python3 --version 2>&1
node --version 2>&1
git -C "$ROOT" status --short 2>&1
ls "$ROOT"/.agent/state/active_project.json 2>&1
grep -rn "TODO\|FIXME" src/ --include="*.py"
grep -rn "shell=True" src/ --include="*.py"
awk '/^def /{if(len>50)print FILENAME, name; name=$0; len=0} {len++}' src/*.py
python3 -m pytest -q 2>&1 | tail -3
find . -name "*.env" 2>/dev/null | grep -v "node_modules"
cat .gitignore 2>/dev/null | grep ".env"
npm run test 2>&1 | tail -5
```

---

### Example Phase 8 Output

## 🖥️ Phase 8 — Terminal Command Glossary

| Command | Flags / Form Used | What it does (plain English) |
|---|---|---|
| `awk` | `awk '/^def /{if(len>50)print FILENAME, name; name=$0; len=0} {len++}' src/*.py` | Scans Python files and prints function names longer than 50 lines, flagging oversized functions. |
| `cat` | `cat .gitignore 2>/dev/null \| grep ".env"` | Prints .gitignore and filters for lines that hide .env files from git. |
| `find` | `find . -name "*.env" 2>/dev/null \| grep -v "node_modules"` | Searches the project for stray env files outside the dependency folder. |
| `git` | `git -C "$ROOT" status --short` | Shows a compact list of changed/untracked files to confirm a clean starting state. |
| `grep` | `grep -rn "shell=True" src/ --include="*.py"` | Finds subprocess calls that allow shell injection — a critical security check. |
| `ls` | `ls "$ROOT"/.agent/state/active_project.json` | Checks whether the detected Project Profile was cached, confirming Boot ran. |
| `node` | `node --version` | Prints the Node.js version to confirm it meets the project's minimum. |
| `npm` | `npm run test` | Runs the project's test script via npm. |
| `python3` | `python3 -m pytest -q` | Runs the Python test suite quietly and reports pass/fail. |

### 🔑 Key Unix Concepts Used in This Report

- **Pipe `|`**: Connects two commands so the output of the first becomes the input of the second. Used here to feed `pytest` output into `tail` to show only the last lines.
- **Redirection `2>&1`**: Sends error messages (stderr) into the same stream as normal output (stdout). Used so commands don't hide errors when piped.
- **Append `>>`**: Adds content to the end of a file without overwriting it (vs `>` which replaces).
- **`grep -rn`**: `-r` searches recursively through subdirectories; `-n` prints line numbers. Together they give `path:line` for every hit — essential for pinpointing code.
- **`-C <dir>` (git)**: Runs git as if started in `<dir>`, so you can query a repo without `cd`-ing into it.

---

*Navi v27 · ADR-P02 Extension · Phase 8 Terminal Command Glossary · 2026-06-02*
