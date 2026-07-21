#!/bin/zsh
# 매일 IT 뉴스 노트 생성 (launchd com.nahkim.itnote-news 에서 호출)
# 로그: ~/it-note-job/run.log  (repo 밖 — git 오염 방지)
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
REPO="/Users/nahkim/Documents/nahkim-github/IT-note"
LOGDIR="/Users/nahkim/it-note-job"
mkdir -p "$LOGDIR"

cd "$REPO" || exit 1

{
  echo "===== $(/bin/date '+%F %T %Z') START ====="
  /usr/bin/git pull --rebase --autostash origin master || true
  /opt/homebrew/bin/claude -p "$(/bin/cat "$REPO/scripts/news-prompt.txt")" \
    --model claude-opus-4-8 \
    --dangerously-skip-permissions
  echo "===== $(/bin/date '+%F %T %Z') END ====="
} >> "$LOGDIR/run.log" 2>&1
