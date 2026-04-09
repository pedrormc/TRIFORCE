# Foundation Design — TRIFORCE Unified Memory + Stack

**Status:** Draft (awaiting review)
**Author:** Claude Master (Desktop) + Pedro Roberto (pedrormc)
**Date:** 2026-04-09
**Scope:** Sub-project A (Stack Install + Deduplication) + Sub-project B (Unified Memory Brain) of the TRIFORCE Unification initiative
**Related:**
- Repo: [pedrormc/TRIFORCE](https://github.com/pedrormc/TRIFORCE)
- Repo: [pedrormc/claude-code-toolkit](https://github.com/pedrormc/claude-code-toolkit)
- Repo: [pedrormc/obsidiano](https://github.com/pedrormc/obsidiano) (vault)
- Repo: [pedrormc/zel](https://github.com/pedrormc/zel) (WhatsApp channel)

---

## 0. Executive Summary

Foundation unifies the three Claude Code environments (Desktop / Mobile / VPS) under a single memory brain stored in the Obsidian vault, while installing and deduplicating the extended stack (Gstack + RuFlo + existing plugins). It refactors `obsidiano/CLAUDE.md` to separate the Zel WhatsApp persona from generic standing orders, creates a 6-file unified memory structure at `obsidiano/Claude/memory/`, and wires session lifecycle hooks that automatically load memory on session start and promote cross-project patterns to global memory on session end — all with safety nets, auditable logs, and easy rollback.

Foundation is scoped to deliver a working unified memory system in 2-3 implementation sessions. It explicitly excludes: cross-env auto-sync (sub-project C), autonomous scheduled tasks (D), multimodal memory (E), visual mascot (F), and active RuFlo workers (Phase 2).

---

## 1. Context and Problem Statement

### 1.1 Current state

Pedro (Robertin, CTO @ Singular Group, GitHub: pedrormc) operates the TRIFORCE methodology: three Claude Code environments with distinct identities and permissions:

- **Desktop (Claude Master)** — Windows 11, full permissions, primary development
- **Mobile (Claude Mobile)** — Termux on Poco F5, restricted, lightly used
- **VPS (Claude VPS / Zel)** — Ubuntu on DigitalOcean, maximum permissions, runs Zel (WhatsApp assistant via Evolution API)

The setup is documented in:
- `github.com/pedrormc/TRIFORCE` — methodology, templates, scripts
- `github.com/pedrormc/claude-code-toolkit` — shared agents, skills, rules, hooks, statusline
- `github.com/pedrormc/obsidiano` — Obsidian vault (shared via git)
- `github.com/pedrormc/zel` — WhatsApp channel integration

Plugins installed: Everything Claude Code (ECC) v1.8.0, Superpowers v5.0.2, Ralph v1.0.0, UI/UX Pro Max v2.2.1. MCPs: `@bitbonsai/mcpvault` (Obsidian), `n8n-mcp`, `@testsprite/testsprite-mcp`, plus cloud connectors (Gmail, Calendar, Drive, HubSpot x2, Excalidraw).

### 1.2 Problems this Foundation solves

1. **Memory fragmentation.** Three disconnected memory systems: auto-memory per cwd (`~/.claude/projects/*/memory/`), Obsidian vault (manual), and session files (`~/.claude/sessions/`). None sync, none compose.

2. **Zel CLAUDE.md conflict.** `obsidiano/CLAUDE.md` is 100% Zel system prompt (WhatsApp reply tool, restrictions on outbound messaging). When Desktop/Mobile Claude Code reads the vault via MCPVault, it inherits Zel's WhatsApp restrictions incorrectly.

3. **Cross-env context loss.** A decision made on Desktop is invisible to VPS until manually documented. Sessions don't carry state across environments.

4. **Plugin overlap unresolved.** ECC, Superpowers, and the planned Gstack install will have 30+ overlapping commands (`planner` / `writing-plans` / `/autoplan`; `code-reviewer` in both ECC and Superpowers; Gstack's `/review` and `/ship` overlap with existing flows). Without a documented strategy, users (and Claude) don't know which to use.

5. **No persistent standing orders.** Each session starts blank. User preferences, project context, and active state must be re-explained. The imagery shared in the brainstorm illustrated this pattern clearly ("Claude has no memory by default").

### 1.3 Goals

**G1.** Unified memory readable across all three environments via a single source of truth in the vault.
**G2.** Zel WhatsApp functionality preserved exactly as-is (zero regression).
**G3.** Stack expanded (Gstack + RuFlo) with documented deduplication strategy and zero breakage of existing flows.
**G4.** Session lifecycle automated: memory loaded on start, sessions persisted on end, cross-project patterns promoted to global memory automatically with safety nets.
**G5.** All changes reversible via git tags and documented rollback procedures.
**G6.** Everything versioned in TRIFORCE (spec) and claude-code-toolkit (scripts/configs).

### 1.4 Non-goals (explicitly deferred)

- **NG1.** Cross-env auto-sync (git pull/push automation) — sub-project C.
- **NG2.** Scheduled autonomous tasks (morning briefing, research-scout, decision-logger) — sub-project D.
- **NG3.** Multimodal memory (video/audio/image semantic search) — sub-project E.
- **NG4.** Visual mascot / pixel art persona — sub-project F.
- **NG5.** Active RuFlo workers (swarm orchestration) — Phase 2 after Foundation validated.
- **NG6.** Context7 MCP — removed from scope. User's stack (Opus 4.6 + WebFetch + research-agent + domain MCPs) already covers library doc needs; added friction not worth marginal value.
- **NG7.** Mobile environment configuration — documented as an appendix but not executed as part of Foundation.
- **NG8.** Performance optimization of memory loader (~4k tokens per session is acceptable for 1M context).

---

## 2. Architecture

### 2.1 The three context layers

```
┌───────────────────────────────────────────────────────────────┐
│ LAYER 1: Environment-Local (per physical machine)             │
│ ~/.claude/CLAUDE.md                                           │
│ • Environment identity (Claude Master / Mobile / VPS)         │
│ • Permission level (acceptEdits / default / bypass)           │
│ • Origin tag for traceability                                 │
│ → Different on each machine. Does not sync.                   │
└───────────────────────────────────────────────────────────────┘
                            ↓ composes with
┌───────────────────────────────────────────────────────────────┐
│ LAYER 2: Vault Brain (shared across envs via git)             │
│ obsidiano/Claude/CLAUDE.md + Claude/memory/*.md               │
│ • Generic standing orders (TRIFORCE methodology, PT-BR)       │
│ • Six unified memory files (user, preferences, active, ...)   │
│ • INDEX.md as master map of all three memory systems          │
│ → Identical across envs. Synced via pedrormc/obsidiano repo.  │
└───────────────────────────────────────────────────────────────┘
                            ↓ composes with
┌───────────────────────────────────────────────────────────────┐
│ LAYER 3: Project-Local (per working directory)                │
│ <repo>/.claude/CLAUDE.md (optional, only if present)          │
│ • Project-specific rules (stack, patterns, constraints)       │
│ → Versioned with the project repo.                            │
└───────────────────────────────────────────────────────────────┘
```

### 2.2 Session load flow

```
1. Claude Code starts in any environment
2. Reads LAYER 1 (~/.claude/CLAUDE.md) → knows its identity
3. SessionStart hook fires →
   reads LAYER 2 via MCPVault:
     a. obsidiano/Claude/CLAUDE.md (standing orders)
     b. obsidiano/Claude/memory/INDEX.md (master index)
     c. obsidiano/Claude/memory/*.md (all 6 seed files, always)
     d. ~/.claude/projects/<cwd-hash>/memory/*.md (auto-memory for current cwd)
4. If cwd has LAYER 3 (.claude/CLAUDE.md) → overrides where conflict
5. Session proceeds with full unified context injected
6. During session: writes to Claude/memory/ via MCPVault, validated by PostToolUse hook
7. On /save-session or Stop: session-end hook writes to Claude/sessions/, updates active.md, regenerates INDEX.md, triggers auto-promote (cron-based, not inline), auto-commits to vault
```

### 2.3 The three memory systems (unified, not collapsed)

Three coexisting memory layers, each with a distinct purpose. Unification happens via schema, index, and promotion — not by merging.

| System | Location | Scope | Source | Purpose |
|---|---|---|---|---|
| **Auto-memory** | `~/.claude/projects/<cwd>/memory/` | per-cwd | auto-memory | What was learned in THIS project |
| **Claude memory** | `obsidiano/Claude/memory/*.md` | global | claude-memory | What is true across ALL projects (distilled) |
| **Vault humano** | `obsidiano/[folders]/` | vault | vault | Everything Pedro uses as a human (notes, clients, meetings) |

Unification mechanisms:
- Shared frontmatter schema across all three
- `Claude/memory/INDEX.md` master map referencing all three
- Promotion skill (`memory-auto-promote`) moves cross-project patterns from auto-memory → Claude memory automatically with safety nets
- Wiki links cross-system: `[[vault/note]]`, `@~/.claude/projects/<id>/memory/<file>`, `@github:pedrormc/<repo>`

---

## 3. Vault Refactor (Split of `obsidiano/CLAUDE.md`)

### 3.1 Current state (the problem)

`obsidiano/CLAUDE.md` today is 75 lines, 100% Zel system prompt. Mixes:
- Zel identity and WhatsApp reply tool (Zel-specific)
- Security rules (generic, reusable)
- Vault capabilities (generic)
- Project categories (generic)
- Paridade with Claude VPS (Zel-specific)
- WhatsApp response rules (Zel-specific)

When Desktop Claude Code reads this via MCPVault, it inherits Zel's WhatsApp restrictions, which is wrong.

### 3.2 Target state

Three files, each with a single responsibility:

**File 1: `obsidiano/CLAUDE.md`** (new loader, ~20 lines)

A thin loader that explains to any Claude Code session which files to actually read depending on whether it's running as Zel or not. Acts as documentation for humans and a pointer for agents.

**File 2: `obsidiano/Claude/CLAUDE.md`** (new, ~60 lines)

Generic standing orders that apply to any Claude Code instance reading the vault:
- Security rules (secrets, tokens, .env handling)
- Vault capabilities and structure
- Project categorization
- PT-BR informal style
- Writing-origin tagging convention
- References to `Claude/memory/*` files

**File 3: `obsidiano/Claude/personas/zel.md`** (new, ~40 lines)

Extracted Zel-specific content:
- "Voce e o Zel" identity
- Paridade with Claude VPS
- WhatsApp reply tool rules
- Permission flow via WhatsApp approval codes
- Reference to `../CLAUDE.md` for base rules

### 3.3 Migration steps

```bash
# 1. Defensive backup
cd ~/Documents/obsidiano
git checkout -b feat/foundation-claude-split
cp CLAUDE.md CLAUDE.md.backup

# 2. Create structure
mkdir -p Claude/personas Claude/memory Claude/sessions

# 3. Extract Zel persona (lines 1-5, 41-59 of old CLAUDE.md)
# Write Claude/personas/zel.md

# 4. Write Claude/CLAUDE.md (new generic standing orders)

# 5. Overwrite vault/CLAUDE.md with loader

# 6. Commit atomically
git add CLAUDE.md Claude/
git commit -m "refactor: split vault CLAUDE.md into loader + generic + Zel persona"

# 7. Read-back validation via MCPVault
```

### 3.4 Zel system prompt update

Zel currently loads `obsidiano/CLAUDE.md` directly. After the split, `whatsapp-channel.ts` must load BOTH `Claude/CLAUDE.md` (generic) and `Claude/personas/zel.md` (persona). This requires a code change in `pedrormc/zel`:

```typescript
// Before
const systemPrompt = readFileSync('/home/claude/obsidiano/CLAUDE.md', 'utf-8');

// After
const generic = readFileSync('/home/claude/obsidiano/Claude/CLAUDE.md', 'utf-8');
const persona = readFileSync('/home/claude/obsidiano/Claude/personas/zel.md', 'utf-8');
const systemPrompt = `${generic}\n\n---\n\n${persona}`;
```

#### Deploy strategy

This is production code. The change ships on a feature branch with immediate post-deploy verification before E2E:

1. **Branch:** `feat/foundation-dual-prompt-load` off `main` in `pedrormc/zel`
2. **Commit:** single commit touching only `whatsapp-channel.ts` (and any import test if exists)
3. **Pre-deploy check (runs on VPS before restart):**
   ```bash
   cd ~/zel && git fetch && git checkout feat/foundation-dual-prompt-load
   bun --version                                    # sanity
   bun x tsc --noEmit whatsapp-channel.ts           # type-check only
   ```
4. **Restart sequence:**
   ```bash
   pm2 stop zel-channel 2>/dev/null || tmux kill-session -t zel 2>/dev/null
   cd ~/zel && bun run channel &                    # starts fresh
   sleep 3                                          # give it time to boot
   ```
5. **Log-grep smoke check (immediate, BEFORE E2):**
   ```bash
   tail -50 ~/zel/logs/channel.log 2>/dev/null | grep -E "(loaded.*CLAUDE|persona.*zel|system prompt)" && echo "✅ prompt loaded" || echo "❌ no prompt load log"
   tail -50 ~/zel/logs/channel.log 2>/dev/null | grep -iE "(error|exception|ENOENT|cannot find)" && echo "❌ errors present" || echo "✅ no errors"
   ```
6. **Only after both smoke checks are green:** proceed to E2E test E2 (WhatsApp round-trip).
7. **If any smoke check fails:** immediate rollback via `git checkout main && cd ~/zel && bun run channel` (reverts to working single-file loader).

#### Merge policy

The branch `feat/foundation-dual-prompt-load` is NOT merged to main until both the log-grep smoke check AND E2E test E2 pass. After merge, tag as `v2.1.0-foundation`.

This change is mandatory for the split to work without regressing Zel. E2E test E2 (§ 8.4) validates the end-to-end WhatsApp round-trip.

### 3.5 Rollback

Three-command rollback restores the original state. The refactor runs on a feature branch, so aborting is a branch delete:

```bash
cd ~/Documents/obsidiano
git checkout main                                         # returns to untouched main
git branch -D feat/foundation-claude-split                # discards the feature branch
```

The `CLAUDE.md.backup` file created in step 1 of §3.3 is a belt-and-suspenders safety net for non-git edits and can be discarded after the rollback. Do NOT run `git checkout -- CLAUDE.md` — main is already clean, and that command would have overwritten a restored backup anyway.

---

## 4. Memory Brain Structure

### 4.1 Six seed files at `obsidiano/Claude/memory/`

All files use a shared YAML frontmatter schema:

```yaml
---
name: <short name>
description: <one-line, used for relevance detection>
type: active | decisions | people | preferences | projects | user | reference
scope: per-cwd | global | vault
source: auto-memory | claude-memory | vault
last_updated: YYYY-MM-DD
---
```

**4.1.1 `active.md`** — Live state of current week
- Active projects with links
- This week's priorities
- Blockers
- Last 3 session summaries (auto-updated by session-end hook)
- Target size: <100 lines
- Written by: Claude (per session) + user (manual)

**4.1.2 `decisions.md`** — Append-only decision log
- Format: `## YYYY-MM-DD — Decision title`
- Each entry has: Motivo, Outcome esperado, Review em
- Never deleted, only appended
- Written by: Claude when detecting a decision + user (manual)

**4.1.3 `people.md`** — Context about people
- Extends `Clientes/` folder with living context (preferences, last contact, communication patterns)
- Uses wiki links `[[Clientes/Name]]` to reference full notes
- Does not duplicate vault content
- Written by: Claude when learning a fact + user (manual)

**4.1.4 `preferences.md`** — User work preferences
- Communication style (PT-BR informal)
- Code style (immutability, <800 line files, error handling, Zod)
- Tool preferences
- Origin tagging convention
- Destination for auto-promoted patterns from auto-memory
- Written by: mostly user + auto-promote script

**4.1.5 `projects.md`** — Global projects index
- All projects with category, status, stack, vault link
- Consolidates / replaces `Claudete.md` index
- Written by: Claude on new project + user (manual)

**4.1.6 `user.md`** — User profile
- Identity (Pedro Roberto / Robertin / pedrormc)
- Role, stack expertise, background
- Three environments reference
- Active repos
- Written rarely, mostly by user

#### 4.1.7 Write semantics matrix (quick reference)

| File | Writer | Trigger | Mode |
|---|---|---|---|
| `active.md` | Claude | session-end hook (last 3 sessions) + user (manual) | edit-in-place |
| `decisions.md` | Claude | decision-detector heuristic during session + user (manual) | append-only |
| `people.md` | Claude | when new fact learned about a person + user (manual) | append-only |
| `preferences.md` | user (primary) + auto-promote cron | manual edits + cron promotions | edit + append |
| `projects.md` | Claude | on new project detected + user (manual) | append + edit-in-place |
| `user.md` | user (only) | manual edits | edit-in-place |
| `INDEX.md` | script | session-end hook + daily cron | replace (auto-generated) |
| `.promotion-log.jsonl` | auto-promote + memory-revert | cron + user commands | append-only |

### 4.2 Load strategy

All six files are loaded on every session start (user decision during brainstorming: full load preferred over partial, token cost ~2000 acceptable for 1M context). Token budget breakdown:

| Source | Estimated tokens |
|---|---|
| `Claude/CLAUDE.md` (standing orders) | ~600 |
| `Claude/memory/INDEX.md` | ~400 |
| 6 `Claude/memory/*.md` files | ~2000 |
| Auto-memory for current cwd | ~500-1500 |
| **Total per session** | **~3500-4500** |

### 4.3 Write strategy

All writes go through either:
- MCPVault (for `Claude/memory/*.md`) — prevents YAML frontmatter corruption
- `~/.claude/scripts/memory-update.sh` (unified wrapper) — validates schema, updates `last_updated`, commits

Direct `Edit` tool writes to memory files are allowed but **warned**, not blocked. The PostToolUse validator hook (§ 7.3) validates YAML frontmatter and emits a warning to stderr if malformed. It does NOT fail the edit — a typo must not brick an in-progress session. Enforcement boundary is `memory-update.sh`, which is the canonical write path.

Rationale: blocking an `Edit` on memory files would make quick fixes impossible from inside a session and create a frustrating UX. Warning allows user to fix on the next save cycle, and the auto-commit hook ensures the warning is visible in the commit message if the YAML is malformed.

### 4.4 Size limits and compaction

| File | Soft limit | Compaction trigger |
|---|---|---|
| `active.md` | 100 lines | Move old entries to `decisions.md` or drop |
| `decisions.md` | unbounded | Paginate quarterly at 1000 lines |
| `people.md` | 200 lines | Split into `people/<name>.md` folder |
| `preferences.md` | 80 lines | Auto-prune low-confidence auto-promoted entries |
| `projects.md` | varies | Split by status (`projects-active.md` / `projects-archive.md`) |
| `user.md` | 50 lines | Never auto-compact (user-owned) |

Compaction is manual in Foundation. Scheduled compaction is sub-project D.

### 4.5 Initial population (migration from existing memories)

Seeds are NOT empty templates. During implementation, Claude will:

1. Read `~/.claude/projects/C--Users-teste/memory/*.md` (existing auto-memory for the root cwd)
2. Read `obsidiano/Claudete.md` (existing index)
3. Read `obsidiano/CLAUDE.md` (rules to extract into preferences.md)
4. Extract user profile from existing sources
5. Write all six seed files with real data
6. Present to user for review before committing

User decision during brainstorming: populate with real extracted data, not empty templates.

---

## 5. Memory Unification

### 5.1 Strategy: schema + index + promotion (not collapse)

Three memory systems coexist. Unification is achieved by:

1. **Shared schema** — all three systems use the same frontmatter format
2. **Master INDEX** — single file at `Claude/memory/INDEX.md` that maps all three
3. **Automatic promotion** — patterns repeated across projects are promoted from auto-memory to Claude memory with safety nets
4. **Wiki links** — three link syntaxes allow cross-system references
5. **Unified update API** — `memory-update.sh` script as single write entry point

The systems are NOT collapsed into one. Each keeps its distinct write semantics and scope.

### 5.2 Unified schema (expanded frontmatter)

Adds `scope` and `source` fields to existing auto-memory format:

```yaml
---
name: <short name>
description: <one-line>
type: user | feedback | project | reference | active | decisions | people | preferences | projects
scope: per-cwd | global | vault
source: auto-memory | claude-memory | vault
last_updated: YYYY-MM-DD
---
```

Existing auto-memory files get `scope: per-cwd, source: auto-memory` added in a migration pass. Existing vault folders (`singular/`, `Clientes/`, etc.) are not modified — they are referenced from INDEX.md without edits.

### 5.3 `Claude/memory/INDEX.md` (master map)

Auto-generated file listing:
- All files in `Claude/memory/` with type and last_updated
- All auto-memory directories across `~/.claude/projects/*/memory/`
- All top-level vault folders with brief description
- Known cross-references

Regenerated by `~/.claude/scripts/memory-index-rebuild.sh` on session end and on a daily cron. Marked `auto_generated: true` to prevent manual edits.

### 5.4 Wiki links cross-system

Three syntaxes serve different resolution mechanisms:

| Syntax | Target | Example | Foundation resolution |
|---|---|---|---|
| `[[Folder/Note]]` | Vault Obsidian (humano) | `[[Clientes/Eduardo Dib]]` | **Active** — MCPVault resolves and fetches on read |
| `@~/.claude/projects/<id>/memory/<file>` | Auto-memory entry | `@~/.claude/projects/C--Users-teste-Desktop-n8n-Mili/memory/project_hubspot_singular_kanban.md` | **Active** — Claude follows via Read tool when context demands |
| `@github:pedrormc/<repo>` | GitHub repo | `@github:pedrormc/Mel` | **Visual only in Foundation** — Claude recognizes the marker and can follow via `gh` CLI manually, but no automatic resolver is implemented. Treat as a label meaning "the canonical project lives there". |

MCPVault natively handles `[[wiki links]]`. Auto-memory `@path` references are literal paths Claude can open. The `@github:` marker is a naming convention — if automated resolution becomes a need, Phase 2 may add a resolver script, but Foundation does not ship one.

### 5.5 `memory-update.sh` unified API

Single CLI wrapper for memory writes across all three systems:

```bash
memory-update auto <type> <content>              # writes to auto-memory (per-cwd)
memory-update claude <file> <content>            # writes to Claude/memory/ (vault)
memory-update vault <relative-path> <content>    # writes to vault humano
```

The script:
1. Validates YAML frontmatter
2. Auto-updates `last_updated: <today>`
3. Uses MCPVault for vault writes (prevents corruption)
4. Uses plain `Edit` for auto-memory writes
5. Auto-commits if the write is to the vault

---

## 6. Stack Installation

### 6.1 Final component matrix

| Component | Desktop | VPS | Mobile (appendix) |
|---|---|---|---|
| Gstack (clone + setup) | ✅ | ✅ | documented, not executed |
| MCPVault | ✅ already installed | ✅ install | documented |
| Vault clone (`pedrormc/obsidiano`) | ✅ already cloned | ✅ clone | documented |
| Ralph disabled (`disabledPlugins`) | ✅ | ✅ | documented |
| RuFlo install (workers OFF) | ❌ | ✅ | ❌ |
| `namespace-cheatsheet.md` rule | ✅ | ✅ | documented |
| Memory hooks (`session-start`, `session-end`, etc.) | ✅ | ✅ | documented |
| Auto-promote cron | ✅ (Task Scheduler) | ✅ (cron) | ❌ |

Context7 is explicitly out of scope — see § 1.4 NG6. Not listed in the matrix because it is not installed anywhere.

### 6.2 Gstack installation

```bash
git clone --single-branch --depth 1 \
  https://github.com/garrytan/gstack.git \
  ~/.claude/skills/gstack
cd ~/.claude/skills/gstack && ./setup
```

Installed in single-machine mode (not team mode) for Foundation. Installs 33 slash commands: `/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/plan-design-review`, `/design-consultation`, `/design-shotgun`, `/design-html`, `/review`, `/ship`, `/land-and-deploy`, `/canary`, `/benchmark`, `/browse`, `/connect-chrome`, `/qa`, `/qa-only`, `/design-review`, `/setup-browser-cookies`, `/setup-deploy`, `/retro`, `/investigate`, `/document-release`, `/codex`, `/cso`, `/autoplan`, `/plan-devex-review`, `/devex-review`, `/careful`, `/freeze`, `/guard`, `/unfreeze`, `/gstack-upgrade`, `/learn`.

### 6.3 RuFlo installation (VPS only, workers disabled)

**Canonical install command (locked for Foundation):**

```bash
# VPS only
npx ruflo@latest init --install-only --no-start
```

The `--install-only --no-start` flags ensure binaries and MCP server config are placed on disk without launching any worker processes. This is the "workers OFF" state for Phase 1.

**Binary verification:**

```bash
which ruflo || npx ruflo --version    # should print v3.5.x
ls ~/.ruflo/ 2>/dev/null               # expected: config, agents/, policy/, memory/
```

**Add to VPS `~/.claude/settings.json`:**

```json
{
  "disabledPlugins": ["ralph-skills@1.0.0", "ruflo-workers"]
}
```

**Workers OFF verification:**

```bash
pgrep -f "ruflo.*worker" && echo "❌ workers running" || echo "✅ workers off"
```

RuFlo is installed but workers are disabled in Foundation. Phase 2 enables workers for the autonomous tasks sub-project (D) by removing `ruflo-workers` from the disabled list and running `npx ruflo start --workers=N`.

### 6.4 Ralph deprecation

Ralph is marked deprecated in `claude-code-toolkit/README.md`. It is NOT deleted from disk. Added to `disabledPlugins` in all three envs. Easy to re-enable by removing from the array.

### 6.5 MCPVault replication to VPS

**Prerequisites (verify BEFORE editing config):**

```bash
# 1. Node.js 20+ and npx available
node --version    # must be >= v20.0.0
npx --version     # must print a version

# 2. Vault cloned
test -d /home/claude/obsidiano || \
  (cd /home/claude && git clone https://github.com/pedrormc/obsidiano.git)

# 3. mcpvault package reachable from npm registry
npx -y @bitbonsai/mcpvault@latest --help >/dev/null 2>&1 && echo "✅ reachable" || echo "❌ check network or proxy"
```

If Node is missing, install via `curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -` and `sudo apt-get install -y nodejs` BEFORE proceeding. Foundation does not install Node itself — it assumes a working Node environment on the VPS (the VPS runs Zel/Bun, so Node is expected but not guaranteed; this check makes the assumption explicit).

**Add to VPS `~/.claude.json`:**

```json
{
  "mcpServers": {
    "obsidian": {
      "command": "npx",
      "args": ["@bitbonsai/mcpvault@latest", "/home/claude/obsidiano"],
      "disabled": false
    }
  }
}
```

**Post-install verification:**

```bash
claude 2>&1 | head -20   # session should not error on MCPVault connection
```

### 6.6 `namespace-cheatsheet.md` rule

New file at `~/.claude/rules/common/namespace-cheatsheet.md`, versioned in `claude-code-toolkit/rules/common/`.

Documents:
- All installed plugins with status (active / disabled)
- When to use which command in case of overlap (ECC `/plan` vs Superpowers `writing-plans` vs Gstack `/autoplan`)
- Custom agents usage table
- Golden rule for resolving conflicts

Strategy: install everything, let user decide per-use case, disable only after 14+ days of unused observation.

### 6.7 claude-code-toolkit updates

The `claude-code-toolkit` repo receives:

- `rules/common/namespace-cheatsheet.md` — new
- `config/settings.json` — updated with `disabledPlugins`, memory hooks
- `hooks/session-start-memory-loader.sh` — new
- `hooks/session-end-memory-writer.sh` — new
- `hooks/save-session-vault-mirror.sh` — new
- `hooks/post-edit-memory-validator.sh` — new
- `scripts/memory-auto-promote.sh` — new
- `scripts/memory-index-rebuild.sh` — new
- `scripts/memory-revert.sh` — new
- `scripts/memory-update.sh` — new
- `scripts/foundation-smoke.sh` — new (validation)
- `scripts/foundation-validate.sh` — new (validation)
- `install.sh` — updated to install Gstack, apply hooks, configure scheduled tasks
- `templates/claude-md/zel.md` — new (Zel persona template)
- `README.md` — updated (Plugins section: +Gstack, ~Ralph deprecated)

### 6.8 Mobile appendix

Documented in `TRIFORCE/docs/setup-mobile.md`. Contains full install instructions for Pedro to execute when Mobile environment is next used. Not part of Foundation execution.

---

## 7. Session Lifecycle and Hooks

### 7.1 Hook map

| Event | Hook | Blocking | Purpose |
|---|---|---|---|
| `SessionStart` | `session-start-memory-loader.sh` | No | Load unified memory into session context |
| `PostToolUse` (Write to `~/.claude/sessions/`) | `save-session-vault-mirror.sh` | No | Mirror session files to vault |
| `Stop` (session end) | `session-end-memory-writer.sh` | No | Update active.md, regenerate INDEX, auto-commit |
| `PostToolUse` (Edit/Write to memory files) | `post-edit-memory-validator.sh` | Yes | Validate YAML, update last_updated |
| Cron (daily 03:00) | `memory-auto-promote.sh` | — | Promote cross-project patterns to global memory |
| Cron (daily 03:05) | `memory-index-rebuild.sh` | — | Rebuild INDEX.md |

All hooks are failure-tolerant: they use `set -uo pipefail` (not `-e`), and missing files produce commented markers in output instead of crashing the session.

### 7.2 SessionStart hook (`session-start-memory-loader.sh`)

Detects OS (Windows/Linux/Termux) to locate vault path. Computes cwd hash matching the harness auto-memory path. Outputs to stdout all memory files in structured sections:

1. Standing orders (`obsidiano/Claude/CLAUDE.md`)
2. Master index (`obsidiano/Claude/memory/INDEX.md`)
3. All 6 seed memory files (`active`, `decisions`, `people`, `preferences`, `projects`, `user`)
4. Current cwd auto-memory (`~/.claude/projects/<hash>/memory/*.md`)

Output is injected as initial context by Claude Code. Token cost: ~3500-4500.

#### Failure mode (CRITICAL)

A hook failure MUST NOT block session start. Foundation guarantees:

- Script uses `set -uo pipefail` (not `-e`) — missing files are tolerated
- Every file read goes through `safe_cat()` helper that emits `<!-- ARQUIVO AUSENTE: <path> -->` on missing files instead of failing
- **Hook always exits 0.** Any internal error is swallowed, logged to `~/.claude/hooks/session-start-memory-loader.log`, and replaced by a degraded context marker at the top of output:
  ```
  === ⚠️ MEMORY LOADER DEGRADED — partial context only ===
  Reason: <error summary>
  Full log: ~/.claude/hooks/session-start-memory-loader.log
  ```
- If the vault directory itself is unreachable (partial install, detached volume, MCPVault down), the hook emits ONLY the degraded marker and exits 0. The session starts with whatever Layer 1 (`~/.claude/CLAUDE.md`) provides. User can work without memory context until the issue is fixed — the session is never bricked.
- If `~/.claude/settings.json` is misconfigured and the hook binary is missing entirely, Claude Code skips the missing hook (standard harness behavior) and the session still starts.

This failure-tolerant design is non-negotiable: a single bad vault state must not prevent `claude` from launching in any environment.

Configuration in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          { "type": "command", "command": "~/.claude/hooks/session-start-memory-loader.sh" }
        ]
      }
    ]
  }
}
```

### 7.3 PostToolUse memory validator (`post-edit-memory-validator.sh`)

Fires on every Edit/Write. Filters for paths matching `obsidiano/Claude/memory/*.md` or `~/.claude/projects/*/memory/*.md`. For matches:

1. Validates YAML frontmatter exists (first 20 lines have two `---` markers)
2. Auto-updates `last_updated: <today>` via sed
3. If the file is in the vault, auto-commits silently

Blocking on failure (exit 1) to prevent malformed writes.

### 7.4 Session end hook (`session-end-memory-writer.sh`)

Fires on `Stop` event. Composes with existing `claude-notify.js` (not replaced). Actions:

1. Updates `Claude/memory/active.md` "Últimas 3 sessões" section (append + truncate to 3)
2. Triggers `memory-index-rebuild.sh` in background
3. Auto-commits `Claude/memory/active.md` and `INDEX.md` silently (no push — user decision)

### 7.5 Save-session vault mirror (`save-session-vault-mirror.sh`)

Triggers when `/save-session` writes a file to `~/.claude/sessions/`. Copies the latest session file to `obsidiano/Claude/sessions/<date>-<id>-session.md` for persistence in the vault.

### 7.6 Auto-promote (`memory-auto-promote.sh`) — 100% automatic with safety nets

**User decision:** promotion is 100% automatic (no per-entry confirmation). Required safety nets:

**Filter 1 — Repetition:** entry must appear in **3+ projects** (not 2). User decision: "Balanceado" preset.

**Filter 2 — Age:** entry must be **7+ days old** in auto-memory before eligible. Prevents promoting ideas that may be revised.

**Filter 3 — Confidence (similarity mechanism):** similarity score between two entries must be **>= 0.75**.

Computed as **token-set Jaccard** on normalized content:

1. Strip YAML frontmatter
2. Lowercase
3. Strip punctuation and stop-words (pt-BR stop list: `de|a|o|que|e|do|da|em|um|para|é|com|não|uma|os|no|se|na|por|mais|as|dos|como|mas|foi|ao|ele|das|à|seu|sua`)
4. Tokenize by whitespace
5. Build sets A and B
6. `similarity = |A ∩ B| / |A ∪ B|`

Threshold 0.75 means two entries share >= 75% of distinct meaningful tokens. This is cheap (no embedding model required), deterministic (reproducible), and adequate for short auto-memory entries (typically 20-200 tokens). If an entry is longer than 500 tokens, it is excluded from the similarity pool (cap to prevent pathological cases). Phase 2 may upgrade to embedding-based similarity if needed, but Foundation uses Jaccard only.

**Filter 4 — Allow-list of types:** promotes only `feedback` → `preferences`, `reference` → `projects` or `people`. **Never promotes `project` type** (cwd-specific by design).

**Filter 5 — Block-list of sensitive content:** regex-based rejection of entries containing financial values (`R$`, `$`, `USD`, `EUR`), secrets (`password`, `token`, `api_key`, `secret`, `.env`, `credential`), or PII (emails, phones, CPF/CNPJ).

**Filter 6 — Auto-promotion tag:** all promoted entries receive frontmatter marker:

```yaml
auto_promoted: true
promoted_from:
  - <source path 1>
  - <source path 2>
  - <source path 3>
promoted_at: <ISO timestamp>
confidence: <float>
entry_id: <unique id>
```

**Filter 7 — Audit log:** all promotions append a JSONL line to `obsidiano/Claude/memory/.promotion-log.jsonl`:

```json
{"timestamp":"2026-04-09T03:00:00","action":"promote","target":"preferences.md","entry_id":"prom-...","sources":[...],"confidence":0.87}
```

**Filter 8 — Originals preserved:** source auto-memory entries are NEVER deleted during promotion. Promotion is a copy + tag operation.

**Filter 9 — Max per run:** hard limit of 5 promotions per cron run to prevent vault flooding in edge cases.

**Empty-state handling (Day 1 and beyond):** when the candidate set is empty (no entries meet all filters — typical on Day 1 when auto-memory has only one cwd), the cron script:

1. Exits 0 (success, not failure)
2. Appends a single line to `.promotion-log.jsonl`:
   ```json
   {"timestamp":"<ISO>","action":"cron-run","promoted":0,"eligible":0,"reason":"empty_candidate_set"}
   ```
3. Produces no output (silent). Monitoring systems should treat the empty-state line as healthy heartbeat, not as failure.

**Filter 10 — Easy reversion:** `~/.claude/scripts/memory-revert.sh <entry-id>` reads the log, removes the entry from the target file, marks the log entry as `reverted: true` (does not delete log entry — audit trail preserved).

### 7.7 Balanced preset values

```yaml
# ~/.claude/config/auto-promote.yaml
filters:
  min_projects: 3
  min_age_days: 7
  similarity_threshold: 0.75
max_per_run: 5
target_mapping:
  feedback: preferences.md
  reference: projects.md  # or people.md if person-shaped
block_list_patterns:
  - 'R\$|USD|EUR|\$\d'
  - 'password|token|api_key|secret|\.env|credential'
  - '[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}'  # emails
  - '\+?55 ?\d{2} ?\d{4,5}-?\d{4}'  # BR phones
  - '\d{3}\.\d{3}\.\d{3}-\d{2}'  # CPF
```

### 7.8 Cron scheduling

- **Desktop (Windows):** `schtasks` creates two daily tasks at 03:00 and 03:05
- **VPS (Linux):** standard crontab entries
- **Mobile (Termux):** appendix only

### 7.9 Zel system prompt change

On VPS, `~/zel/whatsapp-channel.ts` is updated to load two files instead of one (see § 3.4). This is a code change committed to `pedrormc/zel` during VPS implementation session. Covered by E2E test E2.

---

## 8. Validation and Testing

### 8.1 Test pyramid

```
       ┌────────────────┐
       │ E2E (3 tests)  │      ← slowest, most realistic
       └────────────────┘
    ┌────────────────────────┐
    │ Integration (7 tests)  │
    └────────────────────────┘
┌────────────────────────────────┐
│   Smoke / Unit (13 tests)      │  ← fastest, per-component
└────────────────────────────────┘
```

All smoke tests automated in `~/.claude/scripts/foundation-smoke.sh`. Integration tests semi-automated in `~/.claude/scripts/foundation-validate.sh`. E2E tests are manual (require opening real sessions and sending real WhatsApp messages).

### 8.2 Smoke tests (run first, per-component)

> **Shell note:** all smoke tests run under **bash** (Git Bash on Windows, native bash on Linux, bash on Termux). They do NOT run under PowerShell or cmd.exe on Windows. The smoke runner script sets `#!/usr/bin/env bash`.

| # | Test | Command | Success criterion |
|---|---|---|---|
| S1 | Vault CLAUDE.md is loader | `head -5 ~/Documents/obsidiano/CLAUDE.md` | Contains "Vault Claude Instructions" and references `Claude/personas/` |
| S2 | Claude/CLAUDE.md exists | `test -f ~/Documents/obsidiano/Claude/CLAUDE.md` | Exit 0, non-empty |
| S3 | Zel persona extracted | `head -10 ~/Documents/obsidiano/Claude/personas/zel.md` | Starts with "Voce e o Zel" |
| S4 | 6 memory files populated | `ls ~/Documents/obsidiano/Claude/memory/*.md \| wc -l` | `>= 7` (6 seeds + INDEX) |
| S5 | active.md has real sections | `grep -c "^##" ~/Documents/obsidiano/Claude/memory/active.md` | `>= 3` |
| S6 | INDEX.md auto_generated | `grep "auto_generated: true" ~/Documents/obsidiano/Claude/memory/INDEX.md` | Match |
| S7 | Gstack installed | `ls ~/.claude/skills/ \| grep -c gstack` | `>= 1` |
| S8 | SessionStart hook exists | `test -x ~/.claude/hooks/session-start-memory-loader.sh` | Exit 0 |
| S9 | Session-end hook exists | `test -x ~/.claude/hooks/session-end-memory-writer.sh` | Exit 0 |
| S10 | Ralph disabled (strict) | `jq -e '.disabledPlugins \| any(. \| test("ralph"))' ~/.claude/settings.json` | Exit 0 (strict jq check inside disabledPlugins array, not substring anywhere) |
| S11 | Namespace rule exists | `test -f ~/.claude/rules/common/namespace-cheatsheet.md` | Exit 0 |
| S12 | MCPVault configured | `jq -e '.mcpServers.obsidian.command' ~/.claude.json` | Exit 0 |
| S13 | Auto-promote script exists | `test -x ~/.claude/scripts/memory-auto-promote.sh` | Exit 0 |

Tests S10 and S12 require `jq` to be installed. Foundation install adds `jq` to the toolchain prerequisites (check: `command -v jq || apt-get install jq` on VPS; already present in Git Bash on Windows).

### 8.3 Integration tests (run after smoke pass)

| # | Test | How | Criterion |
|---|---|---|---|
| I1 | Memory loader output complete | Run `bash ~/.claude/hooks/session-start-memory-loader.sh` | Has all 4 sections, no `<!-- ARQUIVO AUSENTE -->` |
| I2 | New Claude session reads memory | Open `claude`, ask "what do you know about me?" | Response cites CTO Singular, pedrormc, 3 envs, TRIFORCE |
| I3 | Memory write auto-commits | Edit `Claude/memory/active.md` via Edit tool | `git log -1` shows auto-commit within seconds |
| I4 | Auto-promote with synthetic data | See §8.3.1 below for full reproducible script | Promotion written to preferences.md with frontmatter tag, log line appended |
| I5 | Reversion works | Run `memory-revert.sh <entry-id>` on I4's promotion | Entry removed from preferences.md, log marked `reverted: true` |
| I6 | INDEX regen reflects changes | Add a new file to `Claude/memory/`, run `memory-index-rebuild.sh` | INDEX.md lists the new file |
| I7 | Gstack slash commands appear | Open `claude`, type `/` | List includes `/office-hours`, `/autoplan`, `/review`, `/ship`, `/qa`, `/cso` |

#### 8.3.1 I4 reproducible fake-data script

```bash
#!/usr/bin/env bash
# Creates 3 synthetic auto-memory entries in distinct fake project cwds, with mtimes
# older than 7 days, to exercise the auto-promote pipeline end-to-end.

set -euo pipefail

PROJECTS="$HOME/.claude/projects"
FAKE_CONTENT="PT-BR informal, direto, sem emojis a menos que explicitamente solicitado"
TARGETS=(
  "$PROJECTS/fake-proj-alpha/memory"
  "$PROJECTS/fake-proj-beta/memory"
  "$PROJECTS/fake-proj-gamma/memory"
)

for dir in "${TARGETS[@]}"; do
  mkdir -p "$dir"
  cat > "$dir/feedback_lang.md" <<'EOF'
---
name: Communication style
description: PT-BR informal, sem emojis, direto
type: feedback
scope: per-cwd
source: auto-memory
last_updated: 2026-03-20
---

PT-BR informal, direto, sem emojis a menos que explicitamente solicitado.
EOF
  # Backdate mtime to 14 days ago (well past the 7-day threshold)
  touch -d "14 days ago" "$dir/feedback_lang.md"
done

echo "✅ 3 synthetic entries created in fake project dirs with mtime 14 days ago"
echo "Now run: bash ~/.claude/scripts/memory-auto-promote.sh"
echo "Verify:"
echo "  grep -A5 'auto_promoted: true' ~/Documents/obsidiano/Claude/memory/preferences.md"
echo "  tail -3 ~/Documents/obsidiano/Claude/memory/.promotion-log.jsonl"
echo ""
echo "Cleanup after test:"
echo "  rm -rf $PROJECTS/fake-proj-{alpha,beta,gamma}"
```

The script uses GNU `touch -d` to backdate. On macOS/BSD systems, use `touch -t` with the equivalent format. Windows Git Bash ships with GNU touch and supports `-d`.

### 8.4 E2E tests (run last, manual)

**E1 — Full Desktop cycle:**

```
1. cd ~/Desktop/<any-folder>
2. claude
3. Ask: "o que você sabe sobre mim e meus projetos atuais?"
4. Verify response cites active.md + user.md + projects.md content
5. Edit any file
6. Run /save-session
7. Exit session
8. Verify:
   - ~/.claude/sessions/ has new session file
   - ~/Documents/obsidiano/Claude/sessions/ has mirror
   - Claude/memory/active.md has new session entry
   - git log in vault shows auto-commit
```

Success: all checks in step 8 pass.

**E2 — Zel regression (CRITICAL):**

Pre: Zel session running on VPS.

```
1. Send Zel a WhatsApp message: "oi, quais projetos ativos?"
2. Zel responds via reply tool
3. Verify:
   - Response arrives in WhatsApp (not terminal only)
   - Response cites real projects (Mel, Mili, etc)
   - Response time < 30 seconds
   - whatsapp-channel.ts logs on VPS show no errors
   - Zel did not attempt to send messages to other numbers
```

Success: all 5 checks pass. If ANY fails: immediate rollback of VPS vault refactor (not Desktop).

**E3 — Cross-env parity:**

```
1. Desktop: edit Claude/memory/decisions.md, add new decision
2. Desktop: confirm auto-commit ran
3. Desktop: git push vault
4. VPS: cd ~/obsidiano && git pull
5. VPS: open claude
6. VPS: ask "quais são as últimas decisões?"
7. Verify VPS Claude cites the decision from step 1
```

Success: step 7 contains the new decision. Total time < 2 minutes.

### 8.5 Foundation completion criteria

Foundation is complete when ALL of the following are true:

| Category | Criterion | Measured by |
|---|---|---|
| Structure | Vault has `Claude/` with 6 populated seeds + INDEX | S2-S6 pass |
| Refactor | `vault/CLAUDE.md` is loader, Zel persona separated | S1, S3 pass |
| Stack | Gstack installed on Desktop + VPS | S7 on both |
| Hooks | 3 hooks active on Desktop + VPS | S8, S9, S13 + settings.json |
| Dedup | Ralph disabled, namespace rule documented | S10, S11 |
| Memory load | Claude reads memory automatically in new session | I1, I2 |
| Auto-promote | Promotion + reversion work end-to-end | I4, I5 |
| Zel intact | WhatsApp continues responding with no degradation | E2 |
| Cross-env | Desktop changes appear on VPS via git | E3 |
| Performance | Session start < 3 seconds with memory loader | Manual timing |

### 8.6 Rollback plan

**Defensive tag before implementation starts:**

```bash
# In all three repos (obsidiano, claude-code-toolkit, TRIFORCE):
git tag pre-foundation-2026-04-09
git push origin pre-foundation-2026-04-09
```

**Per-component rollback:**

| Failed component | Rollback |
|---|---|
| Memory loader slow | Comment out SessionStart hook in settings.json |
| Auto-promote wrong | Run `memory-revert <id>` or edit `preferences.md` + commit |
| Vault split breaks Zel | `git revert` the split commit, restart Zel session via `bun run channel` |
| Gstack conflicts with Superpowers | Add `gstack` to `disabledPlugins` in settings.json |
| Auto-commit polluting | Remove `git commit` from session-end hook |
| MCPVault MCP crashes on VPS | Set `"disabled": true` on obsidian entry in `~/.claude.json`, session falls back to Layer 1 only |
| Cron/Task Scheduler misfires | Delete the Task Scheduler entry (`schtasks /delete /tn "Claude Memory Auto-Promote"`) or comment out crontab line |
| Gstack `./setup` partially succeeds | `rm -rf ~/.claude/skills/gstack*` and re-clone fresh |
| RuFlo install corrupts Node global | `npm uninstall -g claude-flow` + `rm -rf ~/.ruflo/` |
| **Any failure not listed above** | Universal: `git checkout pre-foundation-2026-04-09` in all three repos, `~/.claude/scripts/foundation-uninstall.sh` to remove hooks and cron, restart claude |

The universal rollback script `foundation-uninstall.sh` is part of Foundation deliverables. It removes all hook entries from `settings.json`, deletes scheduled tasks, unlinks symlinks, and leaves the backup files in place. It does NOT delete the `Claude/` vault folder (user may want to salvage memory content).

### 8.7 Test execution order (during implementation)

```
Implement component → Run smoke tests for that component →
  PASS: proceed. FAIL: debug + fix + re-run.

All components done → Run integration tests (I1-I7) →
  PASS: proceed to E2E. FAIL: identify component + rollback just that.

Integration passes → Run E2E (E1-E3) →
  PASS: Foundation complete. FAIL: rollback the problematic component.
```

Never skip stages. Smoke before integration, integration before E2E.

---

## 9. Open Questions

**None at spec-writing time.** All brainstorming decisions are documented inline in sections above. If ambiguities arise during implementation, they are surfaced in the implementation plan (writing-plans phase) and resolved before coding.

---

## 10. Out of Scope (Explicit Non-Goals Recap)

Repeated here for clarity. These are future sub-projects, not Foundation:

- **Sub-project C** — Cross-env automatic sync protocol
- **Sub-project D** — Autonomous scheduled tasks (morning briefing, research-scout, decision-logger, review cron)
- **Sub-project E** — Multimodal memory (ChromaDB / Gemini Embeddings 2 or RuVector)
- **Sub-project F** — Visual mascot / pixel art persona
- **Phase 2** — RuFlo workers activation, swarm orchestration
- **Context7** — removed from scope entirely, see NG6
- **Mobile execution** — documented as appendix, not part of Foundation implementation
- **Memory loader performance optimization** — acceptable at current ~4k tokens
- **Plugin overlap pruning** — disable decisions deferred 14+ days into usage

---

## 11. Appendices

### 11.1 Mobile installation instructions (deferred)

Full instructions below. Foundation also updates `TRIFORCE/docs/setup-mobile.md` with this content. This appendix is self-contained — executing it does not require re-reading this spec.

**Prerequisites (Termux on Poco F5):**

```bash
# Termux has a quirk with /tmp. Fix first (required by Pedro's env):
termux-setup-storage
pkg update && pkg install nodejs bun git jq curl coreutils proot

# The proot /tmp fix (from Pedro's memory):
mkdir -p ~/tmp && echo 'export TMPDIR=$HOME/tmp' >> ~/.bashrc
source ~/.bashrc
```

**Install steps:**

```bash
# 1. Pull toolkit and run install.sh
cd ~/claude-code-toolkit && git pull || git clone https://github.com/pedrormc/claude-code-toolkit.git ~/claude-code-toolkit
bash ~/claude-code-toolkit/install.sh --force

# 2. Clone vault
cd ~ && git clone https://github.com/pedrormc/obsidiano.git || (cd ~/obsidiano && git pull)

# 3. Add MCPVault to ~/.claude.json (Termux path)
# Edit ~/.claude.json and add under mcpServers:
#   "obsidian": {
#     "command": "npx",
#     "args": ["@bitbonsai/mcpvault@latest", "/data/data/com.termux/files/home/obsidiano"],
#     "disabled": false
#   }

# 4. Install Gstack
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
cd ~/.claude/skills/gstack && ./setup

# 5. Validate hooks script works under Termux bash
bash ~/.claude/hooks/session-start-memory-loader.sh | head -20

# 6. Smoke test
claude
> "leia Claude/memory/active.md"
```

**What Mobile does NOT get (same as Foundation matrix):**
- No Context7 (removed from scope)
- No RuFlo (VPS only)
- No auto-promote cron (Termux cron is fragile — skip until Phase 2)
- No Task Scheduler / crontab entries

**Mobile-specific Foundation flags:**
- Memory loader runs in degraded mode if `/data/data/com.termux/files/home/obsidiano` is not mounted
- Session-end hook auto-commits but does NOT auto-push (no credentials cached)
- Test S7-S13 apply; S10/S12 require jq (installed in prerequisites above)

**Known Termux gotchas:**
- `touch -d` works (GNU touch available via coreutils package)
- `set -uo pipefail` works in Termux bash
- `npx` works but may prompt once for confirmation on first run — accept with `y`

### 11.2 Seed file extraction sources

During implementation, these sources are read to populate the 6 seed files:

- `~/.claude/projects/C--Users-teste/memory/*.md` — existing auto-memory for root cwd
- `obsidiano/Claudete.md` — existing index hub
- `obsidiano/CLAUDE.md` (pre-refactor) — rules to extract into preferences.md
- `obsidiano/singular/`, `Projetos/`, `Clientes/`, `Pessoal/` — project discovery for projects.md
- `obsidiano/Jarvis/` — references for people.md and projects.md
- Existing `project_triforce.md`, `user_profile.md` auto-memory files — for user.md

### 11.3 Reference commits and issues

- None yet (Foundation not yet implemented). This section updated during implementation.

---

*End of spec.*
