# TRIFORCE

> Setup Multi-Ambiente Claude Code — 3 ambientes independentes com identidade, permissoes e personalidade propria.

```
         ┌────────────────┐
         │    TRIFORCE     │
         │  Claude Code    │
         │  Multi-Env      │
         └───────┬────────┘
      ┌──────────┼──────────┐
      ▼          ▼          ▼
 ┌─────────┐ ┌────────┐ ┌──────┐
 │ DESKTOP │ │ MOBILE │ │  VPS │
 │ Master  │ │ Termux │ │  DO  │
 │ Windows │ │Android │ │Ubuntu│
 └─────────┘ └────────┘ └──────┘
```

## O que e o TRIFORCE?

TRIFORCE e uma metodologia para operar **3 instancias independentes** do Claude Code, cada uma com:

- **Identidade propria** (nome, personalidade, CLAUDE.md unico)
- **Nivel de permissao** adequado ao ambiente (restrito, total, maximo)
- **Configs compartilhadas** via repositorio toolkit
- **Rastreabilidade** de quem escreveu o que (tag de ambiente)

## Os 3 Ambientes

| Ambiente | Plataforma | Identidade | Permissao | Uso |
|----------|-----------|------------|-----------|-----|
| **Desktop** | Windows 11 | Claude Master | TOTAL (acceptEdits) | Dev principal, coordenacao |
| **Mobile** | Termux/Android | Claude Mobile | RESTRITO (default) | Consultas, emergencias |
| **VPS** | DigitalOcean (Ubuntu 24.04) | Claude VPS | MAXIMO (bypassPermissions) | Automacoes, headless, Zel (WhatsApp) |

## Quick Start

### Pre-requisitos

- Node.js 18+
- git
- Claude Code CLI (`npm install -g @anthropic-ai/claude-code`)
- Conta Claude Max (ou Pro)

### 1. Escolha seu ambiente

- [Setup Desktop (Windows)](docs/setup-desktop.md)
- [Setup Mobile (Termux/Android)](docs/setup-mobile.md)
- [Setup VPS (DigitalOcean)](docs/setup-vps.md)

### 2. Instale o toolkit compartilhado

```bash
git clone https://github.com/pedrormc/claude-code-toolkit.git /tmp/claude-code-toolkit
cd /tmp/claude-code-toolkit
bash install.sh --force
```

### 3. Configure a identidade local

Cada ambiente precisa de um `~/.claude/CLAUDE.md` e `~/.claude/settings.json` proprios.
Templates estao em [`templates/`](templates/).

### 4. Valide a instalacao

```bash
# Verificar agents, rules, skills, plugins
ls ~/.claude/agents/          # 5 agents
ls ~/.claude/rules/common/    # 10 rules
ls ~/.claude/skills/          # 8+ skills
claude plugins list           # 4 plugins
```

## Estrutura do Repo

```
TRIFORCE/
├── README.md                    # Este arquivo
├── docs/
│   ├── setup-desktop.md         # Guia completo Desktop (Windows)
│   ├── setup-mobile.md          # Guia completo Mobile (Termux/Android)
│   ├── setup-vps.md             # Guia completo VPS (DigitalOcean)
│   ├── architecture.md          # Arquitetura e decisoes de design
│   └── troubleshooting.md       # Problemas conhecidos e solucoes
├── templates/
│   ├── claude-md/
│   │   ├── desktop.md           # Template CLAUDE.md para Desktop
│   │   ├── mobile.md            # Template CLAUDE.md para Mobile
│   │   └── vps.md               # Template CLAUDE.md para VPS
│   └── settings/
│       ├── desktop.json         # Template settings.json Desktop
│       ├── mobile.json          # Template settings.json Mobile
│       └── vps.json             # Template settings.json VPS
├── scripts/
│   ├── claude-start.sh          # Fix /tmp para Termux
│   ├── img.sh                   # Screenshot para Claude (Mobile)
│   ├── send-doc.sh              # Upload Drive + WhatsApp
│   ├── send-file-wpp.sh         # Arquivo via WhatsApp (base64)
│   └── backup-mobile.sh         # Backup + restore ~/.claude/
└── prompts/
    ├── spec-mobile.md           # Prompt para coletar specs do Mobile
    └── spec-vps.md              # Prompt para coletar specs da VPS
```

## Repositorios Relacionados

| Repo | Funcao |
|------|--------|
| [TRIFORCE](https://github.com/pedrormc/TRIFORCE) | Metodologia multi-ambiente (este repo) |
| [claude-code-toolkit](https://github.com/pedrormc/claude-code-toolkit) | Caixa de ferramentas (agents, skills, rules) |
| [obsidiano](https://github.com/pedrormc/obsidiano) | Vault Obsidian compartilhado entre ambientes |

## Rastreabilidade

Cada ambiente identifica suas escritas:
- `*[Registrado por: DESKTOP — YYYY-MM-DD]*`
- `*[Registrado por: MOBILE — YYYY-MM-DD]*`
- `*[Registrado por: VPS — YYYY-MM-DD]*`

## Autor

**Pedro Roberto (pedrormc)** — CTO @ Singular Group

---

*Criado com Claude Code (Opus 4.6) em 3 ambientes simultaneos.*
