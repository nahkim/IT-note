#!/bin/zsh
# 매일 IT 뉴스 노트 생성 (launchd com.nahkim.itnote-news 에서 호출)
# 위치: ~/it-note-job/run.sh  (Documents 밖 → launchd TCC 회피)
# 로그: ~/it-note-job/run.log
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

REPO="/Users/nahkim/Documents/nahkim-github/IT-note"
LOGDIR="/Users/nahkim/it-note-job"
LOG="$LOGDIR/run.log"
PROMPT="$REPO/scripts/news-prompt.txt"
mkdir -p "$LOGDIR"

{
  TS() { /bin/date '+%F %T %Z'; }
  TODAY=$(TZ=Asia/Seoul /bin/date +%F)
  NEWS="$REPO/04-뉴스/$TODAY.md"

  echo "===== $(TS) START (today=$TODAY) ====="

  cd "$REPO" || { echo "FATAL: cd repo 실패"; echo "===== $(TS) END (status=1) ====="; exit 1; }

  # 이미 오늘 뉴스가 있으면 스킵
  if [ -f "$NEWS" ]; then
    echo "SKIP: $TODAY.md 이미 존재"
    echo "===== $(TS) END (status=0, skipped) ====="
    exit 0
  fi

  /usr/bin/git pull --rebase --autostash origin master || echo "WARN: git pull 실패(계속 진행)"

  # claude 최대 2회 시도 — 파일이 생기면 즉시 중단
  rc=1
  for attempt in 1 2; do
    echo "--- claude 시도 $attempt/2 ($(TS)) ---"
    /opt/homebrew/bin/claude -p "$(/bin/cat "$PROMPT")" \
      --model claude-opus-4-8 \
      --dangerously-skip-permissions
    rc=$?
    echo "claude exit=$rc"
    [ -f "$NEWS" ] && break
    echo "WARN: 시도 $attempt 후에도 $TODAY.md 없음"
    [ "$attempt" -lt 2 ] && sleep 30
  done

  # 결과 검증 → 실패면 non-zero 로 종료(launchd/로그에 드러나게)
  if [ -f "$NEWS" ]; then
    echo "OK: $TODAY.md 생성 확인"
    echo "===== $(TS) END (status=0) ====="
    exit 0
  else
    echo "FAIL: 뉴스 생성 실패 (claude last exit=$rc, 파일 없음)"
    echo "  ↳ 흔한 원인: 10시에 화면 잠금/절전 → Keychain 잠김으로 claude EPERM"
    echo "===== $(TS) END (status=1) ====="
    exit 1
  fi
} >> "$LOG" 2>&1
