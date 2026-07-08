---
type: 기술노트
tags: [IT, 노트, 네트워크, 트러블슈팅]
출처: (실무 디버깅 — steno STT 파이프라인)
종류: 사례정리
읽은날: 2026-07-08
별점: 
aliases: [STT 504, 응답 유실, NAT 연결 만료, 긴 요청 응답 유실, cold path 504]
---

# 📝 긴 요청 응답 유실 — NAT/터널 연결 만료와 TCP Keepalive

## 한 줄 요약
GPU STT가 **~156초 동안 침묵하며 처리**하는 사이, 중간 NAT/방화벽이 그 조용한 TCP 연결을 **표에서 지워버려서**, GPU가 끝나고 보낸 **200 응답이 돌아올 길을 잃고 유실**됐다(→ nginx 504 → 재시도). WireGuard keepalive(25s)는 **바깥 터널만** 지켜서 못 막았고, **안쪽 TCP 연결에 TCP keepalive**를 걸어 해결.

## 핵심 내용

### 1. 증상
- 구성: `worker(NKS) → nginx(gateway) → WireGuard 터널 → GPU 박스:8082(Ray Serve STT)`
- **idle 상태에서 첫 업로드가 거의 항상 실패**: 워커가 `GPU 호출` 후 응답을 못 받고 nginx `proxy_read_timeout`에 걸려 **504** → 15초 뒤 재시도 → **2번째엔 156초에 정상 성공**.
- 그런데 GPU는 내내 멀쩡히 돌고 있었음(연산 포화 sm~100%, 정상 완료).

### 2. 결정타 — GPU 로그 vs 워커 로그 교차검증
- **GPU serve 로그**: 잡 `93a60e23` 07:25:41 시작 → **07:28:20 완료 → `POST / 200 158769ms`** (정상 완료 + 200 송신)
- **워커 로그**: 같은 잡 07:25:41 `GPU 호출` → **07:31:41 504** (그 200을 끝내 못 받음)
- → **GPU 무죄. 200이 리턴 경로에서 유실**됐음이 확정. 같은 오디오를 두 번 처리(자원 낭비).

### 3. 원인 — 조용한 연결의 상태 만료 (→ [[TCP Keepalive]])
- NAT/방화벽은 연결을 **conntrack 표**에 기억하고, **idle 타임아웃** 후 지운다.
- STT는 `요청 → 156초 완전 침묵 → 응답` 구조라, 그 침묵이 타임아웃을 넘기면 표가 지워짐 → 뒤늦은 200이 drop.
- **idle 오래 뒤 첫 잡**이 특히 잘 터짐(경로가 완전히 식음). 직전에 트래픽이 있으면(재시도·연속 잡) warm이라 대체로 통과 → 경계에서 racy.

### 4. 2계층 함정 — WG keepalive가 왜 안 통했나
```
┌─ 바깥: WireGuard 터널 (UDP) ───────────────────────────────┐
│   gateway ⇄ GPU박스 / PersistentKeepalive=25 → 25s마다 톡톡 ✅ │
│                                                             │
│   ┌─ 안쪽: 진짜 데이터 (TCP) ─────────────────────────┐        │
│   │   nginx → GPU:8082 HTTP / 156초 침묵 ❌ 여기가 죽음  │        │
│   └────────────────────────────────────────────────────┘        │
└───────────────────────────────────────────────────────────┘
```
- WG `PersistentKeepalive=25`는 **바깥 UDP 터널**만 25초마다 살린다.
- 실제로 죽은 건 그 **안에 감싸인 TCP 연결**의 상태. WG keepalive 패킷은 안쪽 TCP 입장에선 트래픽이 아니다.
- **교훈: 터널을 살려두는 것 ≠ 터널 안 모든 연결을 살려두는 것.**

### 5. 수정
- nginx `location = /stt`에 **`proxy_socket_keepalive on;`** (upstream 소켓 `SO_KEEPALIVE`)
- 게이트웨이 파드 netns에 **`tcp_keepalive_time=30 / intvl=15 / probes=4`** (privileged initContainer로 `/proc/sys/...`에 기록). 기본 7200s는 156초 window에 무의미 → **반드시 낮춰야** probe가 나감.
- → 추론 중에도 30초마다 keepalive probe가 그 flow에 흘러 conntrack 유지 → 200이 살아 돌아옴.
- (별개 완화) `proxy_read_timeout` 1800s→360s: 유실 자체는 못 막지만 실패를 **30분→6분**에 띄워 재시도 복구를 빠르게.

### 6. 더 튼튼한 해법
- **비동기 전환**: "시작" 요청만 짧게 → job id → 상태 [[폴링]]. 156초짜리 긴 연결 자체가 사라져 이 문제 클래스가 소멸(+ 단일 워커 head-of-line blocking도 해소).
- **하트비트/스트리밍**: 처리 중 주기적으로 바이트를 흘려 연결이 침묵하지 않게.

## 코드 / 예시
```nginx
# gateway nginx — /stt location
proxy_read_timeout 360s;        # 유실 시 6분에 실패→재시도 (완화)
proxy_socket_keepalive on;      # ★ upstream 소켓에 TCP keepalive
```
```sh
# gateway 파드 netns (privileged initContainer) — 간격을 짧게
echo 30 > /proc/sys/net/ipv4/tcp_keepalive_time    # 기본 7200s → 30s
echo 15 > /proc/sys/net/ipv4/tcp_keepalive_intvl
echo 4  > /proc/sys/net/ipv4/tcp_keepalive_probes
```

## 기억할 문장 / 핵심 포인트
> "**오래 걸리는 동기 요청을, NAT/터널 너머로, 중간 트래픽 없이 한 연결로 붙잡지 마라.**" 조용한 연결은 NAT가 잊어버린다.
> keepalive는 **켜는 것보다 간격이 중요** — 기본 7200초는 무의미, 문제 window보다 짧게.
> 계층마다 keepalive가 따로 필요하다: WG(바깥 터널) ≠ TCP(안쪽 연결).
> "GPU가 200을 보냈다"와 "클라이언트가 200을 받았다"는 다르다 — **로그를 양쪽에서 겹쳐봐야** 유실을 잡는다.

## 등장하는 개념
- [[TCP Keepalive]] — 핵심 원리·해법
- [[TCP-IP]] — TCP 연결의 상태성(왜 idle이 문제인가)
- [[리버스 프록시]] — nginx가 유실 지점(upstream 연결)
- [[타임아웃]] · [[재시도와 백오프]] — 504 판정과 워커의 자동 재시도
- [[동기와 비동기]] · [[폴링]] — 근본 해법(비동기 전환)
- [[쿠버네티스]] · [[컨테이너와 Docker]] — gateway 파드·initContainer로 sysctl 주입
- [[S3 Presigned URL]] · [[STT 음성 인식]] · [[오디오 녹음 파이프라인]] — 같은 STT 파이프라인 맥락

## 내 생각 / 적용할 점
-

---
> 🔧 **실무 사례** — steno STT 파이프라인. 워커 로그와 GPU Ray Serve 로그를 겹쳐 "200 송신 vs 미수신"을 대조해 리턴 경로 유실을 확정. 수정 후 idle 첫 잡이 attempt 1에서 바로 200이면 해결.
