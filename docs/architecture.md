# Arquitetura TRIFORCE

*[Registrado por: DESKTOP — 2026-04-01]*

## Filosofia

O TRIFORCE separa **metodologia** de **ferramentas**:

- **TRIFORCE** = Como montar os ambientes do zero
- **claude-code-toolkit** = O que cada ambiente instala (agents, skills, rules)

## Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────┐
│                    GitHub (pedrormc)                      │
│                                                          │
│  ┌──────────────┐  ┌───────────────┐  ┌──────────────┐  │
│  │   TRIFORCE   │  │   toolkit     │  │  obsidiano   │  │
│  │  metodologia │  │  ferramentas  │  │    vault     │  │
│  └──────┬───────┘  └───────┬───────┘  └──────┬───────┘  │
└─────────┼──────────────────┼─────────────────┼──────────┘
          │                  │                 │
          │    ┌─────────────┼─────────────┐   │
          │    │             │             │   │
     ┌────▼────▼──────┐ ┌───▼─────────┐ ┌▼───▼────────┐
     │   DESKTOP      │ │   MOBILE    │ │    VPS       │
     │   Windows 11   │ │  Termux     │ │  Lightsail   │
     │                │ │  Poco F5    │ │  Docker      │
     │ ┌────────────┐ │ │ ┌─────────┐ │ │ ┌──────────┐ │
     │ │ CLAUDE.md  │ │ │ │CLAUDE.md│ │ │ │CLAUDE.md │ │
     │ │ (Master)   │ │ │ │(Mobile) │ │ │ │(VPS)     │ │
     │ └────────────┘ │ │ └─────────┘ │ │ └──────────┘ │
     │ ┌────────────┐ │ │ ┌─────────┐ │ │ ┌──────────┐ │
     │ │ settings   │ │ │ │settings │ │ │ │settings  │ │
     │ │ (total)    │ │ │ │(restrito│ │ │ │(bypass)  │ │
     │ └────────────┘ │ │ └─────────┘ │ │ └──────────┘ │
     │ ┌────────────┐ │ │ ┌─────────┐ │ │ ┌──────────┐ │
     │ │ toolkit/   │ │ │ │toolkit/ │ │ │ │toolkit/  │ │
     │ │ (shared)   │ │ │ │(shared) │ │ │ │(shared)  │ │
     │ └────────────┘ │ │ └─────────┘ │ │ └──────────┘ │
     └────────────────┘ └─────────────┘ └──────────────┘
```

## Fluxo de Configuracao

```
1. Seguir guia TRIFORCE (docs/setup-*.md)
   ├── Instalar pre-requisitos do ambiente
   ├── Configurar terminal e shell
   └── Autenticar Claude Code

2. Instalar toolkit (claude-code-toolkit)
   ├── git clone + bash install.sh
   ├── Instala agents, skills, rules, scripts
   └── Configura MCP servers

3. Configurar identidade local
   ├── Copiar template CLAUDE.md do ambiente
   ├── Copiar template settings.json do ambiente
   └── Ajustar dados locais (paths, API keys via .env)

4. Validar instalacao
   ├── Agents (5), Rules (16), Skills (8+)
   ├── Plugins (4), MCP servers, Scripts
   └── Rodar testes de permissao
```

## Niveis de Permissao

| Nivel | defaultMode | Deny List | Uso |
|-------|-------------|-----------|-----|
| RESTRITO | default | rm -rf, git push --force, docker destrutivos, .env/.pem/.key | Mobile — ambiente sem supervisao constante |
| TOTAL | acceptEdits | Minimo | Desktop — usuario presente, supervisao ativa |
| MAXIMO | bypassPermissions | Vazio | VPS — container isolado, sem risco ao host |

## Seguranca

### Dados Sensiveis
- API keys, tokens e senhas NUNCA vao em repos publicos
- Usar variaveis de ambiente ou .env local
- Evolution API, n8n, TestSprite: dados ficam em .env ou mcp.json local

### Isolamento VPS
- Container Docker sem acesso ao host
- iptables bloqueando comunicacao container→host
- Capabilities do kernel zeradas
- Unico acesso: /workspace (79GB)

## Obsidian (Base de Conhecimento Compartilhada)

- Todos os 3 ambientes tem acesso total ao vault (read/write/MCP)
- Sync via Git (repo privado pedrormc/obsidiano)
- Pasta `Triforce/` dedicada para notas do setup
- Regra: cada ambiente identifica quem escreveu (tag de origem)
