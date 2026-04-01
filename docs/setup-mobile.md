# Setup Mobile — Termux/Android (Claude Mobile)

*[Registrado por: DESKTOP — 2026-04-01]*

## Pre-requisitos

- Android 7+ (testado em Poco F5 com HyperOS)
- Termux v0.119.0+ instalado via [GitHub Releases](https://github.com/termux/termux-app/releases) (NAO usar Play Store)
- Arquitetura: arm64-v8a

## Passo 1 — Configurar Termux

```bash
pkg update && pkg upgrade -y
termux-setup-storage
pkg install root-repo x11-repo
```

### Pacotes Core
```bash
pkg install -y coreutils util-linux findutils grep sed gawk \
  tar gzip bzip2 xz-utils zip unzip file tree less man \
  curl wget openssh openssl gnupg termux-api termux-services
```

### Dev Tools
```bash
pkg install -y git python python-pip nodejs clang make cmake pkg-config
npm install -g gh
```

### Produtividade
```bash
pkg install -y vim neovim nano tmux zsh fzf ripgrep bat jq htop ncdu
```

## Passo 2 — Shell (Zsh + Oh My Zsh)

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

Adicionar no `~/.zshrc`:
```bash
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# TRIFORCE env vars
export TMPDIR=$PREFIX/tmp
export TEMPDIR=$PREFIX/tmp
export TMP=$PREFIX/tmp
export TEMP=$PREFIX/tmp

# Aliases
alias cc="~/claude-start.sh"
alias ub="proot-distro login ubuntu"
alias img="~/img.sh"
alias send="~/send-doc.sh"
alias sendwpp="~/send-file-wpp.sh"
```

## Passo 3 — Git e GitHub

```bash
git config --global user.name "pedrormc"
git config --global user.email "pedrorobertomiranda@gmail.com"
git config --global core.symlinks false
git config --global pack.threads 1
git config --global pack.windowMemory 100m
```

SSH key:
```bash
ssh-keygen -t ed25519 -C "termux-mobile"
cat ~/.ssh/id_ed25519.pub
# Adicionar no GitHub como "termux-mobile"
```

GitHub CLI:
```bash
gh auth login
```

## Passo 4 — PRoot Ubuntu (opcional)

```bash
pkg install proot-distro
proot-distro install ubuntu
proot-distro login ubuntu
# Dentro do Ubuntu:
apt update && apt install -y git nodejs npm openssh-client
```

## Passo 5 — Fix Critico: /tmp

**OBRIGATORIO** — Sem isso, parallel tool calls e plugins quebram.

Criar `~/claude-start.sh`:
```bash
#!/data/data/com.termux/files/usr/bin/bash
export TMPDIR=$PREFIX/tmp
export TMP=$PREFIX/tmp
export TEMP=$PREFIX/tmp
export TEMPDIR=$PREFIX/tmp
exec proot -0 -b $PREFIX/tmp:/tmp -w $HOME $PREFIX/bin/env TMPDIR=$PREFIX/tmp claude "$@"
```

```bash
chmod +x ~/claude-start.sh
```

Testar: `cc` (alias) deve abrir o Claude Code sem erros de /tmp.

## Passo 6 — Instalar Claude Code

```bash
npm install -g @anthropic-ai/claude-code
claude auth login
```

## Passo 7 — Instalar Toolkit

```bash
git clone git@github.com:pedrormc/claude-code-toolkit.git ~/claude-code-toolkit
cd ~/claude-code-toolkit
bash install.sh --force
```

## Passo 8 — Identidade Local (RESTRITO)

Copiar templates:
```bash
cp templates/claude-md/mobile.md ~/.claude/CLAUDE.md
cp templates/settings/mobile.json ~/.claude/settings.json
```

A identidade Mobile tem:
- defaultMode: "default" (pede confirmacao)
- Deny list extensa (rm -rf, git push --force, .env, .pem, .key)
- Filosofia conservadora

## Passo 9 — Scripts Utilitarios

Os scripts estao em `scripts/` deste repo. Copiar pra home:
```bash
cp scripts/claude-start.sh ~/
cp scripts/img.sh ~/
cp scripts/send-doc.sh ~/
cp scripts/send-file-wpp.sh ~/
cp scripts/backup-mobile.sh ~/
chmod +x ~/*.sh
```

Configurar variaveis de ambiente (criar `~/.env.triforce`):
```bash
EVOLUTION_URL="https://sua-url.com"
EVOLUTION_API_KEY="sua-key"
EVOLUTION_INSTANCE="sua-instancia"
```

## Passo 10 — Validacao

```bash
cc                            # Deve abrir Claude Code
ls ~/.claude/agents/          # 5 agents
ls ~/.claude/rules/common/    # 10 rules
ls ~/.claude/skills/          # 8+ skills
claude plugins list           # 4 plugins
ssh -T git@github.com         # "Hi pedrormc!"
```

## Limitacoes Conhecidas

| Problema | Causa | Workaround |
|----------|-------|------------|
| Glob tool falha | ripgrep incompativel ARM64-Android | Rule `glob-workaround.md` → usar `find` |
| Termux:API nao funciona | libjpeg-hyper.so missing (HyperOS) | Sem fix, usar Gboard pra voice |
| Sem colar imagens | Limitacao do terminal | `~/img.sh` pega screenshot automatico |
| Plugins somem | Android mata Termux | Reinstalar apos restart |
| rclone scope limitado | Configurado como appfolder (scope 4) | Reconfigurar pra scope 1 (full access) |
