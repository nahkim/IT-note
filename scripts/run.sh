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
#
# [2026-08-27 보강 — 8/22~8/24 3일 유실 사고 대응]
# 사고: 8/22 실행이 git pull 의 SSH 끊김 지점에서 멈춘 채 맥이 잠들어 프로세스가
# 3일간 정지. launchd 는 같은 label 의 인스턴스가 살아있으면 다음 예약을 건너뛰므로
# 8/23·8/24 는 시작조차 못 했다. 8/25 에 깨어났을 때 TODAY 는 시작 시점(8/22)
# 값이라 2026-08-22.md 를 찾았는데 claude 는 2026-08-25.md 를 만들어
# 성공을 FAIL 로 오판했다. 아래 4가지를 넣었다.
#   1) 락 + 워치독: 멈춘 이전 인스턴스를 강제 종료하고 진행 (사흘 정지 재발 방지)
#   2) 단계별 타임아웃: macOS 엔 timeout/gtimeout 이 없어 직접 구현 (run_limited)
#   3) TODAY 재계산: 시도마다 다시 구하고, 날짜 무관하게 새 노트 생성을 인정
#   4) 실패 알림: osascript 데스크톱 알림 — 조용한 실패를 없앤다
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

MIRROR="/Users/nahkim/it-note-job/IT-note"             # 실제 작업 트리 (TCC 밖)
VAULT="/Users/nahkim/Documents/nahkim-github/IT-note"  # Obsidian 볼트 (동기화 전용)
LOGDIR="/Users/nahkim/it-note-job"
LOG="$LOGDIR/run.log"
PROMPT="$MIRROR/scripts/news-prompt.txt"
SELFTEST="$LOGDIR/.selftest"
LOCK="$LOGDIR/.run.lock"
GIT_TIMEOUT=120        # git 네트워크 작업 (8/22 사고 지점)
CLAUDE_TIMEOUT=1500    # claude 1회 시도 = 25분 (정상 실행은 6분 내외)
STALE_AFTER=10800      # 이전 인스턴스가 3시간 넘게 살아있으면 멈춘 것으로 본다
mkdir -p "$LOGDIR"

{
  TS() { /bin/date '+%F %T %Z'; }
  KST_TODAY() { TZ=Asia/Seoul /bin/date +%F; }

  # 데스크톱 알림 — 조용한 실패를 막는다. 실패해도 본 작업엔 영향 없음.
  notify() {
    /usr/bin/osascript -e "display notification \"$1\" with title \"IT-note 뉴스 자동화\"" \
      >/dev/null 2>&1 || echo "WARN: 알림 전송 실패"
  }

  # 프로세스 트리를 죽인다. launchd 엔 tty 가 없어 job control(`setopt monitor`)이
  # 안 되므로 프로세스 그룹 kill 을 못 쓴다 → pgrep -P 로 자손을 직접 훑는다.
  # 순서가 핵심: 자손 목록을 먼저 확보한 뒤 '뿌리부터' 죽인다. 자식을 먼저 죽이면
  # sleep 을 기다리던 부모(워치독 서브셸)가 깨어나 다음 명령을 실행해버린다.
  collect_tree() {   # 뿌리 → 자손 순서(pre-order)로 pid 출력
    local p=$1 c
    echo "$p"
    for c in ${(f)"$(/usr/bin/pgrep -P $p 2>/dev/null)"}; do
      [ -n "$c" ] && collect_tree "$c"
    done
  }
  kill_tree() {      # kill_tree <시그널> <pid>
    local sig=$1 p
    for p in ${(f)"$(collect_tree $2)"}; do
      [ -n "$p" ] && /bin/kill "-$sig" "$p" 2>/dev/null
    done
  }

  # macOS 에는 timeout(1)/gtimeout(1) 이 없다(coreutils 미설치). 워치독 서브셸로 대체.
  # 사용법: run_limited <초> <명령...>   반환: 명령의 exit code, 타임아웃이면 124
  # 시한 초과 판정은 워치독이 남기는 마커 파일로 한다 — 종료 코드(143/137)로 추측하면
  # 명령 자신이 낸 시그널 종료와 구분되지 않는다.
  run_limited() {
    local limit=$1; shift
    local marker="$LOGDIR/.timeout.$$.$RANDOM"
    /bin/rm -f "$marker"
    "$@" &
    local pid=$!
    ( /bin/sleep "$limit"
      /usr/bin/touch "$marker"
      kill_tree TERM "$pid"
      /bin/sleep 10
      kill_tree KILL "$pid" ) &
    local watchdog=$!
    wait "$pid"; local rc=$?
    kill_tree KILL "$watchdog"
    wait "$watchdog" 2>/dev/null
    if [ -f "$marker" ]; then
      /bin/rm -f "$marker"
      echo "TIMEOUT: '$1' 이 ${limit}s 를 넘겨 강제 종료됨(자손 프로세스까지 정리)"
      return 124
    fi
    return $rc
  }

  TODAY=$(KST_TODAY)
  echo "===== $(TS) START (today=$TODAY) ====="

  # --- 1) 락 + 워치독: 멈춘 이전 인스턴스 정리 ---------------------------------
  if [ -f "$LOCK" ]; then
    oldpid=$(/bin/cat "$LOCK" 2>/dev/null)
    if [ -n "$oldpid" ] && /bin/kill -0 "$oldpid" 2>/dev/null; then
      lockage=$(( $(/bin/date +%s) - $(/usr/bin/stat -f %m "$LOCK") ))
      if [ "$lockage" -ge "$STALE_AFTER" ]; then
        echo "WARN: 이전 인스턴스(pid=$oldpid)가 ${lockage}s 째 정지 상태 → 강제 종료하고 계속"
        /bin/kill -KILL "$oldpid" 2>/dev/null
        notify "멈춰 있던 이전 실행을 강제 종료했습니다 (${lockage}초)"
      else
        echo "SKIP: 이전 인스턴스(pid=$oldpid)가 아직 정상 실행 중 (${lockage}s)"
        echo "===== $(TS) END (status=0, 중복 실행 회피) ====="
        exit 0
      fi
    else
      echo "NOTE: 죽은 락 파일 정리 (pid=$oldpid)"
    fi
  fi
  echo $$ > "$LOCK"
  trap '/bin/rm -f "$LOCK"' EXIT INT TERM

  cd "$MIRROR" || {
    echo "FATAL: cd mirror 실패 ($MIRROR)"
    notify "실패: 작업 디렉터리 접근 불가"
    echo "===== $(TS) END (status=1) ====="; exit 1
  }

  # --- 2) 타임아웃을 씌운 git pull (8/22 사고 지점) ---------------------------
  mirror_pull() { /usr/bin/git pull --rebase --autostash origin master; }
  run_limited "$GIT_TIMEOUT" mirror_pull || echo "WARN: mirror git pull 실패/시간초과(계속 진행)"

  # 셀프테스트 모드: 노트를 만들지 않고 launchd 에서 claude 가 뜨는지만 확인
  if [ -f "$SELFTEST" ]; then
    echo "--- SELFTEST: claude 기동 확인 ($(TS)) ---"
    selftest_claude() {
      /opt/homebrew/bin/claude -p "Reply with exactly: SELFTEST-OK" \
        --model claude-haiku-4-5-20251001 </dev/null
    }
    run_limited 180 selftest_claude
    echo "selftest claude exit=$?"
    /bin/rm -f "$SELFTEST"
    echo "===== $(TS) END (selftest) ====="
    exit 0
  fi

  # 이미 오늘 뉴스가 있으면 스킵
  if [ -f "$MIRROR/04-뉴스/$TODAY.md" ]; then
    echo "SKIP: $TODAY.md 이미 존재"
    echo "===== $(TS) END (status=0, skipped) ====="
    exit 0
  fi

  # --- 3) claude 최대 2회 시도 — TODAY 를 시도마다 재계산 ---------------------
  run_claude() {
    /opt/homebrew/bin/claude -p "$(/bin/cat "$PROMPT")" \
      --model claude-opus-4-8 \
      --dangerously-skip-permissions </dev/null
  }
  rc=1
  for attempt in 1 2; do
    # 실행이 길어져 자정을 넘겼을 수 있다. claude 는 자기가 계산한 KST 날짜로
    # 파일을 만드므로 여기서도 매번 다시 구해야 파일명이 어긋나지 않는다.
    NEW_TODAY=$(KST_TODAY)
    [ "$NEW_TODAY" != "$TODAY" ] && echo "NOTE: 날짜 변경 감지 $TODAY → $NEW_TODAY"
    TODAY="$NEW_TODAY"
    NEWS="$MIRROR/04-뉴스/$TODAY.md"

    echo "--- claude 시도 $attempt/2 (today=$TODAY, $(TS)) ---"
    run_limited "$CLAUDE_TIMEOUT" run_claude
    rc=$?
    echo "claude exit=$rc"
    [ "$rc" -eq 124 ] && notify "claude 가 ${CLAUDE_TIMEOUT}초를 넘겨 중단됐습니다 (시도 $attempt/2)"
    [ -f "$NEWS" ] && break
    echo "WARN: 시도 $attempt 후에도 $TODAY.md 없음"
    [ "$attempt" -lt 2 ] && sleep 30
  done

  # 날짜가 어긋났더라도 새 노트가 생겼으면 성공으로 인정한다 (8/25 오판 방지)
  TODAY=$(KST_TODAY)
  NEWS="$MIRROR/04-뉴스/$TODAY.md"
  CREATED=$(/usr/bin/git -c core.quotepath=false ls-files --others --exclude-standard -- "04-뉴스")

  if [ ! -f "$NEWS" ] && [ -z "$CREATED" ]; then
    echo "FAIL: 뉴스 생성 실패 (claude last exit=$rc, 새 노트 없음)"
    echo "  ↳ 진단: touch $SELFTEST 후"
    echo "     launchctl kickstart -k gui/501/com.nahkim.itnote-news"
    notify "실패: $TODAY 뉴스 노트를 만들지 못했습니다. run.log 를 확인하세요."
    echo "===== $(TS) END (status=1) ====="
    exit 1
  fi
  if [ -f "$NEWS" ]; then
    echo "OK: $TODAY.md 생성 확인 (mirror)"
  else
    echo "OK: 오늘 날짜와 다르지만 새 노트가 생성됨 → 그대로 커밋한다"
    echo "$CREATED"
  fi

  # claude 가 커밋/푸시를 못 했으면 여기서 마무리 (파일명 대신 폴더째 add)
  if [ -n "$(/usr/bin/git status --porcelain -- "04-뉴스")" ]; then
    echo "WARN: 미커밋 변경 발견 → 직접 커밋"
    /usr/bin/git add "04-뉴스"
    # 실제로 스테이징된 노트의 날짜를 커밋 메시지에 쓴다
    DATES=$(/usr/bin/git -c core.quotepath=false diff --cached --name-only \
            | /usr/bin/sed -n 's#^04-뉴스/\(2026-[0-9-]*\)\.md$#\1#p' | /usr/bin/tr '\n' ' ')
    [ -z "$DATES" ] && DATES="$TODAY"
    /usr/bin/git commit -m "docs(뉴스): IT 뉴스 ${DATES% }" || echo "WARN: commit 실패"
  fi

  mirror_push() { /usr/bin/git push origin master; }
  if ! run_limited "$GIT_TIMEOUT" mirror_push; then
    echo "WARN: push 실패/시간초과 → rebase 후 재시도"
    run_limited "$GIT_TIMEOUT" mirror_pull && run_limited "$GIT_TIMEOUT" mirror_push \
      || { echo "WARN: 재시도도 실패"; notify "GitHub push 에 실패했습니다. 수동 확인 필요."; }
  fi

  # Obsidian 볼트 동기화 — Documents 를 건드리는 건 git(platform binary)뿐
  vault_pull() { /usr/bin/git -C "$VAULT" pull --ff-only origin master; }
  if run_limited "$GIT_TIMEOUT" vault_pull; then
    echo "OK: 볼트 동기화 완료 ($VAULT)"
  else
    echo "WARN: 볼트 ff-only pull 실패 — 볼트에 로컬 커밋/변경이 있을 수 있음. 수동 확인 필요."
    notify "볼트 동기화 실패 — 볼트에 로컬 변경이 있는지 확인하세요."
  fi

  echo "===== $(TS) END (status=0) ====="
  exit 0
} >> "$LOG" 2>&1
