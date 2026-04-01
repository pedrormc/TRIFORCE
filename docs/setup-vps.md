# Setup VPS — Docker/AWS Lightsail (Claude VPS)

*[Registrado por: DESKTOP — 2026-04-01]*

## Pre-requisitos

- VPS com 4GB+ RAM, 2+ vCPUs, 40GB+ SSD
- Docker instalado no host
- Acesso SSH ao host
- Node.js 18+ (dentro do container)

Testado em: AWS Lightsail 4GB RAM, 2 vCPUs, 80GB SSD.

## Passo 1 — Criar Container Isolado

```bash
# No host da VPS
docker run -d \
  --name claude-code \
  --cap-drop=ALL \
  --security-opt no-new-privileges \
  -v claude-workspace:/workspace \
  -w /workspace \
  node:20-slim \
  tail -f /dev/null
```

## Passo 2 — Setup Dentro do Container

```bash
docker exec -it claude-code bash

# Dentro do container:
apt update && apt install -y git curl openssh-client
npm install -g @anthropic-ai/claude-code
useradd -m -s /bin/bash coder
su - coder
claude auth login
```

## Passo 3 — Isolamento do Host (CRITICO)

No **host** (fora do container), configurar iptables pra impedir acesso do container aos servicos do host:

```bash
# Bloquear container → host
iptables -I DOCKER-USER -s 172.17.0.0/16 -d 172.17.0.1 -j DROP

# Permitir saida pra internet
iptables -A DOCKER-USER -i docker0 -o ens5 -j ACCEPT
iptables -A DOCKER-USER -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A DOCKER-USER -j RETURN
```

Verificar:
```bash
# De dentro do container:
curl -s https://api.github.com/zen  # Deve funcionar (internet)
curl -s http://172.17.0.1:80        # Deve falhar (host bloqueado)
```

### Troubleshooting Internet do Container

Se HTTPS nao funciona mas DNS resolve:
1. Verificar regras iptables (a ordem importa)
2. Verificar se docker0 → interface de rede do host esta correto
3. Verificar se RELATED,ESTABLISHED esta ACCEPT
4. Testar: `docker exec claude-code curl -v https://api.github.com/zen`

## Passo 4 — Instalar Toolkit

```bash
# Como user coder dentro do container:
git clone https://github.com/pedrormc/claude-code-toolkit.git /tmp/claude-code-toolkit
cd /tmp/claude-code-toolkit
bash install.sh --force
```

## Passo 5 — Identidade Local (MAXIMO)

```bash
cp templates/claude-md/vps.md ~/.claude/CLAUDE.md
cp templates/settings/vps.json ~/.claude/settings.json
```

A identidade VPS tem:
- defaultMode: "bypassPermissions" (sem pedir confirmacao)
- Deny list vazia (confia no isolamento do container)
- Filosofia "ambiente de guerra" — tarefas pesadas

## Passo 6 — Claude Admin no Host (Opcional)

Para gerenciar a VPS com Claude Code diretamente no host:

```bash
# No host (como root ou user admin):
npm install -g @anthropic-ai/claude-code
claude auth login
```

Este Claude "admin" gerencia Docker, iptables, Nginx, e infra geral.
NAO e o mesmo Claude do container.

## Passo 7 — Validacao

```bash
# Dentro do container:
curl -s https://api.github.com/zen    # Internet OK
ls ~/.claude/agents/                   # 5 agents
ls ~/.claude/rules/common/             # 10 rules
claude plugins list                    # 4 plugins

# Do host:
docker exec claude-code whoami         # coder (nao root)
docker exec claude-code ls /root       # Permission denied
docker exec claude-code docker ps      # Command not found
```

## Servicos Complementares na VPS

Esses servicos rodam em containers separados, NAO dentro do container Claude:

| Servico | Funcao | Rede |
|---------|--------|------|
| n8n | Automacoes/workflows | br-36680f8e910b |
| Evolution API | WhatsApp Business | br-b468ab099593 |
| Nginx | Reverse proxy | host |
| PostgreSQL | Banco de dados | host/5432 |

## Lightsail Firewall

Configurar inbound rules:
| Servico | Porta | Protocolo |
|---------|-------|-----------|
| SSH | 22 | TCP |
| HTTPS | 443 | TCP |
| PostgreSQL | 5432 | TCP |

Adicionar portas extras conforme necessidade.
