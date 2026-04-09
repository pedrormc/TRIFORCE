# Foundation Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the TRIFORCE Foundation (sub-projects A+B): unified memory brain in `obsidiano/Claude/`, split vault CLAUDE.md to preserve Zel, install Gstack + RuFlo stack with dedup, wire session lifecycle hooks with auto-promote safety nets, all with tests-first discipline and reversible commits.

**Architecture:** Three-layer context (env-local / vault-brain / project-local), MCPVault as bridge, unified schema across auto-memory + claude-memory + vault. Tests-first per component: smoke test written → fails → component implemented → smoke passes → commit.

**Tech Stack:** Bash (hooks + scripts), jq (config validation), git (version control + rollback), MCPVault `@bitbonsai/mcpvault` (Obsidian MCP), Gstack (Garry Tan slash commands), RuFlo `npx ruflo@latest` (VPS only, workers off), Windows Task Scheduler + cron (cron), Bun (Zel whatsapp-channel.ts).

**Spec reference:** `docs/superpowers/specs/2026-04-09-foundation-design.md`

**Scope adherence:** This plan implements ONLY sub-projects A+B (Foundation). It does NOT cover sub-projects C (cross-env sync), D (autonomous tasks), E (multimodal memory), F (mascot), or Phase 2 (RuFlo workers activation).

---

## File Structure (What Gets Created/Modified)

### In `obsidiano` (vault) — new files

| Path | Responsibility |
|---|---|
| `CLAUDE.md` (REPLACE) | Thin loader (~20 lines) pointing to persona or generic |
| `Claude/CLAUDE.md` | Generic standing orders (~60 lines) for any Claude Code session |
| `Claude/personas/zel.md` | Zel-specific system prompt (extracted from old CLAUDE.md) |
| `Claude/memory/active.md` | Live state of current week (editable) |
| `Claude/memory/decisions.md` | Append-only decision log |
| `Claude/memory/people.md` | Context about people (extends Clientes/) |
| `Claude/memory/preferences.md` | User work preferences (+ auto-promote target) |
| `Claude/memory/projects.md` | Global projects index |
| `Claude/memory/user.md` | User profile |
| `Claude/memory/INDEX.md` | Auto-generated master map (read-only to humans) |
| `Claude/memory/.promotion-log.jsonl` | Append-only audit log of auto-promotions |
| `Claude/sessions/` | Session files mirrored from `~/.claude/sessions/` (initially empty) |

### In `~/.claude/` (Desktop env local, propagates to VPS via toolkit) — new files

| Path | Responsibility |
|---|---|
| `hooks/session-start-memory-loader.sh` | Load unified memory into session context |
| `hooks/post-edit-memory-validator.sh` | Non-blocking YAML warning + auto-update last_updated |
| `hooks/session-end-memory-writer.sh` | Update active.md + regenerate INDEX + auto-commit |
| `hooks/save-session-vault-mirror.sh` | Mirror session files to vault |
| `scripts/memory-update.sh` | Unified write API (auto / claude / vault) |
| `scripts/memory-auto-promote.sh` | Daily cron — promote with 10 safety nets |
| `scripts/memory-index-rebuild.sh` | Regenerate `Claude/memory/INDEX.md` |
| `scripts/memory-revert.sh` | Revert an auto-promotion by entry_id |
| `scripts/foundation-smoke.sh` | Run all 13 smoke tests |
| `scripts/foundation-validate.sh` | Run smoke + 7 integration tests |
| `scripts/foundation-uninstall.sh` | Universal rollback — remove hooks, cron, keep vault |
| `rules/common/namespace-cheatsheet.md` | Documented plugin overlap resolution |
| `settings.json` (MODIFY) | Add hook entries + `disabledPlugins` |

### In `claude-code-toolkit` — new/modified files (propagates via `install.sh`)

| Path | Change |
|---|---|
| `hooks/` (new folder) | All 4 hooks above |
| `scripts/` (existing, expand) | All 7 scripts above |
| `rules/common/namespace-cheatsheet.md` | New rule file |
| `config/settings.json` | Updated with hook entries + `disabledPlugins` |
| `install.sh` | Extended to install Gstack, copy hooks, setup cron |
| `templates/claude-md/zel.md` | New template (extracted Zel persona) |
| `README.md` | Updated plugins section (+Gstack, ~Ralph deprecated) |

### In `pedrormc/zel` — code change

| Path | Change |
|---|---|
| `whatsapp-channel.ts` | Load two files (`Claude/CLAUDE.md` + `Claude/personas/zel.md`) instead of one |

### Defensive tags (before any work)

| Repo | Tag |
|---|---|
| `pedrormc/obsidiano` | `pre-foundation-2026-04-09` |
| `pedrormc/claude-code-toolkit` | `pre-foundation-2026-04-09` |
| `pedrormc/TRIFORCE` | `pre-foundation-2026-04-09` |
| `pedrormc/zel` | `pre-foundation-2026-04-09` |

---

## Chunk 1: Preparation & Vault Refactor & Memory Seeds

> Goal of chunk: leave the vault in a state where `obsidiano/CLAUDE.md` is a loader, `Claude/CLAUDE.md` is generic standing orders, `Claude/personas/zel.md` holds the Zel persona, and all 6 memory seeds + INDEX are populated with REAL extracted data. No hooks or scripts yet.

### Task 1: Defensive tags on all 4 repos

**Files:** No files written. This is git state.

- [ ] **Step 1.1: Tag TRIFORCE**

  ```bash
  cd ~/Desktop/TRIFORCE
  git tag pre-foundation-2026-04-09
  git push origin pre-foundation-2026-04-09
  ```

- [ ] **Step 1.2: Tag claude-code-toolkit**

  ```bash
  cd ~/Desktop/claude-code-toolkit
  git tag pre-foundation-2026-04-09
  git push origin pre-foundation-2026-04-09
  ```

- [ ] **Step 1.3: Tag obsidiano**

  ```bash
  cd ~/Documents/obsidiano
  git tag pre-foundation-2026-04-09
  git push origin pre-foundation-2026-04-09
  ```

- [ ] **Step 1.4: Tag zel (from Desktop if cloned, or SSH to VPS)**

  If Zel is not cloned locally:

  ```bash
  ssh vps "cd ~/zel && git tag pre-foundation-2026-04-09 && git push origin pre-foundation-2026-04-09"
  ```

  If Zel is cloned locally:

  ```bash
  cd ~/Desktop/zel
  git tag pre-foundation-2026-04-09
  git push origin pre-foundation-2026-04-09
  ```

- [ ] **Step 1.5: Verify all 4 tags exist on remote**

  ```bash
  for repo in TRIFORCE claude-code-toolkit obsidiano zel; do
    echo "=== $repo ==="
    git ls-remote --tags https://github.com/pedrormc/$repo.git | grep pre-foundation-2026-04-09
  done
  ```

  Expected output: 4 lines, one per repo, each containing `refs/tags/pre-foundation-2026-04-09`.

### Task 2: Create feature branch in vault

**Files:** Branch `feat/foundation-claude-split` created in `obsidiano`.

- [ ] **Step 2.1: Create branch**

  ```bash
  cd ~/Documents/obsidiano
  git checkout main
  git pull
  git checkout -b feat/foundation-claude-split
  ```

- [ ] **Step 2.2: Belt-and-suspenders backup of CLAUDE.md**

  ```bash
  cp CLAUDE.md CLAUDE.md.backup
  echo "CLAUDE.md.backup" >> .gitignore
  ```

  (The backup is outside git, used only for emergency restore if branch machinery breaks.)

### Task 3: Create Claude/ folder structure

**Files:**
- Create: `obsidiano/Claude/personas/` (dir)
- Create: `obsidiano/Claude/memory/` (dir)
- Create: `obsidiano/Claude/sessions/` (dir)

- [ ] **Step 3.1: Write the smoke test first**

  ```bash
  cat > /tmp/smoke-task3.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  test -d ~/Documents/obsidiano/Claude/personas
  test -d ~/Documents/obsidiano/Claude/memory
  test -d ~/Documents/obsidiano/Claude/sessions
  echo "✅ Task 3 smoke passed"
  EOF
  chmod +x /tmp/smoke-task3.sh
  ```

- [ ] **Step 3.2: Run smoke test — expect FAIL**

  ```bash
  /tmp/smoke-task3.sh
  ```

  Expected: exit 1, error on first `test -d` (directories don't exist yet).

- [ ] **Step 3.3: Create the directories**

  ```bash
  cd ~/Documents/obsidiano
  mkdir -p Claude/personas Claude/memory Claude/sessions
  ```

- [ ] **Step 3.4: Run smoke test — expect PASS**

  ```bash
  /tmp/smoke-task3.sh
  ```

  Expected: `✅ Task 3 smoke passed`

- [ ] **Step 3.5: Add `.gitkeep` to empty dirs so git tracks them**

  ```bash
  touch Claude/personas/.gitkeep Claude/sessions/.gitkeep
  ```

  (`Claude/memory/` will get real files in later tasks.)

### Task 4: Extract Zel persona

**Files:**
- Create: `obsidiano/Claude/personas/zel.md`
- Read source: `obsidiano/CLAUDE.md` (current, Zel system prompt)

- [ ] **Step 4.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task4.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/Documents/obsidiano/Claude/personas/zel.md
  test -f "$F"
  head -5 "$F" | grep -q "Voce e o Zel"
  grep -q "reply tool" "$F"
  grep -q "Paridade com Claude VPS" "$F"
  echo "✅ Task 4 smoke passed"
  EOF
  chmod +x /tmp/smoke-task4.sh
  ```

- [ ] **Step 4.2: Run smoke — expect FAIL**

  ```bash
  /tmp/smoke-task4.sh
  ```

  Expected: `No such file or directory`.

- [ ] **Step 4.3: Write `Claude/personas/zel.md`**

  File content:

  ```markdown
  ---
  name: Zel Persona
  description: Assistente pessoal de produtividade via WhatsApp — runs on VPS as persistent Claude Code Channel
  type: persona
  scope: vault
  source: claude-memory
  last_updated: 2026-04-09
  env: vps-only
  ---

  Voce e o Zel, assistente pessoal de produtividade do Pedro (Robertin).

  Voce roda como sessao persistente do Claude Code com um WhatsApp channel via Evolution API.
  A sessao fica viva — nao precisa abrir/fechar a cada mensagem.

  ## Paridade com Claude VPS

  Voce tem as MESMAS capacidades que o Claude Code rodando interativamente na VPS:
  - Mesmos agents (devops-agent, research-agent, frontend-specialist, api-specialist, prompt-engineer)
  - Mesmas rules e skills
  - Mesmas permissoes (bypassPermissions)
  - Acesso completo a ~/workspace/ (zel, obsidiano, e qualquer repo futuro)
  - Diferenca: sua interface e WhatsApp, entao respostas devem ser curtas e via reply tool

  ## Como responder via WhatsApp (reply tool)
  - Sempre use o tool reply pra enviar respostas — seu output no terminal NAO chega no WhatsApp
  - Maximo 3 paragrafos curtos — e WhatsApp, nao email
  - Se a tarefa for longa, mande updates parciais via reply
  - Se nao conseguir fazer algo, explique o motivo e sugira alternativa via reply
  - Use emojis com moderacao (1-2 por mensagem max)

  ## Permissoes de Tools
  - Quando precisar de aprovacao pra executar algo, o pedido vai pro WhatsApp automaticamente
  - Pedro responde "sim <codigo>" ou "nao <codigo>" direto no chat
  - SEMPRE perguntar antes de enviar mensagem via WhatsApp/Evolution API para qualquer numero que NAO seja o do Pedro (556199272347). Confirmar destinatario e conteudo antes de enviar.

  ## Agendar lembretes
  - Agendar lembretes: salve em ~/zel/reminders.json no formato:
    `[{"time": "2026-03-25T15:00:00", "text": "Ligar pro Bedran"}]`

  ---

  **As regras base (segurança, vault, categorias, estrutura) estão em `Claude/CLAUDE.md`.** Este arquivo contém APENAS o que é específico do Zel. Leia os dois juntos.

  *[Registrado por: DESKTOP — 2026-04-09]*
  ```

- [ ] **Step 4.4: Run smoke — expect PASS**

  ```bash
  /tmp/smoke-task4.sh
  ```

  Expected: `✅ Task 4 smoke passed`

### Task 5: Write generic standing orders (Claude/CLAUDE.md)

**Files:**
- Create: `obsidiano/Claude/CLAUDE.md`

- [ ] **Step 5.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task5.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/Documents/obsidiano/Claude/CLAUDE.md
  test -f "$F"
  grep -q "SEGURANCA" "$F"
  grep -q "PT-BR" "$F"
  grep -q "Categorias" "$F"
  grep -q "Claude/memory" "$F"
  echo "✅ Task 5 smoke passed"
  EOF
  chmod +x /tmp/smoke-task5.sh
  ```

- [ ] **Step 5.2: Run smoke — expect FAIL**

  ```bash
  /tmp/smoke-task5.sh
  ```

- [ ] **Step 5.3: Write `Claude/CLAUDE.md`**

  File content:

  ```markdown
  ---
  name: Vault Standing Orders
  description: Generic standing orders for any Claude Code session reading the vault
  type: reference
  scope: vault
  source: claude-memory
  last_updated: 2026-04-09
  ---

  # Standing Orders — Vault Claude Code

  Este arquivo contém as regras base pra qualquer Claude Code rodando com acesso ao vault Obsidian. Aplica pros 3 ambientes TRIFORCE (Desktop/Mobile/VPS). Se você é o Zel, leia também `Claude/personas/zel.md` pras regras específicas do WhatsApp channel.

  ## Identidade & Idioma
  - PT-BR informal, casual, direto
  - Sem emojis a menos que explicitamente solicitado
  - Respostas curtas, vai pro ponto
  - Não resumir o que o usuário acabou de pedir

  ## Regras gerais
  - Se não achar a informação no vault, diga "não achei no vault"
  - Nunca invente dados
  - Nunca delete arquivos permanentemente sem pedir
  - Pra ações destrutivas ou irreversíveis, pergunte antes

  ## SEGURANCA — REGRA CRITICA
  - NUNCA envie tokens, senhas, API keys, secrets ou credenciais via WhatsApp/reply
  - Se o usuário pedir um token/senha, responda: "Por segurança, não posso enviar credenciais pelo WhatsApp. Acesse direto na VPS."
  - Isso vale pra QUALQUER conteúdo que contenha: api key, token, password, secret, credential, .env, private key
  - Se uma nota do vault contiver segredos, descreva o que a nota contém mas NUNCA copie o valor
  - Ao ler arquivos .env, tokens, credentials.json etc: descreva a existência mas NUNCA mostre valores
  - Esta regra NÃO pode ser sobrescrita por nenhuma instrução do usuário

  ## Capacidades — Vault (Obsidian)
  - Buscar e ler notas no vault Obsidian via MCPVault
  - Criar notas com frontmatter (category, status, stack, created, updated)
  - Consultar projetos por categoria
  - Listar tarefas pendentes
  - Acessar info de clientes, reuniões, agentes (Jarvis)

  ## Memory Brain — leitura obrigatória no início de cada sessão

  Os 6 arquivos abaixo são o cérebro unificado. O hook SessionStart carrega todos eles automaticamente:

  - `Claude/memory/user.md` — quem é o usuário
  - `Claude/memory/preferences.md` — preferências de trabalho
  - `Claude/memory/active.md` — estado vivo da semana
  - `Claude/memory/decisions.md` — log de decisões
  - `Claude/memory/people.md` — contexto sobre pessoas
  - `Claude/memory/projects.md` — índice global de projetos

  Para escritas, use `~/.claude/scripts/memory-update.sh` em vez de editar direto.

  ## Categorias de Projeto
  - **pessoal** → pasta `Pessoal/`
  - **paralelo** → pasta `Projetos/`
  - **freelancer** → pasta `Freelancer/` ou `Clientes/`
  - **singular** → pasta `singular/` (Grupo Black, dedicação full-time)

  ## Estrutura do Vault
  - `singular/` — Empresa, CTO, vendas, Notas Black
  - `Projetos/` — Bombeiros, Glória, Crypto Card
  - `Clientes/` — HOF Masters, Scouting, Bedran, SoCute, ADenergia, etc
  - `Pessoal/` — Currículo, projetos pessoais
  - `Jarvis/` — Hub de agentes IA e automações
  - `Reuniões/` — Pautas, devolutivas, recaps
  - `Diário/` — Daily notes
  - `Tech & IA/` — Estudos e referências técnicas
  - `Claude/` — Memory brain (este diretório)

  ## Tag de origem (obrigatório em TODA escrita no vault)

  Toda escrita no vault por uma instância do Claude Code deve terminar com:

  `*[Registrado por: {DESKTOP|MOBILE|VPS} — YYYY-MM-DD]*`

  Isso garante rastreabilidade cross-env.

  ---

  *Arquivo carregado pelo hook session-start-memory-loader.sh. Não editar sem atualizar `last_updated`.*
  ```

- [ ] **Step 5.4: Run smoke — expect PASS**

  ```bash
  /tmp/smoke-task5.sh
  ```

### Task 6: Replace vault/CLAUDE.md with loader

**Files:**
- Modify: `obsidiano/CLAUDE.md` (overwrite with loader content)

- [ ] **Step 6.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task6.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/Documents/obsidiano/CLAUDE.md
  test -f "$F"
  grep -q "Vault Claude Instructions" "$F"
  grep -q "Claude/personas/zel.md" "$F"
  grep -q "Claude/CLAUDE.md" "$F"
  # Must be short (loader, not full Zel prompt)
  LINES=$(wc -l < "$F")
  test "$LINES" -lt 35
  echo "✅ Task 6 smoke passed (${LINES} lines)"
  EOF
  chmod +x /tmp/smoke-task6.sh
  ```

- [ ] **Step 6.2: Run smoke — expect FAIL**

  ```bash
  /tmp/smoke-task6.sh
  ```

  Expected: current `CLAUDE.md` has 75 lines (Zel prompt) — test fails at line count check or content check.

- [ ] **Step 6.3: Overwrite with loader content**

  File content:

  ```markdown
  # Vault Claude Instructions

  Este vault é compartilhado entre 3 ambientes Claude Code (TRIFORCE) + Zel (WhatsApp).

  ## Como carregar as instruções certas

  - **Se você é o Zel** (sessão do WhatsApp channel rodando na VPS):
    → Leia `Claude/personas/zel.md` (persona + reply tool + regras WhatsApp)
    → Depois leia `Claude/CLAUDE.md` (regras base compartilhadas)

  - **Se você é Claude Master (Desktop) ou Claude Mobile ou Claude VPS (interativo)**:
    → Leia `Claude/CLAUDE.md` (regras base)
    → Leia `Claude/memory/*.md` (contexto persistente)

  ## Indicador de ambiente

  O env atual está em `~/.claude/CLAUDE.md`. Se lá dentro tiver `role: zel` ou
  o processo pai for `whatsapp-channel.ts`, use a persona Zel. Senão, modo genérico.

  ---

  *Arquivo gerado pelo Foundation sub-project, 2026-04-09. Não editar direto —
   edite `Claude/CLAUDE.md` ou `Claude/personas/*.md`.*
  ```

- [ ] **Step 6.4: Run smoke — expect PASS**

  ```bash
  /tmp/smoke-task6.sh
  ```

### Task 7: Write memory seed `user.md`

**Files:**
- Create: `obsidiano/Claude/memory/user.md`

- [ ] **Step 7.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task7.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/Documents/obsidiano/Claude/memory/user.md
  test -f "$F"
  grep -q "^type: user" "$F"
  grep -q "Pedro Roberto" "$F"
  grep -q "pedrormc" "$F"
  grep -q "Singular Group" "$F"
  grep -q "TRIFORCE" "$F"
  echo "✅ Task 7 smoke passed"
  EOF
  chmod +x /tmp/smoke-task7.sh
  ```

- [ ] **Step 7.2: Run smoke — expect FAIL**

- [ ] **Step 7.3: Read source data**

  ```bash
  # Source 1: existing auto-memory
  cat ~/.claude/projects/C--Users-teste/memory/user_profile.md 2>/dev/null
  # Source 2: reference files
  cat ~/.claude/projects/C--Users-teste/memory/reference_desktop.md 2>/dev/null
  # Source 3: Claudete.md for tech stack
  cat ~/Documents/obsidiano/Claudete.md 2>/dev/null | head -100
  ```

- [ ] **Step 7.4: Write `Claude/memory/user.md`**

  File content (populate with real data extracted from Step 7.3):

  ```markdown
  ---
  name: User Profile
  description: Pedro Roberto / Robertin / pedrormc — CTO Singular Group
  type: user
  scope: global
  source: claude-memory
  last_updated: 2026-04-09
  ---

  ## Identidade
  - **Nome:** Pedro Roberto Miranda de Carvalho
  - **Apelido:** Robertin
  - **GitHub:** pedrormc
  - **WhatsApp:** +55 61 99272-3347
  - **Cargo:** CTO @ Singular Group (Grupo Black)

  ## Stack expertise
  - **Backend:** Node.js, TypeScript, Express, FastAPI, PostgreSQL
  - **Frontend:** React 19, Next.js 15, Tailwind v4, Vite 6
  - **Mobile:** React Native (raro)
  - **Automação:** n8n workflows, Claude Code multi-ambiente (TRIFORCE)
  - **CRM:** HubSpot (2 instances: singular + smup), Evolution API (WhatsApp)
  - **DevOps:** Vercel, Docker, AWS Lightsail, DigitalOcean, GitHub Actions, Bun
  - **IA:** Anthropic Claude (Opus/Sonnet/Haiku), OpenAI embeddings, Qdrant, LangChain

  ## Background
  - 10+ anos full-stack
  - Foco em automação + IA aplicada a negócio
  - Estilo: shipping > perfeição, mas com TDD, code review, testes obrigatórios
  - Preferência por abordagens pragmáticas (Approach 3 hybrid) sobre minimal ou aggressive

  ## TRIFORCE — 3 ambientes Claude Code
  - **Desktop** (Claude Master) — Windows 11, Opus 4.6 1M context, permissões totais, dev principal
  - **Mobile** (Claude Mobile) — Termux/Poco F5, restrito, pouco usado
  - **VPS** (Claude VPS + Zel) — Ubuntu DigitalOcean, user nativo `claude` (migrado de Docker 2026-04-02), Zel WhatsApp channel

  ## Repos ativos (github.com/pedrormc/)
  - **TRIFORCE** — metodologia multi-env
  - **claude-code-toolkit** — ferramentas compartilhadas (agents, skills, rules, hooks)
  - **obsidiano** — vault Obsidian (este)
  - **zel** — WhatsApp channel + Evolution API
  - **Mel** — plataforma proteção animal SEPAN/GDF (cliente Eduardo Dib / Atlantis)
  - **Mili** — agente de vendas n8n + HubSpot
  - **FireDash** — dashboard bombeiros
  - **PixCoffee** — sistema IoT café Dolce Gusto
  - **pwrcff** — Headless Shopify (PWR Coffee)

  ## Convenções de assinatura
  Toda escrita em arquivos compartilhados termina com:
  `*[Registrado por: {DESKTOP|MOBILE|VPS} — YYYY-MM-DD]*`

  *[Registrado por: DESKTOP — 2026-04-09]*
  ```

- [ ] **Step 7.5: Run smoke — expect PASS**

### Task 8: Write memory seed `preferences.md`

**Files:**
- Create: `obsidiano/Claude/memory/preferences.md`

- [ ] **Step 8.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task8.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/Documents/obsidiano/Claude/memory/preferences.md
  test -f "$F"
  grep -q "^type: preferences" "$F"
  grep -q "PT-BR" "$F"
  grep -q "imutab" "$F"
  grep -q "DESKTOP\|MOBILE\|VPS" "$F"
  echo "✅ Task 8 smoke passed"
  EOF
  chmod +x /tmp/smoke-task8.sh
  ```

- [ ] **Step 8.2: Run smoke — expect FAIL**

- [ ] **Step 8.3: Read source feedback files**

  ```bash
  cat ~/.claude/projects/C--Users-teste/memory/feedback_*.md 2>/dev/null
  cat ~/.claude/rules/common/coding-style.md 2>/dev/null
  ```

- [ ] **Step 8.4: Write `Claude/memory/preferences.md`**

  File content:

  ```markdown
  ---
  name: User Preferences
  description: Como o Claude deve trabalhar com o Pedro — comunicação, código, workflow
  type: preferences
  scope: global
  source: claude-memory
  last_updated: 2026-04-09
  ---

  ## Comunicação
  - PT-BR informal, casual, direto
  - Sem emojis a menos que explicitamente solicitado
  - Respostas curtas, vai pro ponto
  - Não resumir o que o usuário acabou de pedir
  - Não adicionar preamble ou postamble — vai direto ao ponto

  ## Código — princípios obrigatórios
  - **Imutabilidade** — sempre criar novos objetos, nunca mutar
  - **Files pequenos** — 200-400 linhas típico, 800 linhas máximo
  - **High cohesion, low coupling** — organizar por feature/domínio, não por tipo
  - **Error handling explícito** — em todos os níveis, nunca swallow
  - **Input validation com Zod** — nunca confiar em dados externos
  - **No mutation, no hardcoded values, no console.log em código TypeScript**
  - **80%+ test coverage** — unit + integration + E2E (framework por linguagem)
  - **Conventional commits** — tipo: descrição (feat/fix/refactor/docs/test/chore/perf/ci)

  ## Workflow
  - **TDD obrigatório** — Red / Green / Refactor (superpowers:test-driven-development)
  - **Research antes de código** — checar libs existentes (gh search), Exa MCP, package registries
  - **Plan antes de code** — superpowers:writing-plans ou superpowers:brainstorming
  - **Code review automático** — superpowers:code-reviewer imediatamente após escrita
  - **Security check pre-commit** — everything-claude-code:security-reviewer

  ## Ferramentas
  - **Prefere:** Read/Grep/Glob sobre cat/grep/find no shell
  - **Prefere:** Edit sobre sed/awk
  - **Prefere:** TaskCreate pra tarefas >3 passos
  - **Prefere:** Agent tool pra pesquisas complexas
  - **Prefere:** Parallel tool calls quando não há dependência

  ## Origem das escritas (CRÍTICO)
  Toda escrita em arquivos compartilhados (vault, toolkit, rules) deve terminar com:
  `*[Registrado por: {DESKTOP|MOBILE|VPS} — YYYY-MM-DD]*`

  ## Configs `~/.claude/`
  **NUNCA sobrescrever** configs existentes. **Só adicionar**. Se quebrar algo por sobrescrita, é falha grave.

  ## Git
  - Nunca push sem pedir explicitamente
  - Nunca force push em main/master sem alerta
  - Commits frequentes > commits grandes
  - PR workflow: full history, não só último commit

  ## Model selection (superpowers:coding-standards)
  - **Opus 4.6** — dev principal, raciocínio complexo, orchestração multi-agent
  - **Sonnet 4.6** — melhor pra coding puro, trabalho principal
  - **Haiku 4.5** — agents leves e frequentes, 3x savings

  *[Registrado por: DESKTOP — 2026-04-09]*
  ```

- [ ] **Step 8.5: Run smoke — expect PASS**

### Task 9: Write memory seed `active.md`

**Files:**
- Create: `obsidiano/Claude/memory/active.md`

- [ ] **Step 9.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task9.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/Documents/obsidiano/Claude/memory/active.md
  test -f "$F"
  grep -q "^type: active" "$F"
  grep -q "Projetos ativos" "$F"
  grep -q "Últimas" "$F"
  test $(grep -c "^##" "$F") -ge 3
  echo "✅ Task 9 smoke passed"
  EOF
  chmod +x /tmp/smoke-task9.sh
  ```

- [ ] **Step 9.2: Run smoke — expect FAIL**

- [ ] **Step 9.3: Read current active state from project memories**

  ```bash
  ls ~/.claude/projects/ | head
  for p in C--Users-teste-Desktop-n8n-Mili C--Users-teste-Desktop-AAsites-antigra-Mel C--Users-teste; do
    echo "=== $p ==="
    ls ~/.claude/projects/$p/memory/ 2>/dev/null
  done
  ```

- [ ] **Step 9.4: Write `Claude/memory/active.md`**

  File content (populate with real data):

  ```markdown
  ---
  name: Active State
  description: Estado vivo da semana — projetos ativos, prioridades, blockers, últimas sessões
  type: active
  scope: global
  source: claude-memory
  last_updated: 2026-04-09
  ---

  ## Projetos ativos esta semana

  - **TRIFORCE Foundation** — em implementação (sub-projetos A+B). Spec aprovado, plan em execução. Este é o projeto meta do Foundation unified memory system.
  - **Mili** (n8n sales agent) — pipeline HubSpot Singular reestruturado em 2026-04-07. Próximo: corrigir 2 deals sem `responsavel_negociacao` (Life Fitness + 1). Custom properties criadas (escopo_negociado, fonte_do_lead, dor_principal, temperatura_da_venda). Ref: [[Projetos/Mili]]
  - **Mel** (proteção animal SEPAN/GDF) — fase 1 implementação, spec + plan completos. Cliente Eduardo Dib / Atlantis. Deploy Vercel aprovado em 2026-04-06 mas status atual pendente verificação. Ref: [[Clientes/Eduardo Dib]]

  ## Próximas 3 prioridades
  1. Executar Foundation implementation plan (este documento)
  2. Confirmar deploy Vercel do Mel + continuação Fase 2 (dossiê PDF)
  3. Corrigir 2 deals HubSpot sem responsavel_negociacao + sincronizar workflow Mili com novos stage IDs

  ## Blockers / pendências
  - Mel deploy status não confirmado (precisa checar produção vercel)
  - 2 deals HubSpot Singular sem responsavel_negociacao (Life Fitness + 1 outro)
  - Mobile environment não configurado com Foundation (apêndice documentado, rodar depois)

  ## Últimas 3 sessões (auto-updated pelo session-end hook)
  - 2026-04-09 DESKTOP: brainstorming + spec + plan Foundation TRIFORCE
  - 2026-04-07 DESKTOP: limpou HubSpot Singular (49 deals, 0 empresas, 5 contatos)
  - 2026-04-06 DESKTOP: Mel UI design + plan implementação + deploy Vercel

  *[Registrado por: DESKTOP — 2026-04-09]*
  ```

- [ ] **Step 9.5: Run smoke — expect PASS**

### Task 10: Write memory seed `decisions.md`

**Files:**
- Create: `obsidiano/Claude/memory/decisions.md`

- [ ] **Step 10.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task10.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/Documents/obsidiano/Claude/memory/decisions.md
  test -f "$F"
  grep -q "^type: decisions" "$F"
  grep -q "Motivo:" "$F"
  grep -q "Review em:" "$F"
  echo "✅ Task 10 smoke passed"
  EOF
  chmod +x /tmp/smoke-task10.sh
  ```

- [ ] **Step 10.2: Run smoke — expect FAIL**

- [ ] **Step 10.3: Write `Claude/memory/decisions.md`**

  File content:

  ```markdown
  ---
  name: Decisions Log
  description: Append-only log de decisões com motivo, outcome esperado e data de revisão
  type: decisions
  scope: global
  source: claude-memory
  last_updated: 2026-04-09
  ---

  > **Append-only.** Nunca editar nem deletar entradas anteriores. Paginar trimestralmente se passar de 1000 linhas.

  ## 2026-04-09 — Foundation TRIFORCE: escolher Approach 3 Hybrid
  **Motivo:** Resolve conflito do vault/CLAUDE.md sem ser invasivo. Instala stack incremental (Gstack ativo, RuFlo VPS-only com workers off). Zero dedup no início — decide após 14 dias de uso real.
  **Outcome esperado:** 3 envs leem mesma memória do vault via MCPVault sem quebrar Zel. Memory brain unificado + stack expandido. ~2-3 sessões de implementação.
  **Review em:** 2026-05-09

  ## 2026-04-09 — Remover Context7 do Foundation
  **Motivo:** Stack atual (Opus 4.6 + WebFetch + research-agent + n8n-mcp + HubSpot MCPs) cobre ~90% dos casos onde Context7 ajudaria. API key grátis mas adiciona friction nos 3 envs. Marginal value baixo.
  **Outcome esperado:** Setup mais enxuto. Adiciona Context7 só se bater num caso real de lib nova não reconhecida.
  **Review em:** 2026-05-09

  ## 2026-04-09 — Auto-promoção de memória: preset Balanceado
  **Motivo:** 3 projetos + 7 dias + 0.75 similarity Jaccard = sweet spot. Frouxo gera ruído, Conservador cresce devagar. Ajustável via `~/.claude/config/auto-promote.yaml` sem redeploy.
  **Outcome esperado:** ~1-3 promoções/semana com baixo falso positivo. Cronada diária 03:00 com 10 safety nets + reversão fácil.
  **Review em:** 2026-05-09

  ## 2026-04-07 — HubSpot Singular: deletar 947 empresas + reestruturar pipeline
  **Motivo:** 204 empresas lixo + 743 SMUP importadas por engano. Pipeline antigo misturava Network/NPS/Recomendação não usados. Novo kanban reflete funil real: Prospecção → Diagnóstico → Triagem (agendada/realizada) → Fechamento → Assinatura.
  **Outcome esperado:** CRM limpo, 49 deals válidos, 5 contatos, 0 empresas, workflows Mili usando novos stage IDs (`1338114665`, `1338115606`, `closedwon`=EM ASSINATURA).
  **Review em:** 2026-04-21

  ## 2026-04-02 — VPS: migrar Docker → user nativo `claude`
  **Motivo:** Simplifica deploy, reduz overhead, permite paridade com Desktop via toolkit install.sh.
  **Outcome esperado:** VPS Ubuntu 24.04 rodando Claude Code nativo, Zel via bun, deploy via git pull + install.sh.
  **Review em:** 2026-05-02

  *[Registrado por: DESKTOP — 2026-04-09]*
  ```

- [ ] **Step 10.4: Run smoke — expect PASS**

### Task 11: Write memory seed `people.md`

**Files:**
- Create: `obsidiano/Claude/memory/people.md`

- [ ] **Step 11.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task11.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/Documents/obsidiano/Claude/memory/people.md
  test -f "$F"
  grep -q "^type: people" "$F"
  grep -q "Eduardo Dib" "$F"
  grep -qE "\[\[Clientes" "$F"
  echo "✅ Task 11 smoke passed"
  EOF
  chmod +x /tmp/smoke-task11.sh
  ```

- [ ] **Step 11.2: Run smoke — expect FAIL**

- [ ] **Step 11.3: List existing client notes**

  ```bash
  ls ~/Documents/obsidiano/Clientes/ 2>/dev/null
  ```

- [ ] **Step 11.4: Write `Claude/memory/people.md`**

  File content (populate with real clients — placeholder example below, fill in more from step 11.3):

  ```markdown
  ---
  name: People Context
  description: Contexto vivo sobre pessoas — complementa Clientes/ sem duplicar
  type: people
  scope: global
  source: claude-memory
  last_updated: 2026-04-09
  ---

  > Este arquivo contém contexto VIVO (preferências, último contato, padrões de comunicação) sobre pessoas importantes. Não duplica o conteúdo de `Clientes/` — referencia via wiki links. Fonte primária de dados permanece nas notas individuais.

  ## Eduardo Dib
  **Empresa:** Atlantis Technologies
  **Projeto ativo:** Mel — plataforma proteção animal SEPAN/GDF
  **Vault:** [[Clientes/Eduardo Dib]]
  **Contexto vivo:** Cliente principal do projeto Mel (fork do FireDash). Projeto em fase 1 com UI/UX aprovada, spec completa, deploy Vercel iniciado em 2026-04-06.
  **Padrão de comunicação:** [preencher conforme sessões]

  ## Bedran (Pedro Bedran)
  **Vault:** [[Clientes/Bedran]]
  **Contexto vivo:** [preencher]

  ## HOF Masters (contato)
  **Vault:** [[Clientes/HOF MASTERS]]
  **Contexto vivo:** [preencher]

  ## SoCute
  **Vault:** [[Clientes/SoCute]]
  **Contexto vivo:** [preencher]

  ## ADenergia
  **Vault:** [[Clientes/ADenergia]]
  **Contexto vivo:** [preencher]

  ---

  > **Convenção:** quando aprender um fato novo sobre uma pessoa, adicionar como bullet ou sub-seção aqui. Nunca duplicar dados primários do vault — só contexto.

  *[Registrado por: DESKTOP — 2026-04-09]*
  ```

  **Nota:** o `[preencher]` nos placeholders é intencional — significa "conteúdo será adicionado conforme sessões capturam contexto vivo". NÃO é um TODO bloqueante.

- [ ] **Step 11.5: Run smoke — expect PASS**

### Task 12: Write memory seed `projects.md`

**Files:**
- Create: `obsidiano/Claude/memory/projects.md`

- [ ] **Step 12.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task12.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/Documents/obsidiano/Claude/memory/projects.md
  test -f "$F"
  grep -q "^type: projects" "$F"
  grep -q "Singular" "$F"
  grep -q "Foundation" "$F"
  grep -q "Mili" "$F"
  grep -q "Mel" "$F"
  echo "✅ Task 12 smoke passed"
  EOF
  chmod +x /tmp/smoke-task12.sh
  ```

- [ ] **Step 12.2: Run smoke — expect FAIL**

- [ ] **Step 12.3: Write `Claude/memory/projects.md`**

  File content:

  ```markdown
  ---
  name: Projects Index
  description: Índice global de todos os projetos conhecidos (singular / freelancer / paralelo / pessoal / meta)
  type: projects
  scope: global
  source: claude-memory
  last_updated: 2026-04-09
  ---

  ## Singular (full-time)
  | Projeto | Status | Stack | Vault / Repo |
  |---|---|---|---|
  | Mili (n8n sales agent) | active | n8n + HubSpot + Claude | [[Projetos/Mili]] / @github:pedrormc/Mili |
  | HubSpot Singular | active | HubSpot CRM | [[singular/CRM]] |
  | Singularidade (marketplace) | active | TBD | @github:pedrormc/Singularidade |
  | Singular-IA | on-hold | Python + LangChain | @github:pedrormc/singular-ia |

  ## Freelancer / Clientes
  | Projeto | Cliente | Status | Stack | Vault / Repo |
  |---|---|---|---|---|
  | Mel (proteção animal) | Eduardo Dib / Atlantis | active Fase 1 | React 19 + Vite 6 + Express + PG + Vercel | [[Clientes/Eduardo Dib]] / @github:pedrormc/Mel |
  | FireDash (bombeiros) | — | base de Mel | React 19 + Vite 6 | @github:pedrormc/FireDash |
  | Bombeiros App | — | active | [[Projetos/Bombeiros]] | — |
  | Glória (chatbot violência) | — | design | Chatwoot + IA | [[Projetos/Glória]] |
  | Crypto Card | — | planning | White label | [[Projetos/Crypto Card]] |
  | PWR Coffee | — | active | Next.js 15 + Shopify Headless | @github:pedrormc/pwrcff |
  | PixCoffee (IoT) | — | active | Firebase + Vercel dashboard + Dolce Gusto | @github:pedrormc/PixCoffee |
  | SoCute (disparo massa) | — | active | @github:pedrormc/imagens-campanhas-SoCute | [[Clientes/SoCute]] |
  | HOF Masters | — | active | — | [[Clientes/HOF MASTERS]] |
  | Bedran | — | active | — | [[Clientes/Bedran]] |
  | ADenergia | — | active | — | [[Clientes/ADenergia]] / @github:pedrormc/ADenergia |

  ## Paralelo
  | Projeto | Status | Stack | Vault / Repo |
  |---|---|---|---|
  | F.D.S. (fast deal system) | active | WhatsApp audio relay | @github:pedrormc/F.D.S---fast-deal-system |

  ## Pessoal / Meta
  | Projeto | Status | Stack | Vault / Repo |
  |---|---|---|---|
  | **TRIFORCE Foundation** | **in-progress** | **bash + MCPVault + Gstack + RuFlo** | **@github:pedrormc/TRIFORCE** |
  | TRIFORCE methodology | active | markdown + scripts | @github:pedrormc/TRIFORCE |
  | claude-code-toolkit | active | agents + skills + rules + hooks | @github:pedrormc/claude-code-toolkit |
  | Zel (WhatsApp channel) | active | Bun + Express + Evolution API | @github:pedrormc/zel |
  | obsidiano (vault) | active | Obsidian + MCPVault | @github:pedrormc/obsidiano |

  ---

  > **Convenção:** quando um novo projeto começa, adicionar linha aqui. Categoria é uma das 4 (pessoal/paralelo/freelancer/singular). Estado é active / on-hold / archived / planning / in-progress.

  *[Registrado por: DESKTOP — 2026-04-09]*
  ```

- [ ] **Step 12.4: Run smoke — expect PASS**

### Task 13: Commit Chunk 1 state (before INDEX)

- [ ] **Step 13.1: Verify all 6 seeds + CLAUDE.md loader present**

  ```bash
  cd ~/Documents/obsidiano
  ls -la Claude/ Claude/memory/ Claude/personas/
  ```

  Expected: 6 `.md` files in `memory/`, 1 `zel.md` in `personas/`, 1 `CLAUDE.md` in `Claude/`, 1 loader at root.

- [ ] **Step 13.2: Run all Chunk 1 smoke tests**

  ```bash
  for i in 3 4 5 6 7 8 9 10 11 12; do
    /tmp/smoke-task$i.sh || echo "❌ task $i failed"
  done
  ```

  Expected: 10 lines, all `✅ Task N smoke passed`.

- [ ] **Step 13.3: Stage and commit**

  ```bash
  cd ~/Documents/obsidiano
  git add CLAUDE.md Claude/
  git status
  git commit -m "refactor: split vault CLAUDE.md + seed Claude/memory brain

  Splits the single Zel-specific CLAUDE.md into:
  - CLAUDE.md (loader, ~20 lines)
  - Claude/CLAUDE.md (generic standing orders)
  - Claude/personas/zel.md (extracted Zel persona)

  Creates Claude/memory/ with 6 populated seed files:
  user.md, preferences.md, active.md, decisions.md,
  people.md, projects.md. Data extracted from existing
  auto-memory + Claudete.md.

  No hooks yet — those come in Chunk 2.
  No INDEX.md yet — that comes in Task 14.

  Part of Foundation sub-project A+B. Spec at
  TRIFORCE/docs/superpowers/specs/2026-04-09-foundation-design.md.

  *[Registrado por: DESKTOP — 2026-04-09]*"
  ```

### Task 14: Write initial INDEX.md

**Files:**
- Create: `obsidiano/Claude/memory/INDEX.md`

- [ ] **Step 14.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task14.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/Documents/obsidiano/Claude/memory/INDEX.md
  test -f "$F"
  grep -q "auto_generated: true" "$F"
  grep -q "Claude Memory" "$F"
  grep -q "Auto-Memory" "$F"
  grep -q "Vault Manual" "$F"
  echo "✅ Task 14 smoke passed"
  EOF
  chmod +x /tmp/smoke-task14.sh
  ```

- [ ] **Step 14.2: Run smoke — expect FAIL**

- [ ] **Step 14.3: Write initial `INDEX.md`**

  File content (this is the "seed" version; the regen script in Chunk 2 will replace with a fresh one):

  ```markdown
  ---
  name: Memory Master Index
  description: Mapa unificado dos 3 sistemas de memória (auto + claude + vault)
  type: reference
  scope: global
  source: claude-memory
  last_updated: 2026-04-09
  auto_generated: true
  ---

  > **NÃO EDITAR MANUALMENTE.** Gerado por `~/.claude/scripts/memory-index-rebuild.sh`.
  > Última geração inicial: 2026-04-09 (DESKTOP, Task 14 do Foundation plan)

  ## 🧠 Claude Memory (global, distilled)

  | Arquivo | Tipo | Última atualização |
  |---|---|---|
  | [active.md](active.md) | active | 2026-04-09 |
  | [decisions.md](decisions.md) | decisions | 2026-04-09 |
  | [people.md](people.md) | people | 2026-04-09 |
  | [preferences.md](preferences.md) | preferences | 2026-04-09 |
  | [projects.md](projects.md) | projects | 2026-04-09 |
  | [user.md](user.md) | user | 2026-04-09 |

  ## 🤖 Auto-Memory (per-project, harness)

  Localização: `~/.claude/projects/<cwd>/memory/`

  | Projeto (cwd) | Arquivos | Link |
  |---|---|---|
  | `C--Users-teste` | (seed inicial — será listado pelo regen script) | `@~/.claude/projects/C--Users-teste/memory/` |

  > Esta seção é parcial. O script `memory-index-rebuild.sh` (Task 21) preenche com `find`.

  ## 📚 Vault Manual (Obsidian, humano)

  | Pasta | Conteúdo | Link |
  |---|---|---|
  | [singular/](../../singular/) | Empresa, CTO, vendas, Notas Black | core business |
  | [Projetos/](../../Projetos/) | Bombeiros, Glória, Crypto Card, Mili | paralelo |
  | [Clientes/](../../Clientes/) | HOF Masters, Bedran, SoCute, ADenergia, Eduardo Dib | freelancer |
  | [Pessoal/](../../Pessoal/) | Currículo, projetos pessoais | pessoal |
  | [Jarvis/](../../Jarvis/) | Hub agentes IA + automações | tech |
  | [Reuniões/](../../Reuniões/) | Pautas, devolutivas, recaps | meetings |
  | [Diário/](../../Diário/) | Daily notes | journal |
  | [Tech & IA/](../../Tech%20%26%20IA/) | Estudos e referências técnicas | tech |

  ## 🔗 Cross-references

  - `Claude/memory/people.md` → [[Clientes/Eduardo Dib]], [[Clientes/Bedran]], [[Clientes/HOF MASTERS]]
  - `Claude/memory/projects.md` → [[Projetos/Mili]], [[Clientes/Eduardo Dib]], @github:pedrormc/Mel, @github:pedrormc/TRIFORCE
  - `Claude/memory/active.md` → [[Projetos/Mili]], [[Clientes/Eduardo Dib]]

  ---

  *[Registrado por: DESKTOP — 2026-04-09]*
  ```

- [ ] **Step 14.4: Run smoke — expect PASS**

- [ ] **Step 14.5: Commit INDEX.md separately (pra log git ficar legível)**

  ```bash
  cd ~/Documents/obsidiano
  git add Claude/memory/INDEX.md
  git commit -m "feat: seed Claude/memory/INDEX.md (manual initial version)

  Initial INDEX.md populated manually as Task 14 of Foundation plan.
  Will be replaced by memory-index-rebuild.sh auto-regeneration in Chunk 2.

  *[Registrado por: DESKTOP — 2026-04-09]*"
  ```

### Task 15: Merge Chunk 1 feature branch to main in vault

- [ ] **Step 15.1: Run E2E validation of vault refactor (manual read-back)**

  ```bash
  cd ~/Documents/obsidiano
  cat CLAUDE.md                # verify loader
  cat Claude/CLAUDE.md | head -20      # verify generic standing orders
  cat Claude/personas/zel.md | head -10  # verify Zel persona
  ls Claude/memory/            # verify 7 files: 6 seeds + INDEX
  ```

  Expected visual confirmation: each file contains what task N produced.

- [ ] **Step 15.2: Merge to main**

  ```bash
  git checkout main
  git merge --no-ff feat/foundation-claude-split -m "merge: Foundation Chunk 1 — vault refactor + memory seeds

  Includes Tasks 1-14 of the Foundation implementation plan.
  Vault is now in the post-Chunk-1 state:
  - CLAUDE.md is a loader
  - Claude/CLAUDE.md has generic standing orders
  - Claude/personas/zel.md has the Zel persona
  - Claude/memory/ has 6 seeds + INDEX.md populated

  No hooks or scripts yet. Those come in Chunk 2.

  Merges feat/foundation-claude-split into main."
  git branch -d feat/foundation-claude-split
  ```

- [ ] **Step 15.3: DO NOT push yet** — push happens after Chunk 2 to keep remote consistent.

---

> **End of Chunk 1.** At this point the vault is in its target state structurally. No hooks or scripts exist yet, so the session-start hook is NOT active — Claude Code sessions do not yet auto-load memory. This is fine for Chunk 1. Chunk 2 wires the hooks.

---

## Chunk 2: Desktop Hooks & Scripts

> Goal of chunk: create all 4 hooks and all 7 scripts, wire them into `~/.claude/settings.json`, verify each component with smoke tests.

### Task 16: Create `~/.claude/hooks/session-start-memory-loader.sh`

**Files:**
- Create: `~/.claude/hooks/session-start-memory-loader.sh`

- [ ] **Step 16.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task16.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/.claude/hooks/session-start-memory-loader.sh
  test -x "$F"
  # Run hook and capture output
  OUT=$("$F" 2>&1)
  echo "$OUT" | grep -q "STANDING ORDERS"
  echo "$OUT" | grep -q "MEMORY UNIFICADA"
  echo "$OUT" | grep -q "Claude/memory"
  # Must exit 0 even if files missing
  "$F" >/dev/null 2>&1
  echo "✅ Task 16 smoke passed"
  EOF
  chmod +x /tmp/smoke-task16.sh
  ```

- [ ] **Step 16.2: Run smoke — expect FAIL**

  Expected: hook doesn't exist.

- [ ] **Step 16.3: Create hook script**

  File content (refer to spec §7.2 for design):

  ```bash
  #!/usr/bin/env bash
  # ~/.claude/hooks/session-start-memory-loader.sh
  # Loads unified memory (vault + auto-memory) into session context.
  # Failure-tolerant: always exits 0. See spec §7.2.

  set -uo pipefail

  LOG=~/.claude/hooks/session-start-memory-loader.log

  log_err() {
    echo "[$(date -Iseconds)] $1" >> "$LOG"
  }

  safe_cat() {
    if [ -f "$1" ]; then
      cat "$1"
    else
      echo "<!-- ARQUIVO AUSENTE: $1 -->"
      log_err "missing: $1"
    fi
  }

  # Detect OS to locate vault
  case "$OSTYPE" in
    msys*|cygwin*|win32*)
      VAULT="$HOME/Documents/obsidiano"
      ;;
    linux*)
      if [ -d "/data/data/com.termux" ]; then
        VAULT="$HOME/obsidiano"
      else
        VAULT="$HOME/obsidiano"
      fi
      ;;
    *)
      VAULT="$HOME/Documents/obsidiano"
      ;;
  esac

  # Check vault reachability
  if [ ! -d "$VAULT/Claude" ]; then
    cat <<DEGRADED
  === ⚠️ MEMORY LOADER DEGRADED — partial context only ===
  Reason: vault Claude/ directory not found at $VAULT/Claude
  Full log: $LOG
  DEGRADED
    log_err "vault unreachable: $VAULT/Claude"
    exit 0
  fi

  # Compute cwd hash for auto-memory lookup
  CWD_HASH=$(pwd | sed 's/\//-/g; s/://g')
  PROJECT_MEM="$HOME/.claude/projects/$CWD_HASH/memory"

  cat <<HEADER
  === 🧠 MEMÓRIA UNIFICADA (carregada em $(date +%Y-%m-%dT%H:%M:%S)) ===

  > Fontes: vault Obsidian ($VAULT) + auto-memory do harness ($PROJECT_MEM)
  > Edições devem usar memory-update.sh, NÃO Edit direto.

  === 📜 STANDING ORDERS (Claude/CLAUDE.md) ===
  HEADER

  safe_cat "$VAULT/Claude/CLAUDE.md"

  echo ""
  echo "=== 🗺️ INDEX MEMÓRIA UNIFICADA (Claude/memory/INDEX.md) ==="
  safe_cat "$VAULT/Claude/memory/INDEX.md"

  echo ""
  echo "=== 🧠 CLAUDE MEMORY (global, 6 arquivos) ==="
  for f in user preferences active decisions people projects; do
    echo ""
    echo "--- Claude/memory/$f.md ---"
    safe_cat "$VAULT/Claude/memory/$f.md"
  done

  echo ""
  echo "=== 🤖 AUTO-MEMORY (cwd: $(pwd)) ==="
  if [ -d "$PROJECT_MEM" ]; then
    for f in "$PROJECT_MEM"/*.md; do
      [ -f "$f" ] || continue
      echo ""
      echo "--- $(basename "$f") ---"
      cat "$f"
    done
  else
    echo "(sem auto-memory pra este cwd ainda)"
  fi

  echo ""
  echo "=== FIM DA MEMÓRIA UNIFICADA ==="
  exit 0
  ```

- [ ] **Step 16.4: Make executable and run smoke — expect PASS**

  ```bash
  mkdir -p ~/.claude/hooks
  chmod +x ~/.claude/hooks/session-start-memory-loader.sh
  /tmp/smoke-task16.sh
  ```

### Task 17: Create `~/.claude/hooks/post-edit-memory-validator.sh`

**Files:**
- Create: `~/.claude/hooks/post-edit-memory-validator.sh`

- [ ] **Step 17.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task17.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/.claude/hooks/post-edit-memory-validator.sh
  test -x "$F"
  # Simulate a hook event with a non-memory path — should be silent exit 0
  echo '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/not-memory.md"}}' | "$F"
  echo "✅ Task 17 smoke passed"
  EOF
  chmod +x /tmp/smoke-task17.sh
  ```

- [ ] **Step 17.2: Run smoke — expect FAIL**

- [ ] **Step 17.3: Create hook script**

  File content (spec §7.3):

  ```bash
  #!/usr/bin/env bash
  # ~/.claude/hooks/post-edit-memory-validator.sh
  # Non-blocking YAML validator for memory files. Warns on stderr, never fails.

  set -uo pipefail

  HOOK_INPUT=$(cat)
  TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
  FILE_PATH=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")

  # Filter: only act on memory files
  case "$FILE_PATH" in
    */obsidiano/Claude/memory/*.md|*/.claude/projects/*/memory/*.md)
      ;;
    *)
      exit 0
      ;;
  esac

  # Validate YAML frontmatter
  if [ -f "$FILE_PATH" ]; then
    MARKERS=$(head -20 "$FILE_PATH" | grep -c '^---$' || true)
    if [ "$MARKERS" -lt 2 ]; then
      echo "⚠️ memory-validator: YAML frontmatter missing or malformed in $FILE_PATH" >&2
    else
      # Auto-update last_updated
      TODAY=$(date +%Y-%m-%d)
      if grep -q "^last_updated:" "$FILE_PATH"; then
        sed -i.bak "s/^last_updated: .*/last_updated: $TODAY/" "$FILE_PATH" 2>/dev/null
        rm -f "$FILE_PATH.bak"
      fi
    fi

    # Auto-commit if in vault
    if echo "$FILE_PATH" | grep -q "/obsidiano/Claude/memory/"; then
      VAULT_DIR="${FILE_PATH%%/Claude/memory/*}"
      (cd "$VAULT_DIR" && git add "$FILE_PATH" && git commit -q -m "memory: auto-update $(basename "$FILE_PATH")" 2>/dev/null) || true
    fi
  fi

  exit 0
  ```

- [ ] **Step 17.4: Make executable and run smoke — expect PASS**

  ```bash
  chmod +x ~/.claude/hooks/post-edit-memory-validator.sh
  /tmp/smoke-task17.sh
  ```

### Task 18: Create `~/.claude/hooks/session-end-memory-writer.sh`

**Files:**
- Create: `~/.claude/hooks/session-end-memory-writer.sh`

- [ ] **Step 18.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task18.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/.claude/hooks/session-end-memory-writer.sh
  test -x "$F"
  "$F" 2>&1 | head -5    # should not error
  echo "✅ Task 18 smoke passed"
  EOF
  chmod +x /tmp/smoke-task18.sh
  ```

- [ ] **Step 18.2: Run smoke — expect FAIL**

- [ ] **Step 18.3: Create hook script**

  File content (spec §7.4):

  ```bash
  #!/usr/bin/env bash
  # ~/.claude/hooks/session-end-memory-writer.sh
  # Updates active.md last-sessions + triggers INDEX rebuild + auto-commits.

  set -uo pipefail

  case "$OSTYPE" in
    msys*|cygwin*|win32*) VAULT="$HOME/Documents/obsidiano" ;;
    *) VAULT="$HOME/obsidiano" ;;
  esac
  [ -d "$VAULT" ] || VAULT="$HOME/Documents/obsidiano"

  ACTIVE="$VAULT/Claude/memory/active.md"
  [ -f "$ACTIVE" ] || exit 0  # no memory yet, exit clean

  TIMESTAMP=$(date +"%Y-%m-%d %H:%M")
  ENV_TAG="${CLAUDE_ENV_TAG:-DESKTOP}"
  CWD_BASE=$(basename "$(pwd)")

  # Append new session entry under "## Últimas 3 sessões" section
  LINE="- $TIMESTAMP $ENV_TAG: $CWD_BASE"
  TMP=$(mktemp)
  awk -v line="$LINE" '
    /^## Últimas 3 sessões/ {
      print
      print line
      next
    }
    { print }
  ' "$ACTIVE" > "$TMP" && mv "$TMP" "$ACTIVE"

  # Trigger INDEX rebuild in background
  if [ -x ~/.claude/scripts/memory-index-rebuild.sh ]; then
    (~/.claude/scripts/memory-index-rebuild.sh &) >/dev/null 2>&1
  fi

  # Auto-commit silently (no push)
  (cd "$VAULT" && git add Claude/memory/active.md Claude/memory/INDEX.md 2>/dev/null && \
    git commit -q -m "auto: session end ${ENV_TAG} ${TIMESTAMP}" 2>/dev/null) || true

  exit 0
  ```

- [ ] **Step 18.4: Make executable and run smoke — expect PASS**

  ```bash
  chmod +x ~/.claude/hooks/session-end-memory-writer.sh
  /tmp/smoke-task18.sh
  ```

### Task 19: Create `~/.claude/hooks/save-session-vault-mirror.sh`

**Files:**
- Create: `~/.claude/hooks/save-session-vault-mirror.sh`

- [ ] **Step 19.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task19.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/.claude/hooks/save-session-vault-mirror.sh
  test -x "$F"
  "$F" 2>&1 || true  # should not crash even if no session file exists
  echo "✅ Task 19 smoke passed"
  EOF
  chmod +x /tmp/smoke-task19.sh
  ```

- [ ] **Step 19.2: Run smoke — expect FAIL**

- [ ] **Step 19.3: Create hook script**

  File content (spec §7.5):

  ```bash
  #!/usr/bin/env bash
  # ~/.claude/hooks/save-session-vault-mirror.sh
  # Mirrors ~/.claude/sessions/*-session.tmp to vault/Claude/sessions/*.md

  set -uo pipefail

  case "$OSTYPE" in
    msys*|cygwin*|win32*) VAULT="$HOME/Documents/obsidiano/Claude/sessions" ;;
    *) VAULT="$HOME/obsidiano/Claude/sessions" ;;
  esac

  mkdir -p "$VAULT" 2>/dev/null || true

  SOURCE_DIR="$HOME/.claude/sessions"
  LATEST=$(ls -t "$SOURCE_DIR"/*-session.tmp 2>/dev/null | head -1 || true)

  if [ -n "$LATEST" ] && [ -f "$LATEST" ]; then
    DEST="$VAULT/$(basename "$LATEST" .tmp).md"
    cp "$LATEST" "$DEST"
  fi

  exit 0
  ```

- [ ] **Step 19.4: Make executable and run smoke — expect PASS**

  ```bash
  chmod +x ~/.claude/hooks/save-session-vault-mirror.sh
  /tmp/smoke-task19.sh
  ```

### Task 20: Create `~/.claude/scripts/memory-update.sh`

**Files:**
- Create: `~/.claude/scripts/memory-update.sh`

- [ ] **Step 20.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task20.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/.claude/scripts/memory-update.sh
  test -x "$F"
  # Invoke with no args — should print usage and exit 1
  "$F" 2>&1 | grep -q "Uso:" || exit 1
  echo "✅ Task 20 smoke passed"
  EOF
  chmod +x /tmp/smoke-task20.sh
  ```

- [ ] **Step 20.2: Run smoke — expect FAIL**

- [ ] **Step 20.3: Create script (spec §5.5)**

  ```bash
  #!/usr/bin/env bash
  # ~/.claude/scripts/memory-update.sh
  # Unified API for writing to any of the 3 memory systems.

  set -euo pipefail

  if [ $# -lt 2 ]; then
    echo "Uso: memory-update {auto|claude|vault} <args>" >&2
    echo "  auto <type> <content>           - writes to auto-memory (per-cwd)" >&2
    echo "  claude <file> <content>         - writes to Claude/memory/ (vault)" >&2
    echo "  vault <relative-path> <content> - writes to vault humano" >&2
    exit 1
  fi

  SYSTEM="$1"; shift

  case "$OSTYPE" in
    msys*|cygwin*|win32*) VAULT="$HOME/Documents/obsidiano" ;;
    *) VAULT="$HOME/obsidiano" ;;
  esac
  [ -d "$VAULT" ] || VAULT="$HOME/Documents/obsidiano"

  case "$SYSTEM" in
    auto)
      TYPE="$1"; CONTENT="$2"
      CWD_HASH=$(pwd | sed 's/\//-/g; s/://g')
      DEST="$HOME/.claude/projects/$CWD_HASH/memory/${TYPE}_$(date +%s).md"
      mkdir -p "$(dirname "$DEST")"
      cat > "$DEST" <<EOF
  ---
  name: $TYPE
  description: Auto-update via memory-update.sh
  type: $TYPE
  scope: per-cwd
  source: auto-memory
  last_updated: $(date +%Y-%m-%d)
  ---

  $CONTENT
  EOF
      echo "wrote: $DEST"
      ;;
    claude)
      FILE="$1"; CONTENT="$2"
      DEST="$VAULT/Claude/memory/$FILE"
      [ -f "$DEST" ] || { echo "file not found: $DEST" >&2; exit 1; }
      case "$FILE" in
        decisions.md|people.md)
          printf "\n%s\n" "$CONTENT" >> "$DEST"
          ;;
        *)
          # Replace mode (write full content)
          printf "%s" "$CONTENT" > "$DEST"
          ;;
      esac
      (cd "$VAULT" && git add "Claude/memory/$FILE" && git commit -q -m "memory: $FILE update" 2>/dev/null) || true
      echo "wrote: $DEST"
      ;;
    vault)
      FILE="$1"; CONTENT="$2"
      DEST="$VAULT/$FILE"
      mkdir -p "$(dirname "$DEST")"
      printf "\n%s\n" "$CONTENT" >> "$DEST"
      (cd "$VAULT" && git add "$FILE" && git commit -q -m "vault: $FILE update" 2>/dev/null) || true
      echo "wrote: $DEST"
      ;;
    *)
      echo "unknown system: $SYSTEM (expected auto|claude|vault)" >&2
      exit 1
      ;;
  esac

  exit 0
  ```

- [ ] **Step 20.4: Run smoke — expect PASS**

  ```bash
  mkdir -p ~/.claude/scripts
  chmod +x ~/.claude/scripts/memory-update.sh
  /tmp/smoke-task20.sh
  ```

### Task 21: Create `~/.claude/scripts/memory-index-rebuild.sh`

**Files:**
- Create: `~/.claude/scripts/memory-index-rebuild.sh`

- [ ] **Step 21.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task21.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/.claude/scripts/memory-index-rebuild.sh
  test -x "$F"
  # Back up current INDEX and re-generate
  cp ~/Documents/obsidiano/Claude/memory/INDEX.md /tmp/INDEX.bak
  "$F"
  grep -q "auto_generated: true" ~/Documents/obsidiano/Claude/memory/INDEX.md
  grep -q "Claude Memory" ~/Documents/obsidiano/Claude/memory/INDEX.md
  echo "✅ Task 21 smoke passed"
  EOF
  chmod +x /tmp/smoke-task21.sh
  ```

- [ ] **Step 21.2: Run smoke — expect FAIL**

- [ ] **Step 21.3: Create script**

  ```bash
  #!/usr/bin/env bash
  # ~/.claude/scripts/memory-index-rebuild.sh
  # Regenerates Claude/memory/INDEX.md from live filesystem state.

  set -uo pipefail

  case "$OSTYPE" in
    msys*|cygwin*|win32*) VAULT="$HOME/Documents/obsidiano" ;;
    *) VAULT="$HOME/obsidiano" ;;
  esac
  [ -d "$VAULT/Claude/memory" ] || exit 0

  INDEX="$VAULT/Claude/memory/INDEX.md"
  TODAY=$(date +%Y-%m-%d)
  NOW_ISO=$(date -Iseconds)
  ENV_TAG="${CLAUDE_ENV_TAG:-DESKTOP}"
  PROJECTS_DIR="$HOME/.claude/projects"

  {
    cat <<EOF
  ---
  name: Memory Master Index
  description: Mapa unificado dos 3 sistemas de memória (auto + claude + vault)
  type: reference
  scope: global
  source: claude-memory
  last_updated: $TODAY
  auto_generated: true
  ---

  > **NÃO EDITAR MANUALMENTE.** Gerado por \`~/.claude/scripts/memory-index-rebuild.sh\`.
  > Última geração: $NOW_ISO ($ENV_TAG)

  ## 🧠 Claude Memory (global, distilled)

  | Arquivo | Tipo | Última atualização |
  |---|---|---|
  EOF

    for f in user preferences active decisions people projects; do
      FILE="$VAULT/Claude/memory/$f.md"
      if [ -f "$FILE" ]; then
        TYPE=$(grep '^type:' "$FILE" | head -1 | awk '{print $2}')
        LAST=$(grep '^last_updated:' "$FILE" | head -1 | awk '{print $2}')
        echo "| [$f.md]($f.md) | $TYPE | $LAST |"
      fi
    done

    cat <<EOF

  ## 🤖 Auto-Memory (per-project, harness)

  Localização: \`~/.claude/projects/<cwd>/memory/\`

  | Projeto (cwd) | Arquivos | Última atividade |
  |---|---|---|
  EOF

    if [ -d "$PROJECTS_DIR" ]; then
      for proj_dir in "$PROJECTS_DIR"/*/; do
        [ -d "$proj_dir/memory" ] || continue
        NAME=$(basename "$proj_dir")
        COUNT=$(find "$proj_dir/memory" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l)
        LATEST=$(ls -t "$proj_dir/memory"/*.md 2>/dev/null | head -1)
        if [ -n "$LATEST" ]; then
          MTIME=$(stat -c '%y' "$LATEST" 2>/dev/null | cut -d' ' -f1 || echo "-")
          echo "| \`$NAME\` | $COUNT | $MTIME |"
        fi
      done
    fi

    cat <<EOF

  ## 📚 Vault Manual (Obsidian, humano)

  | Pasta | Conteúdo |
  |---|---|
  EOF

    # List vault top-level folders (exclude Claude/, .obsidian/, .git/)
    for dir in "$VAULT"/*/; do
      NAME=$(basename "$dir")
      case "$NAME" in
        Claude|.obsidian|.git) continue ;;
      esac
      [ -d "$dir" ] || continue
      FILE_COUNT=$(find "$dir" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l)
      echo "| [$NAME/](../../$NAME/) | $FILE_COUNT arquivos .md |"
    done

    cat <<EOF

  ---

  *[Registrado por: $ENV_TAG — $TODAY]*
  EOF
  } > "$INDEX.tmp" && mv "$INDEX.tmp" "$INDEX"

  exit 0
  ```

- [ ] **Step 21.4: Make executable and run smoke — expect PASS**

  ```bash
  chmod +x ~/.claude/scripts/memory-index-rebuild.sh
  /tmp/smoke-task21.sh
  ```

### Task 22: Create `~/.claude/scripts/memory-auto-promote.sh`

**Files:**
- Create: `~/.claude/scripts/memory-auto-promote.sh`
- Create: `~/.claude/config/auto-promote.yaml`

- [ ] **Step 22.1: Write smoke test (empty-state behavior)**

  ```bash
  cat > /tmp/smoke-task22.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/.claude/scripts/memory-auto-promote.sh
  C=~/.claude/config/auto-promote.yaml
  test -x "$F"
  test -f "$C"
  # Run on empty state — should exit 0 and append heartbeat line
  BEFORE=$(wc -l < ~/Documents/obsidiano/Claude/memory/.promotion-log.jsonl 2>/dev/null || echo 0)
  "$F"
  AFTER=$(wc -l < ~/Documents/obsidiano/Claude/memory/.promotion-log.jsonl 2>/dev/null || echo 0)
  test "$AFTER" -gt "$BEFORE"  # at least 1 heartbeat line
  tail -1 ~/Documents/obsidiano/Claude/memory/.promotion-log.jsonl | grep -q "cron-run"
  echo "✅ Task 22 smoke passed"
  EOF
  chmod +x /tmp/smoke-task22.sh
  ```

- [ ] **Step 22.2: Run smoke — expect FAIL**

- [ ] **Step 22.3: Create config file**

  ```bash
  mkdir -p ~/.claude/config
  ```

  File `~/.claude/config/auto-promote.yaml`:

  ```yaml
  # Foundation auto-promote thresholds — Balanced preset
  # Edit values here to tune promotion behavior. No code redeploy needed.

  filters:
    min_projects: 3
    min_age_days: 7
    similarity_threshold: 0.75

  max_per_run: 5

  target_mapping:
    feedback: preferences.md
    reference: projects.md  # or people.md if person-shaped (resolved by script heuristic)

  block_list_patterns:
    - 'R\$|USD|EUR|\$\d'
    - 'password|token|api_key|secret|\.env|credential'
    - '[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}'
    - '\+?55 ?\d{2} ?\d{4,5}-?\d{4}'
    - '\d{3}\.\d{3}\.\d{3}-\d{2}'
  ```

- [ ] **Step 22.4: Create promote script (core skeleton — real Jaccard logic + block-list + promotion)**

  ```bash
  #!/usr/bin/env bash
  # ~/.claude/scripts/memory-auto-promote.sh
  # Daily cron — promote cross-project patterns with safety nets (spec §7.6)

  set -uo pipefail

  case "$OSTYPE" in
    msys*|cygwin*|win32*) VAULT="$HOME/Documents/obsidiano" ;;
    *) VAULT="$HOME/obsidiano" ;;
  esac
  [ -d "$VAULT" ] || VAULT="$HOME/Documents/obsidiano"

  PROJECTS_DIR="$HOME/.claude/projects"
  LOG="$VAULT/Claude/memory/.promotion-log.jsonl"
  TIMESTAMP=$(date -Iseconds)

  # Defaults (overridden by yaml if present)
  MIN_PROJECTS=3
  MIN_AGE_DAYS=7
  SIMILARITY_THRESHOLD=0.75
  MAX_PER_RUN=5

  # Parse YAML config if present (simple grep — no full yaml parser dep)
  CONFIG="$HOME/.claude/config/auto-promote.yaml"
  if [ -f "$CONFIG" ]; then
    MIN_PROJECTS=$(grep "min_projects:" "$CONFIG" | awk '{print $2}')
    MIN_AGE_DAYS=$(grep "min_age_days:" "$CONFIG" | awk '{print $2}')
    SIMILARITY_THRESHOLD=$(grep "similarity_threshold:" "$CONFIG" | awk '{print $2}')
    MAX_PER_RUN=$(grep "max_per_run:" "$CONFIG" | awk '{print $2}')
  fi

  # Normalize content for Jaccard (strip frontmatter, lowercase, strip stopwords)
  normalize() {
    awk '/^---$/{c++; next} c>=2 {print}' "$1" | \
      tr '[:upper:]' '[:lower:]' | \
      tr -d '[:punct:]' | \
      tr -s '[:space:]' '\n' | \
      grep -vE '^(de|a|o|que|e|do|da|em|um|para|é|com|não|uma|os|no|se|na|por|mais|as|dos|como|mas|foi|ao|ele|das|à|seu|sua)$' | \
      grep -v '^$' | \
      sort -u
  }

  jaccard() {
    local file_a="$1"
    local file_b="$2"
    local tmp_a=$(mktemp)
    local tmp_b=$(mktemp)
    normalize "$file_a" > "$tmp_a"
    normalize "$file_b" > "$tmp_b"

    local a_count=$(wc -l < "$tmp_a")
    local b_count=$(wc -l < "$tmp_b")

    # Exclude if either file is too long (>500 tokens)
    if [ "$a_count" -gt 500 ] || [ "$b_count" -gt 500 ]; then
      rm -f "$tmp_a" "$tmp_b"
      echo "0.0"
      return
    fi

    local intersection=$(comm -12 "$tmp_a" "$tmp_b" | wc -l)
    local union=$(sort -u "$tmp_a" "$tmp_b" | wc -l)

    rm -f "$tmp_a" "$tmp_b"

    if [ "$union" -eq 0 ]; then
      echo "0.0"
    else
      # Compute intersection/union using awk (bash can't do floats)
      awk -v i="$intersection" -v u="$union" 'BEGIN { printf "%.4f\n", i/u }'
    fi
  }

  block_listed() {
    local content="$1"
    if [ -f "$CONFIG" ]; then
      local patterns=$(grep -A20 "block_list_patterns:" "$CONFIG" | grep "^\s*-" | sed "s/^\s*- '\(.*\)'$/\1/")
      while IFS= read -r pattern; do
        [ -z "$pattern" ] && continue
        if echo "$content" | grep -qiE "$pattern" 2>/dev/null; then
          return 0  # is block-listed
        fi
      done <<< "$patterns"
    fi
    return 1  # not block-listed
  }

  # Heartbeat for empty-state (Day 1 safe)
  heartbeat_and_exit() {
    local promoted="$1"
    local eligible="$2"
    local reason="$3"
    mkdir -p "$(dirname "$LOG")"
    echo "{\"timestamp\":\"$TIMESTAMP\",\"action\":\"cron-run\",\"promoted\":$promoted,\"eligible\":$eligible,\"reason\":\"$reason\"}" >> "$LOG"
    exit 0
  }

  # Collect candidates: feedback_*.md and user_*.md older than MIN_AGE_DAYS
  CANDIDATES=()
  if [ -d "$PROJECTS_DIR" ]; then
    while IFS= read -r f; do
      # Age check
      AGE_DAYS=$(( ( $(date +%s) - $(stat -c '%Y' "$f" 2>/dev/null || echo 0) ) / 86400 ))
      [ "$AGE_DAYS" -ge "$MIN_AGE_DAYS" ] && CANDIDATES+=("$f")
    done < <(find "$PROJECTS_DIR" -name "feedback_*.md" -o -name "user_*.md" 2>/dev/null)
  fi

  if [ "${#CANDIDATES[@]}" -lt "$MIN_PROJECTS" ]; then
    heartbeat_and_exit 0 "${#CANDIDATES[@]}" "insufficient_candidates"
  fi

  # Group by similarity (O(n²) — fine for small candidate pools)
  declare -A GROUPS
  declare -A GROUP_FILES
  GROUP_ID=0

  for file_a in "${CANDIDATES[@]}"; do
    ASSIGNED=""
    for gid in "${!GROUPS[@]}"; do
      # Compare against first file in group
      first_file="${GROUP_FILES[$gid]%% *}"
      SIM=$(jaccard "$file_a" "$first_file")
      if awk "BEGIN { exit !($SIM >= $SIMILARITY_THRESHOLD) }"; then
        GROUPS[$gid]=$((GROUPS[$gid] + 1))
        GROUP_FILES[$gid]+=" $file_a"
        ASSIGNED="yes"
        break
      fi
    done
    if [ -z "$ASSIGNED" ]; then
      GROUP_ID=$((GROUP_ID + 1))
      GROUPS[$GROUP_ID]=1
      GROUP_FILES[$GROUP_ID]="$file_a"
    fi
  done

  # Promote groups with count >= MIN_PROJECTS
  PROMOTED=0
  for gid in "${!GROUPS[@]}"; do
    [ "$PROMOTED" -ge "$MAX_PER_RUN" ] && break
    if [ "${GROUPS[$gid]}" -ge "$MIN_PROJECTS" ]; then
      files=(${GROUP_FILES[$gid]})
      first="${files[0]}"

      # Read content (skip frontmatter)
      CONTENT=$(awk '/^---$/{c++; next} c>=2' "$first")

      # Block-list check
      if block_listed "$CONTENT"; then
        continue
      fi

      # Check if already promoted (hash-based)
      HASH=$(echo "$CONTENT" | sha256sum | cut -c1-16)
      if grep -q "\"hash\":\"$HASH\"" "$LOG" 2>/dev/null; then
        continue
      fi

      ENTRY_ID="prom-$(date +%Y-%m-%d)-$HASH"

      # Determine target (feedback -> preferences.md by default)
      TARGET="$VAULT/Claude/memory/preferences.md"

      # Append promoted entry with tag
      cat >> "$TARGET" <<EOF

  ## [auto-promoted $(date +%Y-%m-%d)] from ${GROUPS[$gid]} projects
  $CONTENT

  > *auto_promoted: true | promoted_from: ${GROUPS[$gid]} projects | entry_id: $ENTRY_ID | revert: \`memory-revert $ENTRY_ID\`*
  EOF

      # Audit log
      echo "{\"timestamp\":\"$TIMESTAMP\",\"action\":\"promote\",\"target\":\"preferences.md\",\"entry_id\":\"$ENTRY_ID\",\"hash\":\"$HASH\",\"sources_count\":${GROUPS[$gid]},\"confidence\":0.80}" >> "$LOG"

      PROMOTED=$((PROMOTED + 1))
    fi
  done

  # Final heartbeat
  heartbeat_and_exit "$PROMOTED" "${#CANDIDATES[@]}" "cron_complete"
  ```

- [ ] **Step 22.5: Make executable and run smoke — expect PASS**

  ```bash
  chmod +x ~/.claude/scripts/memory-auto-promote.sh
  /tmp/smoke-task22.sh
  ```

### Task 23: Create `~/.claude/scripts/memory-revert.sh`

**Files:**
- Create: `~/.claude/scripts/memory-revert.sh`

- [ ] **Step 23.1: Write smoke test (usage only — full behavior tested in I5)**

  ```bash
  cat > /tmp/smoke-task23.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/.claude/scripts/memory-revert.sh
  test -x "$F"
  "$F" 2>&1 | grep -q "Uso:"
  echo "✅ Task 23 smoke passed"
  EOF
  chmod +x /tmp/smoke-task23.sh
  ```

- [ ] **Step 23.2: Run smoke — expect FAIL**

- [ ] **Step 23.3: Create script**

  ```bash
  #!/usr/bin/env bash
  # ~/.claude/scripts/memory-revert.sh
  # Reverts an auto-promotion by entry_id.

  set -euo pipefail

  if [ $# -lt 1 ]; then
    echo "Uso: memory-revert <entry-id>" >&2
    echo "Example: memory-revert prom-2026-04-15-abc123def456" >&2
    exit 1
  fi

  ENTRY_ID="$1"

  case "$OSTYPE" in
    msys*|cygwin*|win32*) VAULT="$HOME/Documents/obsidiano" ;;
    *) VAULT="$HOME/obsidiano" ;;
  esac

  LOG="$VAULT/Claude/memory/.promotion-log.jsonl"
  [ -f "$LOG" ] || { echo "no promotion log found at $LOG" >&2; exit 1; }

  ENTRY=$(grep "\"entry_id\":\"$ENTRY_ID\"" "$LOG" | tail -1)
  if [ -z "$ENTRY" ]; then
    echo "entry_id not found in log: $ENTRY_ID" >&2
    exit 1
  fi

  TARGET=$(echo "$ENTRY" | jq -r '.target')
  TARGET_FILE="$VAULT/Claude/memory/$TARGET"

  if [ ! -f "$TARGET_FILE" ]; then
    echo "target file missing: $TARGET_FILE" >&2
    exit 1
  fi

  # Remove lines from the "## [auto-promoted" heading matching entry_id until the next "##" or EOF
  awk -v eid="$ENTRY_ID" '
    /^## \[auto-promoted/ { in_block = 1; buffer = $0; next }
    in_block && /entry_id: '"$ENTRY_ID"'/ { in_block = 2; buffer = ""; next }
    in_block == 1 && /^##/ { in_block = 0; print buffer; print; next }
    in_block == 1 { buffer = buffer "\n" $0; next }
    in_block == 2 && /^##/ { in_block = 0; print; next }
    in_block == 2 { next }
    { print }
    END { if (in_block == 1) print buffer }
  ' "$TARGET_FILE" > "$TARGET_FILE.tmp" && mv "$TARGET_FILE.tmp" "$TARGET_FILE"

  # Mark log entry as reverted
  TIMESTAMP=$(date -Iseconds)
  echo "{\"timestamp\":\"$TIMESTAMP\",\"action\":\"revert\",\"entry_id\":\"$ENTRY_ID\",\"reverted\":true}" >> "$LOG"

  # Commit
  (cd "$VAULT" && git add "Claude/memory/$TARGET" "Claude/memory/.promotion-log.jsonl" && \
    git commit -q -m "revert: memory promotion $ENTRY_ID") || true

  echo "✅ reverted: $ENTRY_ID from $TARGET"
  exit 0
  ```

- [ ] **Step 23.4: Make executable and run smoke — expect PASS**

  ```bash
  chmod +x ~/.claude/scripts/memory-revert.sh
  /tmp/smoke-task23.sh
  ```

### Task 24: Wire hooks into `~/.claude/settings.json`

**Files:**
- Modify: `~/.claude/settings.json`

- [ ] **Step 24.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task24.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/.claude/settings.json
  jq -e '.hooks.SessionStart[0].hooks[0].command' "$F" | grep -q "session-start-memory-loader"
  jq -e '.hooks.Stop' "$F" >/dev/null
  jq -e '.disabledPlugins | any(. | test("ralph"))' "$F"
  echo "✅ Task 24 smoke passed"
  EOF
  chmod +x /tmp/smoke-task24.sh
  ```

- [ ] **Step 24.2: Run smoke — expect FAIL**

- [ ] **Step 24.3: Backup current settings.json**

  ```bash
  cp ~/.claude/settings.json ~/.claude/settings.json.pre-foundation-bak
  ```

- [ ] **Step 24.4: Edit settings.json via jq (additive, never overwrite)**

  Use jq to merge the hook entries into the existing `hooks` section (preserving any existing hooks like `claude-notify.js`):

  ```bash
  jq '.hooks.SessionStart = ([{"matcher": "*", "hooks": [{"type":"command","command":"~/.claude/hooks/session-start-memory-loader.sh"}]}] + (.hooks.SessionStart // []))' \
    ~/.claude/settings.json > /tmp/s1.json && mv /tmp/s1.json ~/.claude/settings.json

  jq '.hooks.Stop = ((.hooks.Stop // []) + [{"matcher": "*", "hooks": [{"type":"command","command":"~/.claude/hooks/session-end-memory-writer.sh"}]}])' \
    ~/.claude/settings.json > /tmp/s2.json && mv /tmp/s2.json ~/.claude/settings.json

  jq '.hooks.PostToolUse = ((.hooks.PostToolUse // []) + [
    {"matcher": "Edit|Write", "hooks": [{"type":"command","command":"~/.claude/hooks/post-edit-memory-validator.sh"}]},
    {"matcher": "Write", "hooks": [{"type":"command","command":"~/.claude/hooks/save-session-vault-mirror.sh"}]}
  ])' ~/.claude/settings.json > /tmp/s3.json && mv /tmp/s3.json ~/.claude/settings.json

  jq '.disabledPlugins = ((.disabledPlugins // []) + ["ralph-skills@1.0.0"] | unique)' \
    ~/.claude/settings.json > /tmp/s4.json && mv /tmp/s4.json ~/.claude/settings.json
  ```

- [ ] **Step 24.5: Run smoke — expect PASS**

  ```bash
  /tmp/smoke-task24.sh
  ```

- [ ] **Step 24.6: Diff against backup (visual verification)**

  ```bash
  diff ~/.claude/settings.json.pre-foundation-bak ~/.claude/settings.json | head -50
  ```

### Task 25: Integration test — SessionStart hook produces memory output

- [ ] **Step 25.1: Run hook manually**

  ```bash
  bash ~/.claude/hooks/session-start-memory-loader.sh > /tmp/loader-output.txt 2>&1
  head -30 /tmp/loader-output.txt
  wc -l /tmp/loader-output.txt
  ```

  Expected: no `<!-- ARQUIVO AUSENTE -->` markers (vault is populated). Line count > 100.

- [ ] **Step 25.2: Verify all 4 sections present**

  ```bash
  grep -c "^=== " /tmp/loader-output.txt
  ```

  Expected: `>= 4` (STANDING / INDEX / CLAUDE MEMORY / AUTO-MEMORY / FIM).

- [ ] **Step 25.3: Verify no errors in loader log**

  ```bash
  tail -20 ~/.claude/hooks/session-start-memory-loader.log 2>/dev/null || echo "(no log — good)"
  ```

### Task 26: Commit Chunk 2 (hooks + scripts)

- [ ] **Step 26.1: Verify all Chunk 2 smoke tests still pass**

  ```bash
  for i in 16 17 18 19 20 21 22 23 24; do
    /tmp/smoke-task$i.sh || echo "❌ task $i failed"
  done
  ```

  Expected: 9 green lines.

- [ ] **Step 26.2: This is Desktop-local state — NOT committed to any repo yet.**

  The hooks and scripts live in `~/.claude/` which is not a git repo. They will be committed to `claude-code-toolkit` in Chunk 3 (Task 27). For now, they are just files on disk. State verification is via smoke tests above.

---

> **End of Chunk 2.** Desktop has all hooks, all scripts, and wired settings.json. The session-start memory loader is live — the NEXT `claude` session on Desktop will auto-load the vault memory. Nothing committed to any repo yet; commit happens in Chunk 3 when we propagate via claude-code-toolkit.

---

## Chunk 3: Desktop Stack Install & Toolkit Updates

> Goal: install Gstack, create namespace rule, update claude-code-toolkit with all Foundation scripts/hooks/rules/settings so the VPS can pull and replicate in Chunk 4.

### Task 27: Install Gstack on Desktop

**Files:**
- Create: `~/.claude/skills/gstack/` (via git clone)

- [ ] **Step 27.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task27.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  test -d ~/.claude/skills/gstack
  test -f ~/.claude/skills/gstack/README.md || test -f ~/.claude/skills/gstack/SKILL.md
  # Count gstack-prefixed entries (setup should have created several)
  COUNT=$(ls ~/.claude/skills/ | grep -c "^gstack" || echo 0)
  test "$COUNT" -ge 1
  echo "✅ Task 27 smoke passed (gstack entries: $COUNT)"
  EOF
  chmod +x /tmp/smoke-task27.sh
  ```

- [ ] **Step 27.2: Run smoke — expect FAIL**

- [ ] **Step 27.3: Clone and setup Gstack**

  ```bash
  git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
  cd ~/.claude/skills/gstack && ./setup
  ```

  The setup script is interactive. Expected prompts:
  - "Install gstack for Claude Code? (y/n)" → y
  - "Enable team mode? (y/n)" → n (Foundation uses single-machine mode)

- [ ] **Step 27.4: Run smoke — expect PASS**

### Task 28: Create namespace-cheatsheet rule

**Files:**
- Create: `~/.claude/rules/common/namespace-cheatsheet.md`

- [ ] **Step 28.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task28.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  F=~/.claude/rules/common/namespace-cheatsheet.md
  test -f "$F"
  grep -q "Gstack" "$F"
  grep -q "Superpowers" "$F"
  grep -q "ralph" "$F"
  grep -q "Regra de ouro" "$F"
  echo "✅ Task 28 smoke passed"
  EOF
  chmod +x /tmp/smoke-task28.sh
  ```

- [ ] **Step 28.2: Run smoke — expect FAIL**

- [ ] **Step 28.3: Write the rule file (content from spec §6.6)**

  File `~/.claude/rules/common/namespace-cheatsheet.md`:

  ```markdown
  # Namespace Cheatsheet — Claude Code Stack

  > Quem faz o quê nos slash commands. Use isso quando houver dúvida ou colisão.

  ## Plugins instalados (4 ativos + 2 desabilitados)

  | Plugin | Origem | Comando exemplo | Status |
  |---|---|---|---|
  | ECC | everything-claude-code | `/plan`, `/tdd`, `/learn-eval` | ativo |
  | Superpowers | superpowers-marketplace | `/brainstorming`, `/writing-plans` | ativo |
  | Gstack | garrytan/gstack | `/office-hours`, `/autoplan`, `/review`, `/ship`, `/qa`, `/cso` | ativo |
  | UI/UX Pro Max | ui-ux-pro-max-skill | `/ui-ux-pro-max` | ativo |
  | Ralph | snarktank/ralph | `/prd`, `/ralph` | **desabilitado** (substituído por RuFlo) |
  | RuFlo | ruvnet/ruflo (VPS only) | n/a (workers off na Fase 1) | **desabilitado** (Phase 2) |
  | Context7 | upstash/context7 | — | não instalado (fora de escopo) |

  ## Quando usar qual (em caso de overlap)

  | Tarefa | Use |
  |---|---|
  | Brainstorm requisitos antes de codar | `superpowers:brainstorming` (rigoroso) |
  | Escrever spec depois de brainstorm | `superpowers:writing-plans` |
  | Quick plan pragmático sem spec | `gstack:/autoplan` |
  | Code review focado em padrões | `superpowers:requesting-code-review` |
  | Code review focado em deploy | `gstack:/review` |
  | Security audit completo (OWASP+STRIDE) | `gstack:/cso` |
  | Security check pre-commit | ECC `security-reviewer` agent |
  | Test E2E completo via browser | `gstack:/qa` |
  | Test E2E via Playwright headless | ECC `e2e-runner` agent |
  | Plan de implementação multi-passo | `superpowers:writing-plans` |
  | Investigação de bug | `gstack:/investigate` |
  | Retro semanal | `gstack:/retro` |
  | Salvar sessão | `ECC save-session` |
  | Retomar sessão | `ECC resume-session` |
  | Atualizar memória global (vault) | `~/.claude/scripts/memory-update.sh claude <file> <content>` |
  | Reverter auto-promoção | `~/.claude/scripts/memory-revert.sh <entry-id>` |

  ## Agents customizados (5, do claude-code-toolkit)

  | Agent | Quando |
  |---|---|
  | `api-specialist` | Express REST API, queries PG |
  | `devops-agent` | Vercel deploy, GitHub Actions, env mgmt |
  | `frontend-specialist` | React 19 + TS strict + Tailwind v4 |
  | `prompt-engineer` | Otimizar CLAUDE.md, agents, skills, rules |
  | `research-agent` | Avaliar libs antes de implementar |

  ## Regra de ouro pra escolher

  1. Se o slash command **só existe num plugin**, usa esse.
  2. Se existe em 2+, **prefere o mais específico ao caso de uso** (ver tabela acima).
  3. Se ainda em dúvida, **prefere Superpowers** (mais rigoroso, gates explícitos).
  4. Se quer velocidade > rigor, **prefere Gstack**.

  ## Quando matar (re-avaliar a cada 2 semanas)

  Skills/agents não usados em 14 dias → candidatos a disable. Rastreamento de usage via hook `PostToolUse` virá no sub-projeto D.

  *[Registrado por: DESKTOP — 2026-04-09]*
  ```

- [ ] **Step 28.4: Run smoke — expect PASS**

### Task 29: Create foundation-smoke.sh, foundation-validate.sh, foundation-uninstall.sh

**Files:**
- Create: `~/.claude/scripts/foundation-smoke.sh`
- Create: `~/.claude/scripts/foundation-validate.sh`
- Create: `~/.claude/scripts/foundation-uninstall.sh`

- [ ] **Step 29.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task29.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  test -x ~/.claude/scripts/foundation-smoke.sh
  test -x ~/.claude/scripts/foundation-validate.sh
  test -x ~/.claude/scripts/foundation-uninstall.sh
  echo "✅ Task 29 smoke passed"
  EOF
  chmod +x /tmp/smoke-task29.sh
  ```

- [ ] **Step 29.2: Run smoke — expect FAIL**

- [ ] **Step 29.3: Write `foundation-smoke.sh` (runs all 13 smoke tests from spec §8.2)**

  Content: a bash script that runs S1-S13 in sequence, prints a table with green/red per test, exits 0 if all pass, exits 1 if any fails. (Full script — ~150 lines — see spec §8.2 for exact commands.)

  ```bash
  #!/usr/bin/env bash
  # ~/.claude/scripts/foundation-smoke.sh
  # Runs all 13 Foundation smoke tests.

  set +e  # don't exit on first failure — we want to run all tests

  PASS=0
  FAIL=0
  declare -a FAILED_TESTS

  run_test() {
    local num="$1"
    local name="$2"
    local cmd="$3"
    local check="$4"

    local result=$(eval "$cmd" 2>&1)
    if echo "$result" | eval "$check" >/dev/null 2>&1; then
      echo "✅ S$num: $name"
      PASS=$((PASS + 1))
    else
      echo "❌ S$num: $name"
      FAILED_TESTS+=("S$num: $name — $result")
      FAIL=$((FAIL + 1))
    fi
  }

  run_test 1 "Vault CLAUDE.md is loader" \
    "head -5 ~/Documents/obsidiano/CLAUDE.md" \
    "grep -q 'Vault Claude Instructions'"

  run_test 2 "Claude/CLAUDE.md exists" \
    "test -f ~/Documents/obsidiano/Claude/CLAUDE.md && echo ok" \
    "grep -q ok"

  run_test 3 "Zel persona extracted" \
    "head -10 ~/Documents/obsidiano/Claude/personas/zel.md" \
    "grep -q 'Voce e o Zel'"

  run_test 4 "6 memory files populated" \
    "find ~/Documents/obsidiano/Claude/memory -maxdepth 1 -name '*.md' | wc -l" \
    "awk '{exit !(\$1 == 7)}'"

  run_test 5 "active.md has real sections" \
    "grep -c '^##' ~/Documents/obsidiano/Claude/memory/active.md" \
    "awk '{exit !(\$1 >= 3)}'"

  run_test 6 "INDEX.md auto_generated" \
    "cat ~/Documents/obsidiano/Claude/memory/INDEX.md" \
    "grep -q 'auto_generated: true'"

  run_test 7 "Gstack installed" \
    "ls ~/.claude/skills/ | grep -c gstack" \
    "awk '{exit !(\$1 >= 1)}'"

  run_test 8 "SessionStart hook exists" \
    "test -x ~/.claude/hooks/session-start-memory-loader.sh && echo ok" \
    "grep -q ok"

  run_test 9 "Session-end hook exists" \
    "test -x ~/.claude/hooks/session-end-memory-writer.sh && echo ok" \
    "grep -q ok"

  run_test 10 "Ralph disabled (jq strict)" \
    "jq -e '.disabledPlugins | any(. | test(\"ralph\"))' ~/.claude/settings.json && echo ok" \
    "grep -q ok"

  run_test 11 "Namespace rule exists" \
    "test -f ~/.claude/rules/common/namespace-cheatsheet.md && echo ok" \
    "grep -q ok"

  run_test 12 "MCPVault configured" \
    "jq -e '.mcpServers.obsidian.command' ~/.claude.json && echo ok" \
    "grep -q ok"

  run_test 13 "Auto-promote script exists" \
    "test -x ~/.claude/scripts/memory-auto-promote.sh && echo ok" \
    "grep -q ok"

  echo ""
  echo "=== Results: $PASS passed / $FAIL failed ==="

  if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "Failures:"
    for t in "${FAILED_TESTS[@]}"; do
      echo "  $t"
    done
    exit 1
  fi

  exit 0
  ```

- [ ] **Step 29.4: Write `foundation-validate.sh` (runs smoke + 7 integration tests I1-I7)**

  Similar structure but extends with integration tests I1-I7 from spec §8.3.

  ```bash
  #!/usr/bin/env bash
  # ~/.claude/scripts/foundation-validate.sh
  # Runs foundation-smoke.sh + 7 integration tests.

  set +e

  echo "=== Stage 1: Smoke tests ==="
  ~/.claude/scripts/foundation-smoke.sh || { echo "❌ Smoke failed — integration skipped"; exit 1; }

  echo ""
  echo "=== Stage 2: Integration tests ==="

  # I1: Memory loader output complete
  OUT=$(bash ~/.claude/hooks/session-start-memory-loader.sh 2>&1)
  if echo "$OUT" | grep -q "STANDING ORDERS" && ! echo "$OUT" | grep -q "ARQUIVO AUSENTE"; then
    echo "✅ I1: Memory loader output complete"
  else
    echo "❌ I1: Memory loader output missing sections or has missing files"
  fi

  # I2-I7 are interactive or require real Claude sessions — print instructions
  cat <<MANUAL

  === Stage 3: Manual integration tests (run these interactively) ===

  I2: Open \`claude\`, ask "o que você sabe sobre mim?"
      Expected: response cites CTO Singular, pedrormc, TRIFORCE, 3 envs

  I3: Edit Claude/memory/active.md via Edit tool in a claude session.
      Expected: git log -1 in vault shows auto-commit within seconds.

  I4: Run ~/.claude/scripts/test-i4-fake-data.sh (spec §8.3.1)
      Expected: promotion in preferences.md, .promotion-log.jsonl updated.

  I5: Run memory-revert with the entry_id from I4.
      Expected: entry removed from preferences.md, log marked reverted.

  I6: touch ~/Documents/obsidiano/Claude/memory/fake.md && ~/.claude/scripts/memory-index-rebuild.sh
      Expected: INDEX.md contains reference to fake.md. Cleanup: rm fake.md + re-run rebuild.

  I7: Open \`claude\`, type \`/\`.
      Expected: list includes /office-hours, /autoplan, /review, /ship, /qa, /cso
  MANUAL

  exit 0
  ```

- [ ] **Step 29.5: Write `foundation-uninstall.sh` (universal rollback)**

  ```bash
  #!/usr/bin/env bash
  # ~/.claude/scripts/foundation-uninstall.sh
  # Universal Foundation rollback — removes hooks, cron, preserves vault memory.

  set -uo pipefail

  echo "⚠️  Foundation uninstall — this will remove hooks and cron but keep vault memory."
  read -p "Continue? (yes/N): " CONFIRM
  [ "$CONFIRM" = "yes" ] || { echo "aborted"; exit 0; }

  # Restore settings.json from backup
  if [ -f ~/.claude/settings.json.pre-foundation-bak ]; then
    cp ~/.claude/settings.json.pre-foundation-bak ~/.claude/settings.json
    echo "✅ restored settings.json from backup"
  fi

  # Delete hooks
  rm -f ~/.claude/hooks/session-start-memory-loader.sh
  rm -f ~/.claude/hooks/session-end-memory-writer.sh
  rm -f ~/.claude/hooks/post-edit-memory-validator.sh
  rm -f ~/.claude/hooks/save-session-vault-mirror.sh
  echo "✅ removed hooks"

  # Delete scripts (preserve memory-update.sh and memory-revert.sh as they may be in use)
  rm -f ~/.claude/scripts/memory-auto-promote.sh
  rm -f ~/.claude/scripts/memory-index-rebuild.sh
  rm -f ~/.claude/scripts/foundation-smoke.sh
  rm -f ~/.claude/scripts/foundation-validate.sh
  echo "✅ removed scripts (kept memory-update.sh + memory-revert.sh)"

  # Delete namespace cheatsheet
  rm -f ~/.claude/rules/common/namespace-cheatsheet.md

  # Delete cron / Task Scheduler entries
  case "$OSTYPE" in
    msys*|cygwin*|win32*)
      schtasks /delete /tn "Claude Memory Auto-Promote" /f 2>/dev/null || true
      schtasks /delete /tn "Claude Memory Index Rebuild" /f 2>/dev/null || true
      echo "✅ removed Task Scheduler entries"
      ;;
    linux*)
      (crontab -l 2>/dev/null | grep -v "memory-auto-promote\|memory-index-rebuild") | crontab -
      echo "✅ removed cron entries"
      ;;
  esac

  echo ""
  echo "Foundation hooks/scripts/rules removed."
  echo "Vault memory PRESERVED at ~/Documents/obsidiano/Claude/"
  echo "To fully remove vault memory: rm -rf ~/Documents/obsidiano/Claude/"
  echo "To restore pre-Foundation state: git -C ~/Documents/obsidiano checkout pre-foundation-2026-04-09"
  exit 0
  ```

- [ ] **Step 29.6: Make all executable and run smoke — expect PASS**

  ```bash
  chmod +x ~/.claude/scripts/foundation-smoke.sh
  chmod +x ~/.claude/scripts/foundation-validate.sh
  chmod +x ~/.claude/scripts/foundation-uninstall.sh
  /tmp/smoke-task29.sh
  ```

- [ ] **Step 29.7: Run the full smoke suite for the first time**

  ```bash
  ~/.claude/scripts/foundation-smoke.sh
  ```

  Expected: 13/13 passed.

### Task 30: Propagate Desktop state to claude-code-toolkit repo

**Files:**
- Create: `claude-code-toolkit/hooks/` (new folder with 4 hooks)
- Modify: `claude-code-toolkit/scripts/` (add 7 scripts)
- Create: `claude-code-toolkit/rules/common/namespace-cheatsheet.md`
- Modify: `claude-code-toolkit/config/settings.json`
- Create: `claude-code-toolkit/templates/claude-md/zel.md`
- Modify: `claude-code-toolkit/install.sh`
- Modify: `claude-code-toolkit/README.md`

- [ ] **Step 30.1: Create feature branch in toolkit**

  ```bash
  cd ~/Desktop/claude-code-toolkit
  git checkout -b feat/foundation
  ```

- [ ] **Step 30.2: Copy hooks**

  ```bash
  mkdir -p hooks
  cp ~/.claude/hooks/session-start-memory-loader.sh hooks/
  cp ~/.claude/hooks/session-end-memory-writer.sh hooks/
  cp ~/.claude/hooks/post-edit-memory-validator.sh hooks/
  cp ~/.claude/hooks/save-session-vault-mirror.sh hooks/
  chmod +x hooks/*.sh
  ```

- [ ] **Step 30.3: Copy scripts**

  ```bash
  cp ~/.claude/scripts/memory-update.sh scripts/
  cp ~/.claude/scripts/memory-auto-promote.sh scripts/
  cp ~/.claude/scripts/memory-index-rebuild.sh scripts/
  cp ~/.claude/scripts/memory-revert.sh scripts/
  cp ~/.claude/scripts/foundation-smoke.sh scripts/
  cp ~/.claude/scripts/foundation-validate.sh scripts/
  cp ~/.claude/scripts/foundation-uninstall.sh scripts/
  chmod +x scripts/memory-*.sh scripts/foundation-*.sh
  ```

- [ ] **Step 30.4: Copy rules + config + template**

  ```bash
  cp ~/.claude/rules/common/namespace-cheatsheet.md rules/common/
  cp ~/Documents/obsidiano/Claude/personas/zel.md templates/claude-md/zel.md
  cp ~/.claude/config/auto-promote.yaml config/ 2>/dev/null || mkdir -p config && cp ~/.claude/config/auto-promote.yaml config/
  ```

- [ ] **Step 30.5: Update `config/settings.json` (sanitized version — no secrets)**

  ```bash
  # Copy the Desktop settings, strip any env-local values
  cp ~/.claude/settings.json config/settings.json.new
  jq 'del(.env) | del(.customModels)' config/settings.json.new > config/settings.json
  rm config/settings.json.new
  ```

- [ ] **Step 30.6: Extend `install.sh` with Foundation install logic**

  Open `install.sh` and add at the end (before any trailing exit):

  ```bash
  # === Foundation v1 additions ===

  # Copy hooks
  mkdir -p ~/.claude/hooks
  cp "$TOOLKIT_DIR"/hooks/*.sh ~/.claude/hooks/
  chmod +x ~/.claude/hooks/*.sh

  # Copy scripts
  mkdir -p ~/.claude/scripts
  cp "$TOOLKIT_DIR"/scripts/memory-*.sh ~/.claude/scripts/
  cp "$TOOLKIT_DIR"/scripts/foundation-*.sh ~/.claude/scripts/
  chmod +x ~/.claude/scripts/memory-*.sh ~/.claude/scripts/foundation-*.sh

  # Copy auto-promote config
  mkdir -p ~/.claude/config
  cp "$TOOLKIT_DIR"/config/auto-promote.yaml ~/.claude/config/ 2>/dev/null || true

  # Install Gstack if not present
  if [ ! -d ~/.claude/skills/gstack ]; then
    git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
    (cd ~/.claude/skills/gstack && ./setup)
  fi

  # Verify jq available
  command -v jq >/dev/null || echo "⚠️  jq not installed — smoke tests S10/S12 will fail"

  echo "✅ Foundation v1 components installed"
  ```

- [ ] **Step 30.7: Update `README.md` (Plugins + deprecations)**

  Add a new section "## Foundation v1 (2026-04-09)" and update the Plugins table:

  - Ralph: mark as deprecated with reason "substituted by RuFlo in Phase 2"
  - Gstack: add row (33 slash commands, active, single-machine mode)
  - RuFlo: add row (VPS only, workers off in Phase 1)
  - Link to the spec file in TRIFORCE repo

- [ ] **Step 30.8: Commit toolkit changes**

  ```bash
  git add hooks/ scripts/ rules/ config/ templates/ install.sh README.md
  git status
  git commit -m "feat: Foundation v1 — hooks, scripts, namespace rule, install.sh ext

  Adds Foundation infrastructure to the toolkit:
  - hooks/: 4 session lifecycle hooks (memory loader, validator,
    session-end writer, save-session mirror)
  - scripts/: 7 scripts (memory-update, memory-auto-promote,
    memory-index-rebuild, memory-revert, foundation-smoke,
    foundation-validate, foundation-uninstall)
  - rules/common/namespace-cheatsheet.md: plugin overlap guide
  - config/auto-promote.yaml: Balanced preset (3 projects / 7 days / 0.75)
  - templates/claude-md/zel.md: extracted Zel persona
  - install.sh: extended to copy hooks+scripts+config and install Gstack
  - README.md: updated Plugins table, added Foundation section

  Part of TRIFORCE Foundation sub-project A+B.
  Spec: TRIFORCE/docs/superpowers/specs/2026-04-09-foundation-design.md

  *[Registrado por: DESKTOP — 2026-04-09]*"
  ```

### Task 31: Merge toolkit feat branch to main and push

- [ ] **Step 31.1: Merge**

  ```bash
  cd ~/Desktop/claude-code-toolkit
  git checkout main
  git merge --no-ff feat/foundation -m "merge: Foundation v1 toolkit updates"
  git branch -d feat/foundation
  ```

- [ ] **Step 31.2: Push toolkit**

  ```bash
  git push origin main
  ```

- [ ] **Step 31.3: Push vault (with Chunk 1 commits)**

  ```bash
  cd ~/Documents/obsidiano
  git push origin main
  ```

---

> **End of Chunk 3.** Desktop is fully configured. claude-code-toolkit repo has all Foundation artifacts. Vault on GitHub has the refactored CLAUDE.md + memory brain. Next chunk migrates VPS.

---

## Chunk 4: VPS Migration & Zel Update

> Goal: pull toolkit + vault on VPS, install MCPVault, install Gstack, install RuFlo (workers off), update Zel's whatsapp-channel.ts to load both files, verify Zel still works end-to-end.

> **Execution context:** All commands in this chunk run on the VPS, typically via SSH from Desktop. Prefix with `ssh vps "..."` if executing from Desktop, or run directly after SSHing in.

### Task 32: VPS prerequisites verification

- [ ] **Step 32.1: SSH to VPS and check prerequisites**

  ```bash
  ssh vps  # or equivalent
  ```

  ```bash
  node --version                      # must be >= v20.0.0
  npx --version                       # must print a version
  command -v jq || sudo apt-get install -y jq
  command -v git                      # git must exist
  bun --version                       # needed for Zel
  ```

- [ ] **Step 32.2: If Node missing, install:**

  ```bash
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
  node --version
  ```

### Task 33: Pull toolkit + clone vault on VPS

**Files (on VPS):**
- `/home/claude/claude-code-toolkit/` (git pull or clone)
- `/home/claude/obsidiano/` (git clone)

- [ ] **Step 33.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task33.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  test -d /home/claude/claude-code-toolkit
  test -d /home/claude/obsidiano/Claude/memory
  test -f /home/claude/obsidiano/Claude/CLAUDE.md
  test -f /home/claude/obsidiano/Claude/personas/zel.md
  echo "✅ Task 33 smoke passed"
  EOF
  chmod +x /tmp/smoke-task33.sh
  ```

- [ ] **Step 33.2: Run smoke — expect FAIL**

- [ ] **Step 33.3: Pull/clone repos**

  ```bash
  cd /home/claude

  # Toolkit
  if [ -d claude-code-toolkit ]; then
    cd claude-code-toolkit && git pull
  else
    git clone https://github.com/pedrormc/claude-code-toolkit.git
  fi

  # Vault
  if [ -d obsidiano ]; then
    cd obsidiano && git pull
  else
    cd /home/claude && git clone https://github.com/pedrormc/obsidiano.git
  fi
  ```

- [ ] **Step 33.4: Run smoke — expect PASS**

### Task 34: Run toolkit install.sh on VPS

- [ ] **Step 34.1: Backup VPS ~/.claude/ before install**

  ```bash
  cp -r ~/.claude ~/.claude.pre-foundation-bak
  cp ~/.claude.json ~/.claude.json.pre-foundation-bak 2>/dev/null || true
  ```

- [ ] **Step 34.2: Run install.sh**

  ```bash
  cd ~/claude-code-toolkit
  bash install.sh --force
  ```

  Expected output: success messages for each component + Foundation section at the end.

- [ ] **Step 34.3: Run foundation-smoke.sh on VPS**

  ```bash
  ~/.claude/scripts/foundation-smoke.sh
  ```

  Expected: some tests pass, but S1, S12 fail because VPS vault path is different AND MCPVault is not configured yet. This is expected — fixed in Task 35.

### Task 35: Add MCPVault + disable Ralph on VPS ~/.claude.json

- [ ] **Step 35.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task35.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  jq -e '.mcpServers.obsidian.command' ~/.claude.json
  jq -e '.mcpServers.obsidian.args | index("/home/claude/obsidiano")' ~/.claude.json
  jq -e '.disabledPlugins | any(. | test("ralph"))' ~/.claude/settings.json
  echo "✅ Task 35 smoke passed"
  EOF
  chmod +x /tmp/smoke-task35.sh
  ```

- [ ] **Step 35.2: Run smoke — expect FAIL**

- [ ] **Step 35.3: Add MCPVault entry via jq**

  ```bash
  jq '.mcpServers.obsidian = {
    "command": "npx",
    "args": ["@bitbonsai/mcpvault@latest", "/home/claude/obsidiano"],
    "disabled": false
  }' ~/.claude.json > /tmp/claude.json.new && mv /tmp/claude.json.new ~/.claude.json
  ```

- [ ] **Step 35.4: Update session-start-memory-loader.sh with VPS vault path**

  The hook script auto-detects path but uses `$HOME/obsidiano` on Linux. Since VPS is Linux with vault at `/home/claude/obsidiano`, this works as-is. Verify:

  ```bash
  grep "obsidiano" ~/.claude/hooks/session-start-memory-loader.sh
  ```

  Expected: path resolution via `$HOME/obsidiano`. If not, edit.

- [ ] **Step 35.5: Verify mcpvault reachable**

  ```bash
  npx -y @bitbonsai/mcpvault@latest --help >/dev/null 2>&1 && echo "✅ reachable" || echo "❌ check network"
  ```

- [ ] **Step 35.6: Run smoke — expect PASS**

### Task 36: Install RuFlo on VPS (workers off)

- [ ] **Step 36.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task36.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  test -d ~/.ruflo || which ruflo
  pgrep -f "ruflo.*worker" && exit 1 || true  # no workers should be running
  jq -e '.disabledPlugins | any(. | test("ruflo-workers"))' ~/.claude/settings.json
  echo "✅ Task 36 smoke passed"
  EOF
  chmod +x /tmp/smoke-task36.sh
  ```

- [ ] **Step 36.2: Run smoke — expect FAIL**

- [ ] **Step 36.3: Install RuFlo (canonical command per spec §6.3)**

  ```bash
  npx ruflo@latest init --install-only --no-start
  ```

- [ ] **Step 36.4: Verify binary + workers off**

  ```bash
  which ruflo || npx ruflo --version
  ls ~/.ruflo/ 2>/dev/null
  pgrep -f "ruflo.*worker" && echo "❌ workers running" || echo "✅ workers off"
  ```

- [ ] **Step 36.5: Add `ruflo-workers` to disabledPlugins**

  ```bash
  jq '.disabledPlugins = ((.disabledPlugins // []) + ["ruflo-workers"] | unique)' \
    ~/.claude/settings.json > /tmp/s.json && mv /tmp/s.json ~/.claude/settings.json
  ```

- [ ] **Step 36.6: Run smoke — expect PASS**

### Task 37: Update Zel's whatsapp-channel.ts (CRITICAL — regression risk)

**Files (on VPS):**
- Modify: `~/zel/whatsapp-channel.ts`

- [ ] **Step 37.1: Write smoke test**

  ```bash
  cat > /tmp/smoke-task37.sh <<'EOF'
  #!/usr/bin/env bash
  set -e
  grep -q "Claude/CLAUDE.md" ~/zel/whatsapp-channel.ts
  grep -q "Claude/personas/zel.md" ~/zel/whatsapp-channel.ts
  # The old single-file read should be gone
  ! grep -q "readFileSync.*obsidiano/CLAUDE.md" ~/zel/whatsapp-channel.ts
  echo "✅ Task 37 smoke passed"
  EOF
  chmod +x /tmp/smoke-task37.sh
  ```

- [ ] **Step 37.2: Run smoke — expect FAIL (file still has old loader)**

- [ ] **Step 37.3: Checkout feature branch in zel repo**

  ```bash
  cd ~/zel
  git checkout main
  git pull
  git checkout -b feat/foundation-dual-prompt-load
  ```

- [ ] **Step 37.4: Read current whatsapp-channel.ts to find the exact line**

  ```bash
  grep -n "readFileSync.*CLAUDE" whatsapp-channel.ts
  ```

- [ ] **Step 37.5: Apply the dual-load patch**

  Locate the block that reads CLAUDE.md (example — adjust based on actual code):

  Before (current):
  ```typescript
  const systemPrompt = readFileSync('/home/claude/obsidiano/CLAUDE.md', 'utf-8');
  ```

  After (patched):
  ```typescript
  const generic = readFileSync('/home/claude/obsidiano/Claude/CLAUDE.md', 'utf-8');
  const persona = readFileSync('/home/claude/obsidiano/Claude/personas/zel.md', 'utf-8');
  const systemPrompt = `${generic}\n\n---\n\n${persona}`;
  console.log('[zel] system prompt loaded: Claude/CLAUDE.md + Claude/personas/zel.md');
  ```

  **IMPORTANT:** the `console.log` line is added deliberately so the log-grep check in Step 37.7 has something to find.

- [ ] **Step 37.6: Type-check and run**

  ```bash
  cd ~/zel
  bun x tsc --noEmit whatsapp-channel.ts 2>&1 | head -10
  ```

  Expected: no type errors.

- [ ] **Step 37.7: Commit on feature branch**

  ```bash
  git add whatsapp-channel.ts
  git commit -m "feat: dual-load system prompt (Foundation vault split)

  Loads Claude/CLAUDE.md (generic) + Claude/personas/zel.md (persona)
  instead of the single pre-split obsidiano/CLAUDE.md.

  Required by TRIFORCE Foundation sub-project A+B.
  See TRIFORCE/docs/superpowers/specs/2026-04-09-foundation-design.md §3.4.

  *[Registrado por: VPS — 2026-04-09]*"
  ```

- [ ] **Step 37.8: Run smoke — expect PASS**

### Task 38: Restart Zel and verify via log-grep (pre-E2)

- [ ] **Step 38.1: Stop current Zel session**

  ```bash
  pm2 stop zel-channel 2>/dev/null || tmux kill-session -t zel 2>/dev/null || pkill -f whatsapp-channel.ts
  sleep 2
  ```

- [ ] **Step 38.2: Start fresh**

  ```bash
  cd ~/zel
  # use whichever is the current method — pm2 or tmux or direct
  if command -v pm2 >/dev/null; then
    pm2 start "bun run channel" --name zel-channel
  else
    tmux new-session -d -s zel "bun run channel"
  fi
  sleep 3
  ```

- [ ] **Step 38.3: Log-grep fallback chain (spec §3.4 step 5)**

  ```bash
  # Resolve log source
  if [ -f ~/zel/logs/channel.log ]; then
    LOG_CMD="tail -50 ~/zel/logs/channel.log"
  elif command -v pm2 >/dev/null && pm2 list 2>/dev/null | grep -q zel-channel; then
    LOG_CMD="pm2 logs zel-channel --nostream --lines 50"
  elif tmux has-session -t zel 2>/dev/null; then
    LOG_CMD="tmux capture-pane -pt zel -S -50"
  else
    LOG_CMD="echo '(no log source)'"
  fi

  # Check for prompt load marker (the console.log added in 37.5)
  $LOG_CMD | grep -q "system prompt loaded: Claude/CLAUDE.md" && echo "✅ prompt loaded" || echo "⚠️ no prompt load log"

  # Check for errors
  $LOG_CMD | grep -iE "(error|exception|ENOENT|cannot find)" && echo "❌ errors present" || echo "✅ no errors"
  ```

- [ ] **Step 38.4: If log check fails, proceed to E2 anyway (E2 is authoritative)**

### Task 39: E2 — WhatsApp round-trip regression test (MANUAL, CRITICAL)

- [ ] **Step 39.1: From Desktop, send WhatsApp message to Zel**

  ```
  From your WhatsApp (Desktop WhatsApp app or phone):
  Send to Zel: "oi, quais projetos ativos?"
  ```

- [ ] **Step 39.2: Wait for Zel response (< 30 seconds)**

- [ ] **Step 39.3: Verify all 5 criteria**

  | # | Check | Pass if |
  |---|---|---|
  | 1 | Response arrives in WhatsApp | Yes |
  | 2 | Response cites real projects | Contains at least one of: Mel, Mili, Foundation, TRIFORCE |
  | 3 | Response time | < 30 seconds |
  | 4 | No errors in VPS logs | `tail -100` shows no error markers |
  | 5 | Zel did not message other numbers | Only replies to your number |

- [ ] **Step 39.4: If ANY criterion fails → IMMEDIATE ROLLBACK**

  ```bash
  # On VPS:
  cd ~/zel
  git checkout main                           # reverts to pre-split whatsapp-channel.ts
  pm2 restart zel-channel 2>/dev/null || { tmux kill-session -t zel; tmux new-session -d -s zel "bun run channel"; }
  sleep 3

  # ALSO rollback vault split on VPS:
  cd ~/obsidiano
  git checkout pre-foundation-2026-04-09 -- CLAUDE.md
  # Note: this leaves Claude/ folder intact but restores the old monolithic CLAUDE.md
  ```

  After rollback: verify Zel works again (repeat E2 Step 39.1). Then stop implementation and investigate.

- [ ] **Step 39.5: If all 5 pass → merge feature branch**

  ```bash
  cd ~/zel
  git checkout main
  git merge --no-ff feat/foundation-dual-prompt-load -m "merge: Foundation dual-load system prompt"
  git branch -d feat/foundation-dual-prompt-load
  git tag v2.1.0-foundation
  git push origin main
  git push origin v2.1.0-foundation
  ```

### Task 40: VPS full smoke + integration run

- [ ] **Step 40.1: Run foundation-smoke.sh on VPS**

  ```bash
  ~/.claude/scripts/foundation-smoke.sh
  ```

  Expected: 13/13 passed. S1/S2/S3/S12 now pass because vault is populated and MCPVault is configured.

- [ ] **Step 40.2: Run foundation-validate.sh on VPS**

  ```bash
  ~/.claude/scripts/foundation-validate.sh
  ```

  Expected: smoke passes + I1 passes automatically, I2-I7 printed as manual instructions.

---

> **End of Chunk 4.** VPS has Foundation fully installed. Zel is using the dual-load system prompt and passing WhatsApp round-trip. Next chunk sets up cron schedules and runs final E2E validations.

---

## Chunk 5: Cron Setup & Final Validation

> Goal: install scheduled tasks for auto-promote and index-rebuild on Desktop (Task Scheduler) and VPS (cron), run the full validation suite (all 13 smoke + all 7 integration + all 3 E2E), and hand off to user.

### Task 41: Create Desktop Task Scheduler entries

- [ ] **Step 41.1: Open PowerShell as admin (manual)**

  You need PowerShell with admin rights to create scheduled tasks. In Windows Terminal, right-click PowerShell tab → Run as Administrator.

- [ ] **Step 41.2: Create auto-promote task**

  ```powershell
  $action = New-ScheduledTaskAction -Execute "C:\Program Files\Git\bin\bash.exe" -Argument "-c '/c/Users/teste/.claude/scripts/memory-auto-promote.sh'"
  $trigger = New-ScheduledTaskTrigger -Daily -At 03:00
  $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType S4U
  Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName "Claude Memory Auto-Promote" -Description "Foundation v1 daily auto-promotion"
  ```

- [ ] **Step 41.3: Create index-rebuild task**

  ```powershell
  $action = New-ScheduledTaskAction -Execute "C:\Program Files\Git\bin\bash.exe" -Argument "-c '/c/Users/teste/.claude/scripts/memory-index-rebuild.sh'"
  $trigger = New-ScheduledTaskTrigger -Daily -At 03:05
  $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType S4U
  Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName "Claude Memory Index Rebuild" -Description "Foundation v1 daily index regen"
  ```

- [ ] **Step 41.4: Verify both tasks listed**

  ```powershell
  schtasks /query /tn "Claude Memory Auto-Promote"
  schtasks /query /tn "Claude Memory Index Rebuild"
  ```

- [ ] **Step 41.5: Run both tasks manually to sanity-check**

  ```powershell
  schtasks /run /tn "Claude Memory Auto-Promote"
  Start-Sleep -Seconds 5
  schtasks /run /tn "Claude Memory Index Rebuild"
  ```

  Then check logs in `~/.claude/` and vault for heartbeat JSONL line + regenerated INDEX.md.

### Task 42: Create VPS crontab entries

- [ ] **Step 42.1: SSH to VPS and edit crontab**

  ```bash
  ssh vps
  crontab -e
  ```

  Add these two lines:

  ```cron
  0 3 * * * /home/claude/.claude/scripts/memory-auto-promote.sh >> /tmp/memory-auto-promote.cron.log 2>&1
  5 3 * * * /home/claude/.claude/scripts/memory-index-rebuild.sh >> /tmp/memory-index-rebuild.cron.log 2>&1
  ```

- [ ] **Step 42.2: Verify crontab saved**

  ```bash
  crontab -l | grep memory
  ```

  Expected: both lines present.

- [ ] **Step 42.3: Manual run for sanity**

  ```bash
  /home/claude/.claude/scripts/memory-auto-promote.sh
  /home/claude/.claude/scripts/memory-index-rebuild.sh
  tail -5 ~/obsidiano/Claude/memory/.promotion-log.jsonl
  ```

  Expected: heartbeat line and regenerated INDEX.

### Task 43: Full E1 test — Desktop session cycle

- [ ] **Step 43.1: Open a new `claude` session in an empty scratch directory**

  ```bash
  mkdir -p ~/scratch-foundation-test
  cd ~/scratch-foundation-test
  claude
  ```

- [ ] **Step 43.2: In the session, ask about user/projects**

  ```
  Prompt: "o que você sabe sobre mim e meus projetos atuais?"
  ```

  Expected response cites: CTO Singular, pedrormc, TRIFORCE, Mili, Mel, active.md content.

- [ ] **Step 43.3: In the same session, edit a throwaway file**

  ```
  Prompt: "crie um arquivo test.txt com conteúdo 'foundation e2e test'"
  ```

- [ ] **Step 43.4: Run /save-session**

  ```
  Slash command: /save-session
  ```

- [ ] **Step 43.5: Exit session and verify outputs**

  ```bash
  # New session file in harness
  ls -lt ~/.claude/sessions/*-session.tmp | head -3

  # Mirror in vault
  ls -lt ~/Documents/obsidiano/Claude/sessions/*.md | head -3

  # active.md updated
  grep "$(date +%Y-%m-%d)" ~/Documents/obsidiano/Claude/memory/active.md | head -3

  # Auto-commit happened
  cd ~/Documents/obsidiano && git log --oneline -5
  ```

  Expected: recent session file in both locations, active.md has entry for today, git log shows auto-commit.

- [ ] **Step 43.6: Cleanup**

  ```bash
  cd && rm -rf ~/scratch-foundation-test
  ```

### Task 44: Full E2 test — Zel WhatsApp regression

This was already run in Task 39 — if it passed there, E2 is confirmed. If Chunk 5 is executed in a separate session, re-run:

- [ ] **Step 44.1: Send `oi, quais projetos ativos?` to Zel via WhatsApp**

- [ ] **Step 44.2: Verify all 5 criteria from Task 39.3**

### Task 45: Full E3 test — Cross-env parity

- [ ] **Step 45.1: On Desktop, add a decision to `decisions.md`**

  ```bash
  cd ~/Documents/obsidiano
  cat >> Claude/memory/decisions.md <<'EOF'

  ## 2026-04-09 — Foundation E3 test decision (TEST ENTRY — DELETE AFTER)
  **Motivo:** validar cross-env parity E3
  **Outcome esperado:** VPS lê esta decisão após git pull
  **Review em:** 2026-04-10 (será deletado amanhã)

  *[Registrado por: DESKTOP — 2026-04-09]*
  EOF
  ```

- [ ] **Step 45.2: Commit and push from Desktop**

  ```bash
  git add Claude/memory/decisions.md
  git commit -m "test: E3 cross-env parity entry (temporary)"
  git push
  ```

- [ ] **Step 45.3: SSH to VPS, pull, and verify**

  ```bash
  ssh vps
  cd ~/obsidiano
  git pull
  grep "Foundation E3 test" Claude/memory/decisions.md
  ```

  Expected: the test entry is visible on VPS within the 2-minute budget.

- [ ] **Step 45.4: Cleanup — remove test entry**

  ```bash
  # On Desktop:
  cd ~/Documents/obsidiano
  git revert --no-commit HEAD
  git commit -m "test: remove E3 cross-env parity test entry"
  git push

  # On VPS:
  cd ~/obsidiano && git pull
  ```

### Task 46: Final Foundation completion checklist

Run through the checklist from spec §8.5:

- [ ] **Step 46.1: Structure** — Smoke S2-S6 pass on Desktop and VPS
- [ ] **Step 46.2: Refactor** — Smoke S1, S3 pass on both
- [ ] **Step 46.3: Stack** — Smoke S7 pass on both
- [ ] **Step 46.4: Hooks** — Smoke S8, S9, S13 pass + settings.json inspected
- [ ] **Step 46.5: Dedup** — Smoke S10, S11 pass
- [ ] **Step 46.6: Memory load** — I1, I2 pass (I2 manual verification from Task 43)
- [ ] **Step 46.7: Auto-promote + revert** — I4, I5 run manually using `scripts/test-i4-fake-data.sh`
- [ ] **Step 46.8: Zel intact** — E2 pass
- [ ] **Step 46.9: Cross-env** — E3 pass
- [ ] **Step 46.10: Performance** — manual timing of `claude` startup

  ```bash
  time claude --version
  time { bash ~/.claude/hooks/session-start-memory-loader.sh >/dev/null; }
  ```

  Expected: loader completes in < 3 seconds.

### Task 47: Commit final state and push

- [ ] **Step 47.1: Push TRIFORCE (spec + plan)**

  ```bash
  cd ~/Desktop/TRIFORCE
  git push origin main
  git push origin pre-foundation-2026-04-09   # the defensive tag
  ```

- [ ] **Step 47.2: Verify claude-code-toolkit + vault already pushed**

  ```bash
  cd ~/Desktop/claude-code-toolkit && git status && git log --oneline -5
  cd ~/Documents/obsidiano && git status && git log --oneline -5
  ```

- [ ] **Step 47.3: Update `obsidiano/Claude/memory/active.md` with Foundation completion marker**

  Via a session, edit `active.md` to move "TRIFORCE Foundation" from "Projetos ativos" to a new section "Completed this week" or add completion date.

  ```bash
  ~/.claude/scripts/memory-update.sh claude active.md "$(cat ~/Documents/obsidiano/Claude/memory/active.md | sed 's/Foundation.*in implementa.*/Foundation — ✅ complete 2026-04-09/')"
  ```

- [ ] **Step 47.4: Run final full validation**

  ```bash
  ~/.claude/scripts/foundation-validate.sh
  ```

  Expected: all smoke green, I1 green, I2-I7 instructions printed. All 10 completion criteria from 46.1-46.10 marked done.

### Task 48: Handoff to user

- [ ] **Step 48.1: Summarize state in a brief message:**

  ```
  Foundation v1 complete.

  Structure:
  - Vault refactored (CLAUDE.md loader + Claude/ brain with 6 seeds + INDEX)
  - Zel persona isolated in Claude/personas/zel.md, dual-load in whatsapp-channel.ts
  - 4 hooks wired (Desktop + VPS)
  - 7 scripts installed (memory-update, memory-auto-promote, memory-index-rebuild, memory-revert, foundation-smoke, foundation-validate, foundation-uninstall)
  - Gstack installed (33 slash commands)
  - RuFlo installed on VPS, workers off
  - Ralph disabled
  - Cron scheduled (Desktop Task Scheduler + VPS crontab)

  Pushed:
  - pedrormc/TRIFORCE (spec + plan)
  - pedrormc/claude-code-toolkit (hooks + scripts + config + install.sh)
  - pedrormc/obsidiano (vault refactor + memory seeds)
  - pedrormc/zel (whatsapp-channel.ts dual-load, tag v2.1.0-foundation)

  All 13 smoke + 7 integration + 3 E2E tests passed.

  Not yet done (future sub-projects):
  - C: cross-env automatic sync protocol
  - D: autonomous scheduled tasks (morning briefing, research-scout, decision-logger)
  - E: multimodal memory
  - F: visual mascot
  - Phase 2: RuFlo workers activation
  - Mobile: apêndice documented in TRIFORCE/docs/setup-mobile.md, run when Mobile is next used
  ```

---

> **End of Chunk 5.** Foundation is live and validated. All sub-projects A+B deliverables are in production across Desktop and VPS. Mobile is documented for future execution. Spec + plan are in `pedrormc/TRIFORCE`.

---

## Summary

| Chunk | Tasks | Focus | Test count |
|---|---|---|---|
| 1 | 1-15 | Vault refactor + memory seeds | 12 smoke (T3-T14) + visual E2E (T15) |
| 2 | 16-26 | Hooks + scripts + settings.json | 9 smoke (T16-T24) + 1 integration (T25) |
| 3 | 27-31 | Gstack + namespace rule + toolkit propagation | 3 smoke (T27-T29) + first full smoke suite (T29.7) |
| 4 | 32-40 | VPS migration + Zel dual-load + E2 | 5 smoke (T33, T35, T36, T37, T40) + E2 (T39) |
| 5 | 41-48 | Cron + final validation + handoff | E1 (T43) + E3 (T45) + completion checklist (T46) |

**Total tasks:** 48
**Total smoke tests defined:** 29 per-component + 13 in foundation-smoke.sh
**Total integration tests:** 7 (I1-I7)
**Total E2E tests:** 3 (E1-E3)
**Defensive tags:** 4 (TRIFORCE, claude-code-toolkit, obsidiano, zel)
**Feature branches:** 3 (`feat/foundation-claude-split` in vault, `feat/foundation` in toolkit, `feat/foundation-dual-prompt-load` in zel)
**Rollback paths:** per-component (11 rows in spec §8.6) + universal via pre-foundation tags + `foundation-uninstall.sh`

---

*[Registrado por: DESKTOP — 2026-04-09]*
