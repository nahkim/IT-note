---
type: 기술노트
domain: 인프라
tags: [IT, 노트, 네트워크, 인프라, 보안, SSH, Docker, 운영]
출처: (실무 정리 — ProxyCommand 점프 접속 · jnovack/autossh 컨테이너 터널 · 공식 저장소 entrypoint 확인)
종류: 정리
읽은날: 2026-10-27
별점: 
aliases: [베스천 경유 접속, ProxyCommand, ssh -W, 점프 호스트 접속, 상시 터널, autossh, jnovack/autossh, SSH 터널 컨테이너, DB 터널, RDS 터널, 로컬 포워딩 컨테이너, ssh -L 도커, 15432, 터널 생존 확인, docker-proxy, SSLRequest 핸드셰이크]
---

# 📝 베스천 경유 접속과 상시 DB 터널 (ProxyCommand · autossh 컨테이너)

> 🔒 **이 노트의 호스트·엔드포인트는 전부 자리표시자다.** 실제 값은 커밋하지 않는다.
> `BASTION_IP`(베스천 공인 IP) · `PRIVATE_IP`(사설 서버) · `DB_ENDPOINT`(RDS 엔드포인트) · `~/.ssh/myproj.pem`(개인키)

## 한 줄 요약
사설망 자원에 닿는 방법은 **목적에 따라 둘로 갈린다.** 사설 서버에서 **셸을 잡고 싶으면** `ProxyCommand`(또는 `-J`)로 베스천을 **일회성 통로**로 쓰고, DB처럼 **로컬 툴(DBeaver·psql)이 TCP 포트로 붙어야 하면** `-L` 로컬 포워딩을 **상시로** 띄워 둔다. 후자를 끊김 없이 유지하려고 쓰는 게 `autossh` 컨테이너다. **둘 다 베스천은 암호문만 중계하고 개인키는 올라가지 않는다.**

## 핵심 내용

### 1. 전체 그림 — 같은 베스천, 다른 목적

```
                                   ┌──▶ [사설 EC2 PRIVATE_IP:22]   ← ① 셸이 필요
  [내 PC] ──SSH(22)──▶ [베스천]────┤
                      BASTION_IP   └──▶ [RDS DB_ENDPOINT:5432]     ← ② 포트가 필요
                                        (RDS는 셸이 없다. 포트뿐)

  ① ssh -o ProxyCommand=… / ssh -J   : 필요할 때 열고 끝나면 닫는 터미널 세션
  ② docker run … autossh (-L)        : 백그라운드 상주. localhost:15432 가 DB처럼 보임
```

> 🔑 **구분 기준은 "내가 원격에서 명령을 치느냐"다.** 명령을 친다 → ①. 내 PC의 **다른 프로그램**이 붙어야 한다 → ②.
> → [[베스천 서버]] · [[터널링]]

---

### 2. ① 셸 접속 — `ProxyCommand` + `-W`

```bash
ssh -o ProxyCommand="ssh -i ~/.ssh/myproj.pem -W %h:%p ec2-user@BASTION_IP" \
    -i ~/.ssh/myproj.pem ec2-user@PRIVATE_IP
```

| 조각 | 의미 |
|---|---|
| `-o ProxyCommand="…"` | 목적지에 직접 TCP를 열지 않고, **따옴표 안 명령이 만든 통로(stdin/stdout)** 를 연결 채널로 쓴다 |
| 안쪽 `ssh … ec2-user@BASTION_IP` | 베스천에 먼저 로그인 |
| `-W %h:%p` | 베스천에서 **셸을 띄우지 않고 TCP 포워딩만** 수행. `%h`→`PRIVATE_IP`, `%p`→`22`로 치환 |
| 바깥 `-i`, `ec2-user@PRIVATE_IP` | **최종 목적지** 인증·접속 (여기선 양쪽이 같은 키페어) |

**동작 순서**
1. 로컬 ssh가 ProxyCommand를 **먼저** 실행 → 베스천 접속
2. 베스천이 `PRIVATE_IP:22`로 소켓을 열고 stdin/stdout에 이어붙임
3. 로컬 ssh가 그 통로 위에서 **최종 서버와 직접** 키 교환·인증

> ✅ **이 구조의 핵심 이득** — 2단계 암호화가 **중첩**되므로 베스천은 암호문만 본다. 개인키를 베스천에 복사하거나 `ssh -A`(에이전트 포워딩)를 쓸 필요가 없다. → [[SSH 공개키 인증]]

**`-W` vs `nc` vs `-J`**

| 방식 | 형태 | 비고 |
|---|---|---|
| `-W %h:%p` | 위 명령 | OpenSSH 5.4+. 베스천에 **추가 바이너리 불필요** |
| `nc %h %p` | `ProxyCommand="ssh bastion nc %h %p"` | 옛 방식. 베스천에 `nc` 설치 필요, 종료 처리도 지저분 |
| **`-J`(ProxyJump)** | `ssh -J ec2-user@BASTION_IP ec2-user@PRIVATE_IP` | **OpenSSH 7.3+(2016) 권장.** 위 ProxyCommand와 사실상 동일 |

⚠️ `-J` 한 줄로 줄일 때 **`-i`는 최종 목적지에만 적용**된다. 베스천 키가 다르면 config로 분리할 것.

**`~/.ssh/config` 에 박아두기 — 결국 이게 정답**
```sshconfig
Host myproj-bastion
    HostName BASTION_IP
    User ec2-user
    IdentityFile ~/.ssh/myproj.pem

Host myproj-private
    HostName PRIVATE_IP
    User ec2-user
    IdentityFile ~/.ssh/myproj.pem
    ProxyJump myproj-bastion
```
→ 이후 `ssh myproj-private` 한 줄. `scp`·`rsync`·VS Code Remote-SSH도 **같은 설정을 그대로 쓴다**(명령줄 `-o`는 그것들이 못 읽는다). → [[ssh 명령어 옵션]]

> 💡 `PRIVATE_IP`가 `172.31.x.x`면 **AWS 기본(default) VPC 대역**이다. `10.x`·`192.168.x`와 함께 [RFC 1918] 사설 대역이라 인터넷에서 직접 못 간다 — 그래서 베스천이 필요한 것.

---

### 3. ② 상시 DB 터널 — autossh 컨테이너

```bash
docker run -d \
  --name ssh-tunnel \
  --restart unless-stopped \
  -p 127.0.0.1:15432:15432 \
  -v ~/.ssh/myproj.pem:/id_rsa:ro \
  -e SSH_MODE=-L \
  -e SSH_REMOTE_USER=ec2-user \
  -e SSH_REMOTE_HOST=BASTION_IP \
  -e SSH_TARGET_HOST=DB_ENDPOINT \
  -e SSH_TARGET_PORT=5432 \
  -e SSH_TUNNEL_PORT=15432 \
  -e SSH_BIND_IP=0.0.0.0 \
  jnovack/autossh:latest
```

**이게 실제로 만드는 명령** (이미지 `entrypoint.sh` 기준)
```bash
autossh -M 0 -N \
  -o StrictHostKeyChecking=no \
  -o ServerAliveInterval=10 -o ServerAliveCountMax=3 \
  -o ExitOnForwardFailure=yes -t -t \
  -L 0.0.0.0:15432:DB_ENDPOINT:5432 \
  -p 22 ec2-user@BASTION_IP
```

**경로**
```
 DBeaver / psql
   │ localhost:15432
   ▼
 [ 호스트 127.0.0.1:15432 ]        ← -p 127.0.0.1:15432:15432 (외부 노출 차단)
   │ docker 포트 매핑
   ▼
 [ 컨테이너 0.0.0.0:15432 ]        ← SSH_BIND_IP=0.0.0.0 (여기가 함정, §4)
   │ SSH 암호화 터널(22)
   ▼
 [ 베스천 BASTION_IP ]
   │ 사설망 평문 TCP
   ▼
 [ RDS DB_ENDPOINT:5432 ]
```

**변수 읽는 법 — 세 쌍으로 나뉜다**

| 묶음 | 변수 | 뜻 | 기본값 |
|---|---|---|---|
| **어디로 SSH 하나** | `SSH_REMOTE_USER` / `SSH_REMOTE_HOST` / `SSH_REMOTE_PORT` | **베스천**(터널을 중계할 서버) | `root` / `localhost` / `22` |
| **최종 목적지** | `SSH_TARGET_HOST` / `SSH_TARGET_PORT` | 터널이 **끝나는 곳**. 여기선 RDS | `localhost` / `22` |
| **입구** | `SSH_BIND_IP` / `SSH_TUNNEL_PORT` | 터널 **입구 주소·포트** | `127.0.0.1` / 32768+ 랜덤 |
| 방향 | `SSH_MODE` | `-L`(로컬 포워딩) / `-R`(리모트) / `-D`(SOCKS) | **`-R`** |
| 키 | `SSH_KEY_FILE` | 개인키 경로 | **`/id_rsa`** |

> ⚠️ **`SSH_MODE` 기본값이 `-R`이다.** 명시하지 않으면 "내 포트를 원격에 열어주는" **정반대 동작**을 한다. `-L`을 반드시 적을 것. → [[터널링]]의 정방향/리버스 구분.

**`5432`가 아니라 `15432`인 이유** — 로컬에 PostgreSQL이 이미 5432를 쓰고 있어도 충돌하지 않게 한다. `15432`에 특별한 의미는 없다(관례적으로 `1` + 원포트).

---

### 4. 함정 세 가지 — 실제로 걸리는 것들

#### ⚠️ ① `SSH_BIND_IP=0.0.0.0` 은 "전체 공개"가 아니다
언뜻 위험해 보이지만, **컨테이너 안에서의** 바인딩이다.
- Docker의 `-p` 포워딩은 컨테이너의 **eth0 IP**로 들어온다. 컨테이너 안에서 `127.0.0.1`에만 바인딩하면 **그 패킷이 닿지 못해 연결이 안 된다.** → 그래서 안쪽은 `0.0.0.0`이어야 한다.
- 실제 노출 범위를 결정하는 건 **호스트 쪽 `-p 127.0.0.1:15432:15432`의 앞부분**이다. 이게 있어서 **내 PC에서만** 접근 가능하고 같은 사무실 LAN에서는 못 붙는다.

> 🔑 **`-p` 의 `127.0.0.1:` 접두사를 빼면 그 순간 LAN 전체에 운영 DB 포트가 열린다.** 두 값은 세트로 읽어야 한다.

#### ⚠️ ② `STRICT_HOSTS_KEY_CHECKING=no` 는 **이 이미지가 읽지 않는 변수다**
- 자주 같이 복사되는 줄이지만 **오타성 변수명**이다. 실제 이미지가 보는 건 `SSH_STRICT_HOST_IP_CHECK`(기본 `true`).
- 그런데도 잘 돌아간 이유: entrypoint는 **`/known_hosts` 파일이 마운트되어 있을 때만** `StrictHostKeyChecking=yes`로 올린다. 마운트하지 않았으니 **처음부터 `no`** 였다.
- 즉 저 줄은 **무해하지만 무의미**하다. 지워도 동작은 같다.
- 🔒 제대로 할 거면 반대로 가야 한다 — `known_hosts`를 만들어 마운트하고 **검증을 켜는** 쪽:
  ```bash
  ssh-keyscan -H BASTION_IP > ./known_hosts
  docker run ... -v $PWD/known_hosts:/known_hosts:ro ...
  ```
  검증을 끄면 중간자(MITM)가 베스천을 가장해도 **그대로 붙는다**.

#### ⚠️ ③ 개인키 마운트 — 권한 에러는 왜 안 났나
- 보통 `.pem`은 `chmod 600`이 아니면 ssh가 `UNPROTECTED PRIVATE KEY FILE`로 거부한다.
- 이 이미지는 `ssh-add -k - < $SSH_KEY_FILE` 로 **표준입력으로 읽어 에이전트에 올리기** 때문에 파일 권한 검사를 타지 않는다. → [[표준 스트림]]
- 대신 **키가 컨테이너 안에 존재**한다는 사실은 그대로다. `:ro`는 최소한의 방어일 뿐이고, 더 가려면 Docker Secret(`/run/secrets/…`)을 쓴다. 🔒 **암호(passphrase) 없는 키여야 자동 기동된다** — 상시 터널의 근본적 트레이드오프.

---

### 5. autossh가 `ssh -L` 보다 나은 점 — 그리고 `-M 0`

맨손 `ssh -fN -L …`의 문제는 **죽어도 아무도 모른다**는 것이다. NAT 타임아웃·노트북 절전·와이파이 전환이면 세션이 조용히 끊기고, DBeaver는 "Connection refused"만 뱉는다. → [[긴 요청 응답 유실 (NAT 연결 만료)]]

| 층 | 무엇을 복구하나 |
|---|---|
| `ServerAliveInterval=10` / `CountMax=3` | **약 30초** 무응답이면 ssh가 스스로 죽는다 (죽어야 재시작된다) |
| `autossh` | 죽은 ssh를 **즉시 다시 띄운다** |
| `--restart unless-stopped` | 컨테이너·도커·**PC 재부팅** 후에도 되살아난다 |

- **`-M 0`**: autossh의 옛 감시 방식(에코용 포트 2개 왕복)을 끈 것. 요즘은 **`ServerAliveInterval`에 맡기는 게 권장**이며 이 이미지 기본값이다.
- **`-N`**: 원격 명령 없이 포워딩만. **`ExitOnForwardFailure=yes`**: 포트 바인딩 실패 시 "붙었는데 터널은 없는" 유령 상태 대신 **그냥 죽는다**(그래야 재시도).
- → [[TCP Keepalive]] (커널 레벨)와 `ServerAliveInterval`(SSH 레벨)은 **다른 층**이다. 터널엔 후자를 쓴다.

---

### 6. 운영 — 확인·정리

```bash
docker logs -f ssh-tunnel                 # [INFO] Tunneling … / 재연결 로그
docker exec ssh-tunnel netstat -tlnp      # 15432 LISTEN 확인
nc -vz 127.0.0.1 15432                    # ⚠️ 이건 터널 생사를 알려주지 않는다 (아래 §6-1)
psql -h 127.0.0.1 -p 15432 -U myuser -d mydb   # 실제 접속

docker stop ssh-tunnel && docker rm ssh-tunnel  # 해제 (stop만 하면 재부팅 시 안 뜸)
```

#### ⚠️ 6-1. `nc -vz` 로는 터널이 살았는지 알 수 없다

**포트를 여는 주체가 터널이 아니라 도커이기 때문이다.** `-p 127.0.0.1:15432:15432` 를 붙이는 순간 `docker-proxy` 가 호스트에 LISTEN을 걸고, 이건 **컨테이너 안의 ssh가 죽어 있어도 그대로 열려 있다.**

```
 nc -vz 127.0.0.1 15432  →  succeeded!   ← docker-proxy 가 받은 것뿐
                                            베스천까지 갔는지는 전혀 모름
```

실제로 겪은 상황 — 컨테이너 로그에 `ssh: connect to host … port 22: Connection refused` 가 **4,091줄** 쌓여 있는 동안에도 `:15432` 는 계속 "열려" 있었다. 터널은 몇 시간째 끊겨 있었고, 포트 검사만으로는 아무 이상이 없었다.

**제대로 확인하는 법 — 끝단까지 말을 걸어 본다**
```bash
# PostgreSQL SSLRequest 패킷(8바이트)을 보내고 한 글자 응답을 본다
printf '\x00\x00\x00\x08\x04\xd2\x16\x2f' | nc -w 5 127.0.0.1 15432 | xxd
#   53 ('S')  → 터널 너머에 진짜 PostgreSQL 이 있고 SSL 수락   ✅
#   4e ('N')  → PostgreSQL 은 있는데 SSL 거부
#   (무응답)   → 터널이 죽었다. 포트만 열려 있는 상태            🚨
```
자격증명을 보내지 않는 **프로토콜 핸드셰이크 한 번**이라 안전하고, `psql` 설치도 필요 없다.

```bash
# 로그 쪽에서 보는 법 — 최근 실패가 언제였나
docker logs --timestamps --tail 50 ssh-tunnel
docker logs ssh-tunnel 2>&1 | grep -c "Connection refused"   # 쌓인 실패 횟수
```

> 🔑 **"조용하면 붙어 있는 것"** — `AUTOSSH_LOGLEVEL=0` 에서는 성공 시 아무것도 안 찍는다. 마지막 로그 줄의 **시각**을 보는 게 상태 확인이다. 실패가 계속되면 몇 초 간격으로 줄이 쌓인다.

#### ⚠️ 6-2. `5432` 와 `15432` — 포트 하나 차이로 운영 DB

로컬 개발용 PostgreSQL 컨테이너를 같이 띄워 두면, **둘 다 호스트가 `localhost`** 가 된다.

| 접속 주소 | 실제로 닿는 곳 | 위험 |
|---|---|---|
| `localhost:5432` | 로컬 개발 DB (도커 컨테이너) | 없음 |
| `localhost:15432` | **운영 RDS** (터널 경유) | **쓰면 운영 데이터가 바뀐다** |

- DB 툴의 접속 목록에서 둘 다 "localhost"로 보이므로, **이름에 `PROD` 를 박아 두고** 가능하면 읽기 전용 계정을 쓴다.
- 로컬 개발 DB는 보통 `-p 5432:5432`(= `0.0.0.0`)로 띄우는데, 이러면 **같은 와이파이의 다른 기기에서 보인다.** 비밀번호가 `postgres`/프로젝트명 같은 개발용이면 밖에서는 `-p 127.0.0.1:5432:5432` 로 바꾸는 게 맞다 — §4-① 과 **같은 함정**이다.

**DBeaver 설정 시 핵심**: Host는 `127.0.0.1`, Port `15432`. ⚠️ **DBeaver 자체의 "SSH 터널" 탭은 켜지 않는다** — 이미 터널이 있으므로 이중이 된다.

**대안 비교**

| 방법 | 장점 | 단점 |
|---|---|---|
| `docker run autossh` | 환경 독립·재부팅 복구·팀 공유 쉬움 | 컨테이너 안에 키 존재 |
| `ssh -fN -L` + config | 가볍고 즉시 | 끊기면 수동 복구 |
| `autossh` 바이너리 + `launchd`/`systemd` | 도커 불필요 | OS별 설정 상이 → [[systemd]] |
| **AWS SSM Session Manager** | **베스천·22번 포트·키 자체가 불필요**, IAM으로 통제·감사 | 에이전트·IAM 권한 선행 작업 |

> 💡 **장기적으로는 SSM 포트 포워딩이 더 낫다.** 베스천 유지보수·키 배포·22번 노출이 전부 사라지고, 접근 기록이 CloudTrail에 남는다. → [[베스천 서버]]의 "베스천을 아예 없애는 길".

## 기억할 문장 / 핵심 포인트
> **"셸이 필요하면 `-J`, 포트가 필요하면 `-L`."** RDS처럼 셸이 없는 자원은 무조건 후자다.
> **`-W`/`-J`는 개인키를 베스천에 올리지 않는다.** 베스천은 암호문만 중계한다 — 에이전트 포워딩(`-A`)을 습관적으로 쓰지 말 것.
> **`SSH_BIND_IP=0.0.0.0`(컨테이너 안) + `-p 127.0.0.1:…`(호스트) 는 세트다.** 노출을 막는 건 뒤쪽이며, 앞쪽이 없으면 아예 연결이 안 된다.
> **`STRICT_HOSTS_KEY_CHECKING`은 존재하지 않는 변수** — 되는 이유가 "설정해서"가 아니라 "원래 꺼져 있어서"인 경우를 조심.
> **포트가 열려 있다고 터널이 살아 있는 게 아니다.** 포트를 여는 건 `docker-proxy`지 ssh가 아니다 — 생사는 **끝단까지 말을 걸어** 확인한다.
> **`localhost:5432`와 `localhost:15432`는 호스트가 같다.** 포트 숫자 하나가 로컬 DB와 운영 DB를 가른다.
> **상시 터널의 대가는 "암호 없는 개인키가 항상 살아 있다"는 것.** 편의와 위험이 같은 곳에서 나온다.

## 등장하는 개념
- [[베스천 서버]] — 왜 한 대를 거쳐야 하는가, ProxyJump가 정답인 이유
- [[터널링]] — `-L`/`-R`/`-D` 구분, 정방향 vs 리버스
- [[ssh 명령어 옵션]] — `-i`·`-o`·`-N`·`-v`, `~/.ssh/config`
- [[SSH 공개키 인증]] — 키가 베스천에 올라가면 안 되는 이유
- [[컨테이너와 Docker]] — `-p` 포트 매핑·`--restart`·볼륨 `:ro`
- [[TCP Keepalive]] · [[긴 요청 응답 유실 (NAT 연결 만료)]] — 끊김이 생기는 메커니즘
- [[환경 변수]] — `-e`로 주입되는 설정과 기본값의 함정
- [[관계형 데이터베이스와 SQL]] — 터널 너머의 목적지(PostgreSQL 5432)
- [[표준 스트림]] — `-W`의 stdin/stdout 통로, `ssh-add -` 입력

## 내 생각 / 적용할 점
- `~/.ssh/config`에 `ProxyJump`로 박아두면 `scp`·VS Code Remote-SSH까지 한 번에 해결된다 → **명령줄 `-o`를 매번 치는 습관부터 없애기**
- `STRICT_HOSTS_KEY_CHECKING` 줄은 지우고, 대신 `ssh-keyscan`으로 `known_hosts` 만들어 **검증을 켜는 쪽**으로 바꿔보기
- 운영 DB 터널은 결국 **SSM Session Manager**로 옮기는 게 맞다. 베스천·키·22번 포트가 전부 사라짐

---
> ✅ **웹 교차검증 완료** — `jnovack/autossh` 공식 저장소의 `rootfs/entrypoint.sh` 원문으로 ① `SSH_MODE` 기본값이 `-R`, ② `SSH_KEY_FILE` 기본 `/id_rsa`, ③ `SSH_BIND_IP` 기본 `127.0.0.1`, ④ 실제 변수명은 `SSH_STRICT_HOST_IP_CHECK`이며 `STRICT_HOSTS_KEY_CHECKING`은 **읽히지 않음**, ⑤ `/known_hosts` 미마운트 시 `StrictHostKeyChecking=no`가 기본, ⑥ 조립되는 명령이 `autossh -M 0 -N -o ServerAliveInterval=10 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -t -t`임을 확인. `-W`/`ProxyJump`(OpenSSH 7.3+)·RFC 1918 사설 대역은 OpenSSH 문서 기준.
