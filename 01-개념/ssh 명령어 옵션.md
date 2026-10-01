---
type: 개념
domain: 네트워크
tags: [IT, 네트워크, CLI, 도구, 보안, 운영]
created: 2026-10-01
aliases: [ssh 명령어 옵션, ssh 옵션, ssh options, ssh -v, ssh -vvv, ssh -i, ssh 디버깅, ssh verbose, identity file, IdentitiesOnly, ssh -J, ssh -o, ssh -G, ssh config, ssh_config, ControlMaster, 멀티플렉싱, ssh 접속 안될 때]
---

# ssh 명령어 옵션 (`-v` · `-i` 외)

## 한 줄 정의
`ssh`는 **원격 호스트에 암호화된 연결을 맺는 클라이언트**이고, 옵션은 크게 **"어디로·누구로 붙나"(`-p` `-l` `-i`)**, **"무엇을 실어 나르나"(`-L` `-R` `-D` `-J`)**, **"어떻게 동작·기록하나"(`-N` `-f` `-v` `-o`)** 세 묶음으로 나뉜다.

## 질문한 두 옵션

### `-v` — 무슨 일이 벌어지는지 보여줘 (verbose)
```bash
ssh -v   user@host      # debug1  : 연결·인증 진행 상황
ssh -vv  user@host      # debug2  : 프로토콜 수준 상세
ssh -vvv user@host      # debug3  : 최대. 더 붙여도 의미 없다(최대 3)
```

- **출력은 표준출력이 아니라 `stderr`로 간다.** 그래서 파일로 남기려면 `ssh -vvv host 2> ssh.log` 또는 `-E 파일`(OpenSSH 전용 로그 파일). → [[표준 스트림]]
- 각 줄 앞의 `debug1/2/3`이 **그 줄을 보려면 v가 몇 개 필요했는지**를 뜻한다.
- 서버 쪽 로그는 별개다. 서버가 왜 거절했는지는 `/var/log/auth.log`·`journalctl -u sshd`를 봐야 하고, 더 보려면 `sshd_config`의 `LogLevel DEBUG`.

**읽는 법 — 어디까지 갔는지만 보면 된다.** `-v` 출력은 길지만 실제로는 **네 단계를 순서대로 통과**하는 기록이다.

| 로그에서 보이는 것 | 여기서 멈췄다면 |
|---|---|
| `Connecting to host port 22` 에서 멈춤 | **네트워크/방화벽 문제.** DNS·라우팅·보안그룹. ssh 문제가 아니다 |
| `Remote protocol version …` 까지 옴 | TCP·서버 데몬은 정상. 여기부터는 **인증 문제** |
| `Offering public key: …` 가 줄줄이 나옴 | 키를 **여러 개 들이밀고 있다** → 아래 `-i` 함정 |
| `Authentications that can continue: publickey` | 서버가 **비밀번호를 아예 안 받는다**. 키로 가야 함 |
| `Authenticated to host` 이후 | 로그인은 성공. 문제는 **셸·포워딩·권한 쪽** |

> 💡 **진단 1순위가 `-v`인 이유** — "ssh가 안 돼요"는 네트워크·인증·셸 중 어디서 깨졌는지 모르는 상태다. `-v` 한 번이면 **세 구간 중 어디인지**가 바로 갈린다. → [[러버덕 디버깅]]

### `-i` — 이 개인키로 인증해라 (identity file)
```bash
ssh -i ~/.ssh/deploy_key user@host
```
- 지정하지 않으면 기본 경로(`~/.ssh/id_ed25519`, `id_rsa` 등)를 순서대로 시도한다. 키가 한 벌뿐이면 `-i`는 필요 없다.
- **가리키는 건 개인키**(`.pub`가 아니다). 같은 이름의 `.pub`가 옆에 있으면 같이 활용한다.
- ⚠️ **권한이 엄격하다.** 개인키가 그룹·타인에게 읽히면 `UNPROTECTED PRIVATE KEY FILE` 에러로 **아예 거부**한다 → `chmod 600 ~/.ssh/deploy_key` (`~/.ssh`는 `700`).

> ⚠️ **`-i`의 1순위 함정 — "지정했는데 다른 키를 먼저 들이민다."**
> ssh 클라이언트는 **ssh-agent에 올라간 키들을 먼저 다 시도한 뒤에야** `-i`로 준 키를 쓴다. 서버의 `MaxAuthTries`(기본 6)를 넘기면 **정작 맞는 키를 내밀기 전에** `Too many authentication failures`로 끊긴다.
> ```bash
> ssh -o IdentitiesOnly=yes -i ~/.ssh/deploy_key user@host   # 준 키만 쓴다
> ```
> `-v`를 같이 켜면 `Offering public key:` 줄로 **무엇을 어떤 순서로 내밀었는지** 그대로 보인다. → [[SSH 공개키 인증]]

## 자주 쓰는 나머지 옵션

### 접속 대상·신원
| 옵션 | 뜻 | 메모 |
|---|---|---|
| `-p 2222` | 포트 지정 | ⚠️ `scp`·`sftp`는 대문자 `-P`다. 가장 흔한 혼동 |
| `-l user` | 사용자 지정 | `user@host` 형태가 더 흔함 |
| `-F ~/.ssh/other_config` | 설정 파일 지정 | `-F /dev/null`이면 설정 무시하고 순정으로 테스트 |
| `-o Key=Value` | 아무 설정 항목이나 1회성 지정 | `ssh_config`의 모든 항목을 쓸 수 있는 만능 옵션 |
| `-J user@bastion` | **ProxyJump** — 경유해서 접속 | 개인키가 경유지에 가지 않는다 → [[베스천 서버]] |

### 터널·포워딩 → [[터널링]]
| 옵션 | 뜻 |
|---|---|
| `-L 5432:db.internal:5432` | 로컬 포워딩 (내 포트 → 서버가 보는 주소) |
| `-R 8080:localhost:3000` | 리모트 포워딩 (서버 포트 → 내가 보는 주소) |
| `-D 1080` | 다이나믹 포워딩 (SOCKS 프록시) |
| `-A` | **에이전트 포워딩** — ⚠️ 경유지가 뚫리면 내 신원이 도용된다. `-J`로 대체할 것 |

### 실행 제어
| 옵션 | 뜻 | 쓰는 자리 |
|---|---|---|
| `-N` | 원격 명령 실행 안 함 | **터널 전용** 접속. 셸이 안 뜬다 |
| `-f` | 인증 후 백그라운드로 | `-fN` 조합이 터널 상주의 관용구 |
| `-T` / `-t` | TTY 할당 끄기 / 강제 켜기 | 스크립트는 `-T`, 원격에서 `sudo`·`top`은 `-t` |
| `-q` | 조용히(경고·진단 억제) | `-v`의 반대 |
| `-C` | 압축 | 느린 회선에서만 이득. 빠른 망에선 오히려 손해 |
| `-X` / `-Y` | X11 포워딩 / 신뢰 모드 | 원격 GUI. `-Y`는 보안 약함 |
| `-G` | **실제 적용되는 설정을 출력**(접속은 안 함) | "내 config가 먹고 있나" 확인용 |
| `-Q key` | 지원 알고리즘 목록 | 오래된 서버와 알고리즘 협상 실패 디버깅 |

### 끊김·속도에 효과가 큰 `-o` 설정
```bash
ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=3 user@host
```
- **`ServerAliveInterval`** — 조용한 연결에 주기적으로 신호를 보내 **NAT·방화벽이 연결을 잊지 않게** 한다. "가만히 두면 세션이 죽는" 문제의 표준 처방. → [[TCP Keepalive]] · [[긴 요청 응답 유실 (NAT 연결 만료)]]
- **`ConnectTimeout=5`** — 죽은 호스트에 매달리지 않게. 스크립트 필수.
- **멀티플렉싱** — 한 번 맺은 연결을 재사용해 두 번째부터 **연결 수립 비용을 0에 가깝게** 만든다. Ansible·배포 스크립트에서 체감이 크다. → [[Ansible]]
  ```
  Host *
      ControlMaster auto
      ControlPath   ~/.ssh/cm-%r@%h:%p
      ControlPersist 10m
  ```

### ⚠️ 쓰면 안 되는 쪽
- **`-o StrictHostKeyChecking=no`** — 호스트 키 검증을 꺼버린다. 즉 **중간자 공격을 탐지할 수단을 스스로 없애는 것.** 호스트 키가 바뀌어 막힌 거라면 원인을 확인하고 `ssh-keygen -R host`로 명시적으로 지울 것.
- **`-A`(에이전트 포워딩)** — 위 참조.
- **개인키를 `-i`로 가리키되 레포에 넣지 말 것.** 키·토큰은 코드와 같은 곳에 두지 않는다. → [[환경 변수]]

### 옵션 대신 `~/.ssh/config`로
같은 플래그를 매번 치고 있다면 설정 파일로 옮긴다. `-o`로 주던 건 전부 여기 쓸 수 있다.
```
Host web-1
    HostName       10.0.1.23
    User           deploy
    Port           2222
    IdentityFile   ~/.ssh/deploy_key
    IdentitiesOnly yes
    ProxyJump      bastion
    ServerAliveInterval 60
```
→ 이제 `ssh web-1` 한 줄. 적용 여부는 `ssh -G web-1`로 확인한다.

## 왜 중요한가
- **`-v`는 ssh 문제를 "네트워크냐 인증이냐 셸이냐"로 가르는 가장 빠른 칼**이다. 이 구분 없이 추측으로 설정을 고치면 시간만 쓴다.
- **`-i` + `IdentitiesOnly`는 키가 여러 개인 사람(회사·개인·배포용)이 반드시 아는 조합**이다. 모르면 "분명 맞는 키인데 거부당하는" 상황을 반복한다.
- **ssh는 접속 도구가 아니라 운반 도구다.** 포트 포워딩·ProxyJump·멀티플렉싱까지 보면, 배포·DB 접속·사설망 진입이 전부 이 명령 하나 위에 올라가 있다.
- **보안 옵션의 기본값에는 이유가 있다.** `StrictHostKeyChecking`·에이전트 포워딩처럼 "편하게 하려고 끄는" 설정이 곧 사고 경로가 된다.

## 관련 개념
- [[SSH 공개키 인증]] — 키 쌍·`authorized_keys`·에이전트의 원리
- [[터널링]] — `-L` `-R` `-D`가 실제로 무엇을 하는가
- [[베스천 서버]] — `-J`(ProxyJump)를 쓰는 전형적인 구조
- [[curl]] — 같은 결의 "한 줄로 확인하는" CLI 도구 노트
- [[표준 스트림]] — `-v` 출력이 stderr로 가는 이유
- [[TCP Keepalive]] · [[긴 요청 응답 유실 (NAT 연결 만료)]] — `ServerAliveInterval`이 막는 문제
- [[Ansible]] — 멀티플렉싱 효과가 가장 큰 곳
- [[환경 변수]] — 키·시크릿을 어디에 둘 것인가
- [[타임아웃]] — `ConnectTimeout` 설정의 배경

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — **`-v`는 중첩 가능하며 최대 3단계(`-vvv`)**, 디버그 출력이 **stderr**로 나가고 줄머리의 `debug1/2/3`이 필요한 verbosity를 뜻한다는 점을 OpenSSH 매뉴얼 및 복수 튜토리얼로 확인. **`-i`로 키를 지정해도 ssh-agent에 올라간 키들을 먼저 시도하기 때문에 서버의 `MaxAuthTries`를 넘겨 `Too many authentication failures`가 나며, `-o IdentitiesOnly=yes`가 표준 해법**이라는 점을 복수 트러블슈팅 문서로 확인. **`ssh -G`가 모든 설정 해석 후의 유효 설정을 출력**한다는 점, **`ControlMaster auto` + `ControlPath`(`%r@%h:%p` 토큰) + `ControlPersist`(yes 또는 시간)로 연결을 재사용해 두 번째 이후 접속이 극적으로 빨라진다**는 점, `ServerAliveInterval`이 운영 설정에서 연결 유지 용도로 쓰인다는 점을 OpenSSH Cookbook(Multiplexing) 및 복수 가이드로 확인. 개인키 권한이 느슨하면 `UNPROTECTED PRIVATE KEY FILE`로 거부되어 `chmod 600`이 필요하다는 점, `scp`/`sftp`의 포트 플래그가 대문자 `-P`인 점은 OpenSSH 매뉴얼 기준.
