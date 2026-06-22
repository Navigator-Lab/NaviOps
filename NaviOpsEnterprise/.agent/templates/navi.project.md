# navi.project.md — Project Overlay (template)

> Drop this file in a project's root. Navi v27 loads it right after detection as the project's **Project Law**.
> It is the ONLY place project-specific rules live — Navi's core (`.agent/`) stays project-agnostic.

## Identity
- **name**: <project name>
- **one-liner**: <what this project is>
- **stack**: <languages / frameworks / key services>

## Commands
- **install**: `<cmd>`
- **test**: `<cmd>`            # used by VERIFY
- **run / dev**: `<cmd>`
- **build**: `<cmd>`
- **lint / typecheck**: `<cmd>`

## Layout
- **entrypoint**: <path>
- **source roots**: <dirs>
- **config / env**: <.env path; real secrets live in $ROOT/.secrets/ — never committed>
- **docs**: <paths>

## Hard Rules ("Schema Lock") — what Navi must never violate here
1. <e.g. DB access only through core/store.py>
2. <e.g. no new top-level deps without approval>
3. <architectural invariant>

## Danger Zones (confirm before touching)
- <files/commands that are destructive, costly, or outward-facing — e.g. deploy, migrations, paid APIs, sends>

## Notes
- <anything non-obvious a fresh agent must know>
