---
type: 개념
domain: 네트워크
tags: [IT, 네트워크, API, 백엔드, 마이크로서비스]
created: 2026-11-11
aliases: [gRPC, 지알피씨, Google RPC]
---

# gRPC

## 한 줄 정의
**원격 서버의 함수를 내 코드의 함수처럼 호출**하게 해주는 RPC 프레임워크. 전송은 **HTTP/2**, 메시지와 인터페이스 정의는 **Protocol Buffers(protobuf)** 로 한다. Google이 만들어 2015년에 오픈소스로 공개했고, 지금은 CNCF가 호스팅한다.

## 자세히

### RPC란?
- **RPC(Remote Procedure Call)**: 네트워크 너머에 있는 함수를 `user = client.GetUser(id)` 처럼 **로컬 함수처럼** 부르는 방식.
- [[REST API]]가 "**자원(URL)** + HTTP 메서드(GET/POST…)"로 생각한다면, RPC는 "**동작(함수 이름)**"으로 생각한다.
  - REST: `GET /users/42`
  - gRPC: `UserService.GetUser({ id: 42 })`

### 동작 흐름
1. **`.proto` 파일에 계약을 정의**: 서비스(함수 목록)와 메시지(요청·응답 구조)를 적는다.
   ```proto
   syntax = "proto3";

   service UserService {
     rpc GetUser (GetUserRequest) returns (User);
     rpc WatchUsers (WatchRequest) returns (stream User);  // 서버 스트리밍
   }

   message GetUserRequest { int64 id = 1; }
   message User {
     int64  id   = 1;   // 숫자 = 필드 번호(이름 대신 이 번호가 전송된다)
     string name = 2;
   }
   ```
2. **`protoc` 컴파일러로 코드를 생성**: 언어별(Go, Java, Python, TS…) **클라이언트 스텁(stub)** 과 **서버 인터페이스**가 자동으로 만들어진다.
3. 서버는 인터페이스를 구현하고, 클라이언트는 스텁의 메서드를 호출한다. 직렬화, 전송, 역직렬화는 프레임워크가 맡는다.

### 핵심 구성 요소
| 요소 | 역할 |
|---|---|
| **Protocol Buffers** | IDL(인터페이스 정의 언어) 겸 **바이너리 직렬화 포맷**. [[JSON과 직렬화\|JSON]]보다 작고 파싱이 빠르다. 필드 이름 대신 번호로 전송한다. |
| **HTTP/2** | 연결 하나에서 여러 요청을 동시에 처리(**멀티플렉싱**), 헤더 압축, 양방향 스트림을 제공한다. |
| **Stub / 코드 생성** | `.proto` 하나로 여러 언어의 클라이언트·서버 코드를 만든다. 언어가 달라도 **계약은 하나**로 유지된다. |
| **Deadline / 취소** | 호출마다 "언제까지 응답이 없으면 포기"를 지정하고, 이 값이 다음 서비스로 전파된다. |
| **Metadata** | HTTP 헤더에 해당하는 키-값(인증 토큰, 트레이스 ID 등). |
| **Status code** | `OK`, `NOT_FOUND`, `DEADLINE_EXCEEDED`, `UNAVAILABLE` 등 gRPC 고유의 상태 코드(HTTP 상태 코드와는 별개). |

### 4가지 통신 방식
| 방식 | 모양 | 예시 |
|---|---|---|
| **Unary** | 요청 1 → 응답 1 | 일반적인 API 호출 |
| **Server streaming** | 요청 1 → 응답 여러 개 | 실시간 시세나 로그 구독 |
| **Client streaming** | 요청 여러 개 → 응답 1 | 파일 조각 업로드, 센서 데이터 묶음 전송 |
| **Bidirectional streaming** | 양쪽이 자유롭게 여러 개 | 채팅, 실시간 협업 ([[WebSocket]]과 비슷한 용도) |

### 와이어 프로토콜: 실제로 오가는 것
gRPC는 새로운 전송 프로토콜이 아니라 **HTTP/2 위에 얹은 얇은 규칙**이다. 메서드 이름, 타임아웃, 상태 코드 같은 RPC 개념을 HTTP/2의 헤더·DATA 프레임·trailer에 대응시킨다. 호출 1번은 **HTTP/2 스트림 1개**가 된다.

**① 요청 헤더 (HEADERS 프레임)**
```
:method        POST                          ← 항상 POST
:scheme        https
:path          /user.v1.UserService/GetUser  ← /{패키지.서비스}/{메서드}
content-type   application/grpc+proto        ← application/grpc 로 시작해야 함
te             trailers                      ← trailer를 버리는 프록시를 걸러내기 위한 필수 헤더
grpc-timeout   1S                            ← 데드라인(정수 최대 8자리 + 단위 H/M/S/m/u/n)
grpc-encoding  gzip                          ← (선택) 메시지 압축 방식
authorization  Bearer ...                    ← 커스텀 Metadata도 일반 헤더로 전달
```
- `grpc-`로 시작하는 헤더 이름은 gRPC가 예약해 두었다.
- 바이너리 값을 담는 Metadata는 키 이름이 `-bin`으로 끝나고, 값은 **Base64로 인코딩**한다. HTTP/2 헤더에는 임의의 바이트를 넣을 수 없기 때문이다.

**② 메시지 본문 (DATA 프레임): Length-Prefixed Message**
```
┌──────────────┬──────────────────────┬─────────────────────────┐
│ Compressed   │ Message-Length       │ Message                 │
│ Flag (1byte) │ (4byte, big-endian)  │ (protobuf 바이너리)       │
│ 0=압축안함   │                      │                         │
│ 1=압축함     │                      │                         │
└──────────────┴──────────────────────┴─────────────────────────┘
```
- protobuf 메시지 하나마다 **5바이트 머리**(압축 여부 1바이트 + 길이 4바이트)를 붙인다. 이 덕분에 한 스트림에 메시지를 여러 개 이어 보낼 수 있고, 이것이 **스트리밍의 기반**이다.
- `grpc-encoding` 헤더가 없으면 Compressed Flag는 반드시 0이다. 압축은 메시지마다 따로 하며, 앞 메시지의 압축 상태를 이어 쓰지 않는다.

**③ 응답: 헤더 → 메시지들 → trailer**
```
HEADERS   :status 200, content-type application/grpc
DATA      [5바이트 머리][protobuf]   (스트리밍이면 여러 번)
HEADERS   grpc-status 0, grpc-message ...   ← trailer, END_STREAM
```
- **실제 성공·실패는 trailer의 `grpc-status`로 판단한다.** HTTP `:status`는 오류가 나도 보통 200이다. 그래서 HTTP 상태 코드만 보는 모니터링은 gRPC 오류를 놓친다.
- 상태를 응답 **맨 끝**(trailer)에 두는 이유: 스트리밍에서는 메시지를 다 보낸 뒤에야 성공인지 실패인지 정해지기 때문이다.
- **Trailers-Only**: 바로 실패하는 호출은 본문 없이 `:status` + `grpc-status` + `grpc-message`를 HEADERS 프레임 하나에 담아 끝낸다.
- 브라우저 `fetch`는 이 trailer를 읽을 수 없다. gRPC-Web은 그래서 상태를 본문 마지막에 특수 프레임으로 넣어 보내고, 이를 위해 프록시 변환이 필요하다.

### REST와 비교
| | [[REST API\|REST]] (JSON) | gRPC |
|---|---|---|
| 사고방식 | 자원(URL) 중심 | 함수(메서드) 중심 |
| 포맷 | 텍스트(JSON), 사람이 읽기 쉬움 | 바이너리(protobuf), 작고 빠름 |
| 계약 | 선택(OpenAPI 등) | **필수**(`.proto`) |
| 전송 | HTTP/1.1 또는 2 | HTTP/2 필수 |
| 스트리밍 | 제한적 | 4가지 방식 기본 지원 |
| 브라우저 | 바로 사용 가능 | **직접 호출 불가**(gRPC-Web + 프록시 필요) |
| 디버깅 | `curl`로 바로 확인 | 전용 도구 필요(grpcurl, Postman 등) |

### 한계와 주의점
- **브라우저에서 직접 쓸 수 없다**: 브라우저는 gRPC에 필요한 HTTP/2 저수준 제어(trailer 읽기 등)를 열어주지 않는다. 그래서 **gRPC-Web**과 Envoy 같은 변환 프록시를 둔다. gRPC-Web은 unary와 서버 스트리밍만 지원하고 클라이언트·양방향 스트리밍은 지원하지 않는다.
- **사람이 읽기 어렵다**: 바이너리라서 패킷을 그대로 보면 알아볼 수 없다. 로그와 디버깅 도구를 따로 갖춰야 한다.
- **스키마 변경 규칙**: **필드 번호는 재사용하거나 바꾸면 안 된다.** 필드를 지울 때는 `reserved`로 막아둔다. 이 규칙을 어기면 구버전 클라이언트가 데이터를 잘못 해석한다.
- **L7 로드밸런싱**: HTTP/2 연결 하나를 오래 유지하므로 L4 로드밸런서는 한 서버로만 요청을 몰아줄 수 있다. 요청 단위로 분산하는 L7 LB(Envoy 등)나 클라이언트 측 로드밸런싱이 필요하다.

## 왜 중요한가
- [[마이크로서비스]] 사이의 **내부 통신(east-west 트래픽)** 에서 사실상 표준으로 쓰인다. 호출 빈도가 높은 구간에서 속도와 페이로드 크기 이점이 크다.
- 여러 언어로 된 서비스가 섞여 있어도 **`.proto` 하나로 계약을 강제**하므로, 필드 이름 오타나 타입 불일치를 컴파일 시점에 잡을 수 있다.
- 흔한 구조: **외부(브라우저·앱)에는 REST/JSON, 내부 서비스 간에는 gRPC**, 그 사이를 [[API 게이트웨이]]가 변환한다.

## 관련 개념
- [[REST API]]: 가장 자주 비교되는 대안 (자원 중심, JSON)
- [[JSON과 직렬화]]: protobuf가 대체하는 텍스트 직렬화
- [[HTTP와 HTTPS]]: gRPC가 올라타는 HTTP/2
- [[WebSocket]]: 양방향 스트리밍이라는 용도가 겹친다
- [[마이크로서비스]]: gRPC를 가장 많이 쓰는 환경
- [[API 게이트웨이]]: REST↔gRPC 변환(트랜스코딩) 지점
- [[TCP-IP|TCP/IP]]: HTTP/2 아래의 전송 계층

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료**: HTTP/2와 Protocol Buffers 기반, 4가지 RPC 방식(unary, server, client, bidi streaming), 브라우저 직접 호출 불가 및 gRPC-Web과 프록시 필요, gRPC-Web은 클라이언트·양방향 스트리밍 미지원이라는 점을 grpc.io, IBM, Kreya, Cloudflare 블로그 등 여러 출처로 확인했다. (CNCF 성숙도 단계는 출처마다 달라서 적지 않았다.) 와이어 프로토콜 섹션(Length-Prefixed Message 5바이트 머리, `:path` 형식, `grpc-timeout` 단위, trailer의 `grpc-status`, Trailers-Only, `-bin` 헤더의 Base64 인코딩, `grpc-` 예약 접두사)은 grpc/grpc 저장소의 PROTOCOL-HTTP2.md 스펙과 IETF 초안(draft-kumar-rtgwg-grpc-protocol)으로 확인했다.
