# Troubleshooting TRIFORCE

*[Registrado por: DESKTOP — 2026-04-01]*

## Mobile (Termux/Android)

### Glob Tool nao funciona (ARM64)

**Sintoma:** Glob tool retorna erro ou resultados vazios no Termux.
**Causa:** ripgrep tem incompatibilidade com ARM64-Android.
**Solucao:** Criar rule `~/.claude/rules/common/glob-workaround.md`:
```markdown
# Glob Workaround (ARM64-Android)
Glob tool nao funciona no ARM64-Android (ripgrep incompativel).
Usar `find` como alternativa para busca de arquivos.
```

### /tmp nao existe no Termux

**Sintoma:** Parallel tool calls falham, plugins quebram, erros de "no such file /tmp/...".
**Causa:** Termux nao tem /tmp real.
**Solucao:** Usar `~/claude-start.sh` com proot (ver setup-mobile.md).

### Termux:API nao funciona (HyperOS)

**Sintoma:** `termux-speech-to-text`, `termux-dialog`, `termux-camera-photo` falham com erro libjpeg.
**Causa:** HyperOS (Xiaomi/Poco) bloqueia `libjpeg-hyper.so`.
**Status:** SEM FIX CONHECIDO. Usar Gboard pra voice typing, `~/img.sh` pra screenshots.

### Plugins desaparecem apos restart

**Sintoma:** Plugins instalados somem quando Android mata o Termux.
**Causa:** Android agressivamente mata processos em background.
**Solucao:** Reinstalar plugins apos cada restart:
```bash
claude plugins install everything-claude-code --marketplace everything-claude-code
claude plugins install superpowers --marketplace superpowers-marketplace
claude plugins install ralph-skills --marketplace ralph-marketplace
claude plugins install ui-ux-pro-max --marketplace ui-ux-pro-max-skill
```

### rclone scope limitado

**Sintoma:** Upload pro Google Drive falha ou so funciona na pasta AppData.
**Causa:** rclone configurado com scope 4 (appfolder).
**Solucao:** `rclone config` → edit gdrive → mudar scope pra 1 (full access) → re-autenticar.

---

## VPS (Docker/AWS)

### Container sem internet (HTTPS falha, DNS ok)

**Sintoma:** `curl https://...` falha com "No route to host", mas `nslookup` funciona.
**Causa:** Regras iptables bloqueando saida ou fora de ordem.
**Solucao:**
1. Verificar a ordem das regras DOCKER-USER:
```bash
iptables -L DOCKER-USER -v -n --line-numbers
```
2. A regra ACCEPT docker0→ens5 deve vir DEPOIS do DROP para 172.17.0.1, mas ANTES do RETURN.
3. Verificar interface de rede correta (`ens5` no Lightsail, pode ser `eth0` em outros providers).
4. Reiniciar Docker se necessario: `systemctl restart docker`.

### Container acessando servicos do host

**Sintoma:** Container consegue acessar Nginx, PostgreSQL, etc no host.
**Causa:** Falta regra DROP para 172.17.0.1.
**Solucao:**
```bash
iptables -I DOCKER-USER -s 172.17.0.0/16 -d 172.17.0.1 -j DROP
```

### Claude Code nao persiste apos restart do container

**Sintoma:** Configs e auth somem quando container reinicia.
**Causa:** Home do user coder nao e volume persistente.
**Solucao:** Montar volume pro home:
```bash
docker run -d \
  -v claude-home:/home/coder \
  -v claude-workspace:/workspace \
  ...
```

---

## Desktop (Windows)

### Claude Code lento no Windows

**Sintoma:** Respostas demoram, tool calls lentas.
**Causa:** Windows Defender escaneando arquivos em tempo real.
**Solucao:** Adicionar exclusoes:
- `~/.claude/`
- `~/.npm/`
- `node_modules/`
- O diretorio do projeto atual

### Git bash vs PowerShell

**Sintoma:** Comandos Unix nao funcionam.
**Causa:** Claude Code no Windows usa bash por padrao, mas alguns terminais usam PowerShell.
**Solucao:** Garantir que o terminal usa Git Bash ou WSL.
