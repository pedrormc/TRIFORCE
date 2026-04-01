# Setup Desktop — Windows (Claude Master)

*[Registrado por: DESKTOP — 2026-04-01]*

## Pre-requisitos

- Windows 10/11
- Node.js 18+ (`winget install OpenJS.NodeJS.LTS`)
- Git (`winget install Git.Git`)
- GitHub CLI (`winget install GitHub.cli`)
- Terminal: Windows Terminal, WezTerm, ou similar

## Passo 1 — Instalar Claude Code

```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

Autenticar:
```bash
claude auth login
```
Selecionar Claude Max (Opus 4.6, 1M context).

## Passo 2 — Instalar Toolkit

```bash
git clone https://github.com/pedrormc/claude-code-toolkit.git /tmp/claude-code-toolkit
cd /tmp/claude-code-toolkit
bash install.sh --force
```

Resultado esperado:
- 5 agents em `~/.claude/agents/`
- 16 rules em `~/.claude/rules/`
- 8+ skills em `~/.claude/skills/`
- Scripts em `~/.claude/scripts/`

## Passo 3 — Instalar Plugins

```bash
claude plugins install everything-claude-code --marketplace everything-claude-code
claude plugins install superpowers --marketplace superpowers-marketplace
claude plugins install ralph-skills --marketplace ralph-marketplace
claude plugins install ui-ux-pro-max --marketplace ui-ux-pro-max-skill
```

## Passo 4 — Identidade Local

Copiar template de identidade:
```bash
cp templates/claude-md/desktop.md ~/.claude/CLAUDE.md
cp templates/settings/desktop.json ~/.claude/settings.json
```

Ou usar os templates deste repo como base e personalizar.

## Passo 5 — Configurar MCP Servers

Editar `~/.claude/mcp.json` com seus dados reais:
- Obsidian vault path
- n8n API URL e key
- TestSprite API key
- Outros MCPs desejados

**NUNCA commitar API keys em repos publicos.**

## Passo 6 — Configurar Git

```bash
git config --global user.name "pedrormc"
git config --global user.email "pedrorobertomiranda@gmail.com"
gh auth login
```

## Passo 7 — Clonar Obsidian Vault

```bash
git clone git@github.com:pedrormc/obsidiano.git ~/Documents/obsidiano
```

## Passo 8 — Validacao

```bash
ls ~/.claude/agents/          # 5 agents
ls ~/.claude/rules/common/    # 10 rules
ls ~/.claude/skills/          # 8+ skills
claude plugins list           # 4 plugins
cat ~/.claude/mcp.json        # sem placeholders
```

## Caracteristicas do Desktop

- **defaultMode: acceptEdits** — Usuario presente, supervisao ativa
- **Hooks:** Notifications via toast, statusline custom
- **Plugins:** 106+ skills disponiveis
- **Permissao:** TOTAL — ambiente principal de desenvolvimento
