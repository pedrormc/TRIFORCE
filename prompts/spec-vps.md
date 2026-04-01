# Prompt para Coletar Specs do Ambiente VPS

> Cole este prompt no Claude Code da **VPS (Container Docker)** para que ele retorne as especificacoes completas do ambiente.

---

Voce e o Claude VPS rodando dentro de um container Docker na AWS Lightsail. Preciso que voce colete e retorne TODAS as especificacoes do seu ambiente atual. Execute os comandos abaixo e me retorne um relatorio completo formatado em Markdown.

## Comandos para executar:

```bash
# Sistema
uname -a
cat /etc/os-release | head -5
hostname
whoami
id

# Hardware/Container
cat /proc/cpuinfo | grep "model name" | head -1
cat /proc/meminfo | head -3
df -h /workspace | tail -1
df -h /home | tail -1

# Network
ip addr show 2>/dev/null || ifconfig 2>/dev/null
cat /etc/resolv.conf 2>/dev/null

# Internet test
curl -s --connect-timeout 5 https://api.github.com/zen && echo " [OK]" || echo "[FAIL]"
curl -s --connect-timeout 5 -o /dev/null -w "%{http_code}" https://google.com

# Isolation test
ls /root 2>&1 | head -1
docker ps 2>&1 | head -1
curl -s --connect-timeout 2 http://172.17.0.1 2>&1 | head -1

# Node/Claude
node --version
npm --version
claude --version

# Git
git --version
git config --global user.name 2>/dev/null
git config --global user.email 2>/dev/null
ssh -T git@github.com 2>&1 | head -1

# Claude Code configs
ls -la ~/.claude/CLAUDE.md 2>/dev/null
cat ~/.claude/CLAUDE.md 2>/dev/null | head -5
ls ~/.claude/agents/ 2>/dev/null | wc -l
ls ~/.claude/rules/common/ 2>/dev/null | wc -l
ls ~/.claude/skills/ 2>/dev/null | wc -l
cat ~/.claude/settings.json 2>/dev/null | head -10
claude plugins list 2>/dev/null

# Workspace
ls /workspace/ 2>/dev/null | head -20
du -sh /workspace/ 2>/dev/null

# Logs
ls ~/logs/ 2>/dev/null
```

## Formato de saida esperado:

```markdown
# VPS Environment Specs
*[Registrado por: VPS — YYYY-MM-DD]*

## Sistema
- OS: ...
- Kernel: ...
- Hostname: ...
- User: ...

## Container
- CPU: ...
- RAM: ...
- Workspace: ... / ...GB
- Home: ... / ...GB

## Network
- IP: ...
- DNS: ...
- Internet: OK/FAIL
- Host access: BLOCKED/OPEN

## Isolation
- /root: blocked/open
- docker CLI: available/unavailable
- Host (172.17.0.1): blocked/open

## Dev Tools
- Node: ...
- npm: ...
- Claude Code: ...
- Git: ...

## Claude Code
- Agents: X
- Rules: X
- Skills: X
- Plugins: X
- CLAUDE.md: sim/nao
- defaultMode: ...

## Workspace Contents
- (listar conteudo)

## Problemas Detectados
- (listar qualquer issue)
```

Retorne o relatorio completo. Marque como `*[Registrado por: VPS — YYYY-MM-DD]*`.
