---
type: 개념
tags: [IT, 네트워크, 기초]
created: 2026-07-08
aliases: [TCP Keepalive, SO_KEEPALIVE, TCP 킵얼라이브, keepalive]
---

# TCP Keepalive

## 한 줄 정의
오래 idle한 TCP 연결에 커널이 주기적으로 작은 **probe 패킷**을 흘려보내는 기능. 원래는 "상대가 살았나" 확인용이지만, 실무에선 **NAT/방화벽이 조용한 연결을 잊어버리는 것을 막는** 용도로 더 자주 쓴다.

## 자세히
- `SO_KEEPALIVE` 소켓 옵션을 켜면, 연결이 일정 시간 idle일 때 커널이 probe를 보낸다. 상대가 ACK하면 살아있는 것, 몇 번 무응답이면 죽은 연결로 보고 끊는다.
- 동작을 정하는 커널 파라미터 3개 (리눅스 `net.ipv4.*`, **네트워크 네임스페이스별**이라 파드마다 따로 설정 가능):

| sysctl | 뜻 | 리눅스 기본값 |
|---|---|---|
| `tcp_keepalive_time` | idle 몇 초 후 **첫 probe** | **7200 (2시간)** |
| `tcp_keepalive_intvl` | probe 재전송 간격 | 75 |
| `tcp_keepalive_probes` | 몇 번 실패 시 죽음 판정 | 9 |

- ⚠️ **켜기만으론 부족**: `SO_KEEPALIVE`만 켜고 `tcp_keepalive_time`을 그대로 두면 첫 probe가 **2시간 뒤**에나 나간다. 몇 분짜리 문제엔 무의미 → **간격을 짧게(예 30초) 낮춰야** 효과가 있다.
- 애플리케이션 레벨에도 사촌이 있다: HTTP keep-alive(연결 재사용), WebSocket ping/pong, [[폴링]]. 계층마다 목적이 조금씩 다르다.

## 왜 중요한가 — NAT/방화벽 "연결 상태 만료"를 막는다
- NAT나 stateful 방화벽은 지나가는 연결을 **연결 추적 표(conntrack)**에 기억해둔다. 그래야 응답이 돌아올 때 원래 요청자에게 되돌려줄 수 있다.
- 이 표의 각 항목엔 **idle 타임아웃**이 있어, 일정 시간 패킷이 안 흐르면 **지워진다**(메모리 절약). 타임아웃은 장비마다 다르고, 특히 NAT 매핑은 수십 초~몇 분으로 짧을 수 있다.
- 지워진 뒤 그 연결의 패킷(예: 뒤늦은 응답)이 오면 → **"모르는 연결" → drop.**
- 그래서 **오래 걸리는 요청 + 그동안 침묵하는 연결**은 NAT/터널 너머에서 응답이 증발할 수 있다. TCP keepalive가 그 사이 probe를 흘려 **표를 계속 갱신** → 연결이 안 지워진다.
- 비슷한 목적의 사촌: **WireGuard `PersistentKeepalive`**(터널 UDP 매핑 유지). 단, 이건 **바깥 터널만** 지키지 그 안에 감싸인 TCP 연결은 못 지킨다 → 계층이 다르면 계층마다 keepalive가 따로 필요하다.

## 관련 개념
- [[TCP-IP]] — keepalive는 TCP의 기능(연결지향이라 상태가 있음)
- [[타임아웃]] — keepalive가 방어하는 대상(연결 idle 만료)
- [[재시도와 백오프]] — 연결이 끊긴 뒤의 상위 계층 대응
- [[리버스 프록시]] — nginx `proxy_socket_keepalive on`으로 upstream 연결에 적용
- [[긴 요청 응답 유실 (NAT 연결 만료)]] — 이 개념이 실제 문제가 된 실무 사례

## 내 생각 / 질문
-
