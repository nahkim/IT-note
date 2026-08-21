#!/bin/zsh
# 매일 IT 뉴스 노트 생성 (launchd com.nahkim.itnote-news 에서 호출)
# 위치: ~/it-note-job/run.sh
# 로그: ~/it-note-job/run.log
#
# [2026-08-21 구조 변경 — TCC(EPERM) 회피]
# 2026-08-07 claude 업데이트로 CLI 가 네이티브 바이너리(claude.exe, 번들 ID
# com.anthropic.claude-code)가 되면서 자기 자신이 TCC 심사 대상이 됐다.
# ~/Documents 는 TCC 보호 폴더인데 launchd 컨텍스트에는 승인 UI 가 없어
# kTCCServiceSystemPolicyDocumentsFolder / SystemPolicyAllFiles 요청이
# 즉시 거부(authValue=0, authReason=2) → claude 가 EPERM 으로 죽었다.
#  → 작업 트리를 Documents 밖(MIRROR)에 두고 거기서 claude 를 돌린 뒤 GitHub 에
#    push 하고, Obsidian 볼트는 platform binary 인 git 으로만 동기화한다.
#    (git 은 launchd 에서도 Documents 접근이 허용됨 — 8/13~8/21 로그로 확인)
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

MIRROR="/Users/nahkim/it-note-job/IT-note"             # 실제 작업 트리 (TCC 밖)
VAULT="/Users/nahkim/Documents/nahkim-github/IT-note"  # Obsidian 볼트 (동기화 전용)
LOGDIR="/Users/nahkim/it-note-job"
LOG="$LOGDIR/run.log"
PROMPT="$MIRROR/scripts/news-prompt.txt"
SELFTEST="$LOGDIR/.selftest"
mkdir -p "$LOGDIR"

{
  TS() { /bin/date '+%F %T %Z'; }
  TODAY=$(TZ=Asia/Seoul /bin/date +%F)
  NEWS="$MIRROR/04-뉴스/$TODAY.md"

  echo "===== $(TS) START (today=$TODAY) ====="

  cd "$MIRROR" || { echo "FATAL: cd mirror 실패 ($MIRROR)"; echo "===== $(TS) END (status=1) ====="; exit 1; }

  /usr/bin/git pull --rebase --autostash origin master || echo "WARN: mirror git pull 실패(계속 진행)"

  # 셀프테스트 모드: 노트를 만들지 않고 launchd 에서 claude 가 뜨는지만 확인
  if [ -f "$SELFTEST" ]; then
    echo "--- SELFTEST: claude 기동 확인 ($(TS)) ---"
    /opt/homebrew/bin/claude -p "Reply with exactly: SELFTEST-OK" \
      --model claude-haiku-4-5-20251001 </dev/null
    echo "selftest claude exit=$?"
    /bin/rm -f "$SELFTEST"
    echo "===== $(TS) END (selftest) ====="
    exit 0
  fi

  # 이미 오늘 뉴스가 있으면 스킵
  if [ -f "$NEWS" ]; then
    echo "SKIP: $TODAY.md 이미 존재"
    echo "===== $(TS) END (status=0, skipped) ====="
    exit 0
  fi

  # claude 최대 2회 시도 — 파일이 생기면 즉시 중단
  rc=1
  for attempt in 1 2; do
    echo "--- claude 시도 $attempt/2 ($(TS)) ---"
    /opt/homebrew/bin/claude -p "$(/bin/cat "$PROMPT")" \
      --model claude-opus-4-8 \
      --dangerously-skip-permissions </dev/null
    rc=$?
    echo "claude exit=$rc"
    [ -f "$NEWS" ] && break
    echo "WARN: 시도 $attempt 후에도 $TODAY.md 없음"
    [ "$attempt" -lt 2 ] && sleep 30
  done

  if [ ! -f "$NEWS" ]; then
    echo "FAIL: 뉴스 생성 실패 (claude last exit=$rc, 파일 없음)"
    echo "  ↳ 진단: touch $SELFTEST 후"
    echo "     launchctl kickstart -k gui/501/com.nahkim.itnote-news"
    echo "===== $(TS) END (status=1) ====="
    exit 1
  fi
  echo "OK: $TODAY.md 생성 확인 (mirror)"

  # claude 가 커밋/푸시를 못 했으면 여기서 마무리
  if [ -n "$(/usr/bin/git status --porcelain)" ]; then
    echo "WARN: 미커밋 변경 발견 → 직접 커밋"
    /usr/bin/git add "04-뉴스/$TODAY.md"
    /usr/bin/git commit -m "docs(뉴스): IT 뉴스 $TODAY" || echo "WARN: commit 실패"
  fi
  if ! /usr/bin/git push origin master; then
    echo "WARN: push 실패 → rebase 후 재시도"
    /usr/bin/git pull --rebase origin master && /usr/bin/git push origin master || echo "WARN: 재시도도 실패"
  fi

  # Obsidian 볼트 동기화 — Documents 를 건드리는 건 git(platform binary)뿐
  if /usr/bin/git -C "$VAULT" pull --ff-only origin master; then
    echo "OK: 볼트 동기화 완료 ($VAULT)"
  else
    echo "WARN: 볼트 ff-only pull 실패 — 볼트에 로컬 커밋/변경이 있을 수 있음. 수동 확인 필요."
  fi

  echo "===== $(TS) END (status=0) ====="
  exit 0
} >> "$LOG" 2>&1
