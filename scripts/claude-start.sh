#!/data/data/com.termux/files/usr/bin/bash
# TRIFORCE — Claude Code starter for Termux (fixes /tmp)
# Usage: ~/claude-start.sh [claude args...]

export TMPDIR=$PREFIX/tmp
export TMP=$PREFIX/tmp
export TEMP=$PREFIX/tmp
export TEMPDIR=$PREFIX/tmp

exec proot -0 -b $PREFIX/tmp:/tmp -w $HOME $PREFIX/bin/env TMPDIR=$PREFIX/tmp claude "$@"
