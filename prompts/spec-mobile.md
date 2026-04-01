# Prompt para Coletar Specs do Ambiente Mobile

> Cole este prompt no Claude Code do **Mobile (Termux)** para que ele retorne as especificacoes completas do ambiente.

---

Voce e o Claude Mobile rodando no Termux. Preciso que voce colete e retorne TODAS as especificacoes do seu ambiente atual. Execute os comandos abaixo e me retorne um relatorio completo formatado em Markdown.

## Comandos para executar:

```bash
# Sistema
uname -a
cat /proc/version
getprop ro.product.model 2>/dev/null || echo "N/A"
getprop ro.build.display.id 2>/dev/null || echo "N/A"

# Termux
echo "Termux version: $(cat $PREFIX/etc/termux-version 2>/dev/null || echo 'unknown')"
echo "PREFIX: $PREFIX"
echo "HOME: $HOME"
echo "SHELL: $SHELL"

# Hardware
cat /proc/cpuinfo | head -20
cat /proc/meminfo | head -5
df -h $HOME | tail -1

# Node/Claude
node --version
npm --version
claude --version

# Git
git --version
git config --global user.name
git config --global user.email
ssh -T git@github.com 2>&1 | head -1

# Packages instalados
pkg list-installed 2>/dev/null | wc -l
echo "--- Key packages ---"
for pkg in git python nodejs clang zsh tmux fzf ripgrep bat jq; do
    command -v $pkg &>/dev/null && echo "$pkg: $(command -v $pkg)" || echo "$pkg: NOT INSTALLED"
done

# Claude Code configs
ls -la ~/.claude/CLAUDE.md 2>/dev/null
ls ~/.claude/agents/ 2>/dev/null | wc -l
ls ~/.claude/rules/common/ 2>/dev/null | wc -l
ls ~/.claude/skills/ 2>/dev/null | wc -l
claude plugins list 2>/dev/null

# Scripts
for script in ~/claude-start.sh ~/img.sh ~/send-doc.sh ~/send-file-wpp.sh ~/backup-mobile.sh; do
    [ -f "$script" ] && echo "EXISTS: $script" || echo "MISSING: $script"
done

# Aliases
alias cc 2>/dev/null
alias ub 2>/dev/null
alias img 2>/dev/null

# PRoot Ubuntu
proot-distro list 2>/dev/null | grep installed

# rclone
rclone version 2>/dev/null | head -1
rclone listremotes 2>/dev/null
```

## Formato de saida esperado:

```markdown
# Mobile Environment Specs
*[Registrado por: MOBILE — YYYY-MM-DD]*

## Sistema
- Device: ...
- Android: ...
- Termux: ...
- Kernel: ...

## Hardware
- CPU: ...
- RAM: ...
- Storage: ...

## Dev Tools
- Node: ...
- npm: ...
- Claude Code: ...
- Git: ...
- Python: ...

## Claude Code
- Agents: X
- Rules: X
- Skills: X
- Plugins: X
- CLAUDE.md: sim/nao

## Scripts
- claude-start.sh: ok/missing
- img.sh: ok/missing
- ...

## Limitacoes Detectadas
- (listar qualquer problema encontrado)
```

Retorne o relatorio completo. Marque como `*[Registrado por: MOBILE — YYYY-MM-DD]*`.
