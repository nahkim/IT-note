---
type: 개념
domain: 네트워크
tags: [IT, 네트워크, 웹]
created: 2026-08-03
aliases: [URL 구조, URL, URI, URN, 유알엘, uniform resource locator]
---

# URL 구조 (Uniform Resource Locator)

## 한 줄 정의
웹 자원의 **주소**. `scheme://host:port/path?query#fragment` 구조로 **"무슨 프로토콜로 · 어느 서버의 · 어떤 자원을 · 어떤 조건으로"** 가리키는지를 담는다. (스킴·host만 필수, 나머지는 선택)

## 자세히

### 전체 구조 (한눈에)
```
 https://user:pass@www.example.com:443/blog/post?id=42&sort=new#comments
 └─┬─┘   └───┬───┘ └──────┬───────┘ └┬┘└───┬────┘└──────┬──────┘ └──┬───┘
 scheme   userinfo       host       port  path         query      fragment
 └──────────── authority ───────────────┘
```

### 각 부분
- **scheme(스킴/프로토콜)** — `https`·`http`·`ws/wss`·`ftp`·`mailto`·`tel`·`file`·`data`… 어떤 방식으로 접근할지. **기본 포트를 결정**(http→80, https→443).
- **authority**
  - **userinfo**(`user:pass@`) — 인증 정보. 요즘 거의 안 쓰고 보안상 지양.
  - **host** — 도메인(`www.example.com`) 또는 IP. **[[DNS]]로 IP로 변환**되어 접속.
  - **port** — 없으면 스킴의 **기본 포트**로 자동(→ [[Docker nginx 포트 없이 접속]]). 브라우저가 접속 전에 알아서 채움(리다이렉트 아님).
- **path(경로)** — 서버 내 자원 위치(`/blog/post`). 보통 **대소문자 구분**.
- **query(쿼리 스트링)** — `?`로 시작, `key=value`를 `&`로 나열. 필터·검색·파라미터. (예: [[S3 Presigned URL]]의 서명도 쿼리에 실림)
- **fragment(프래그먼트)** — `#` 뒤. 페이지 내 앵커·SPA 라우팅에 쓰인다.

### 꼭 알아둘 3가지 뉘앙스
1. **프래그먼트(`#…`)는 서버로 안 보내진다.** 브라우저만 처리(서버 로그·요청에 안 남음). → SPA `#/route`, `#section` 이동, 그리고 **OAuth 토큰을 프래그먼트로 받으면 서버에 안 남는** 이유.
2. **origin(출처) = scheme + host + port.** 셋이 **전부 같아야** same-origin. path·query·fragment는 origin에 **포함 안 됨**. → [[CORS]]·웹 보안의 근본 경계([[웹사이트 보안]]).
3. **퍼센트 인코딩(URL 인코딩)** — 특수·예약 문자를 `%XX`(바이트의 16진수)로. 공백→`%20`, 한글→UTF-8 바이트로. 쿼리 값에 `&`·공백·`=`이 있으면 **인코딩 필수**. (안전 문자: `A-Z a-z 0-9 - . _ ~`)

### URL vs URI vs URN
- **URI** = 자원을 식별하는 **상위 개념**(문자열 식별자).
- **URL** = 자원의 **위치까지** 알려주는 URI(우리가 쓰는 주소). **URN** = **이름으로만** 식별(예: `urn:isbn:0451450523`).
- 즉 **URL·URN ⊂ URI**.

## 왜 중요한가
- URL을 정확히 읽으면 **어디로·무엇을·어떤 조건으로** 요청하는지 즉시 파악 — 디버깅·API 설계·보안(피싱 host 확인)의 기본기.
- **origin·포트·프래그먼트·인코딩** 같은 뉘앙스가 [[CORS]] 오류, SPA 라우팅, [[curl]] 디버깅, 토큰 전달에서 실제로 걸린다.

## 관련 개념
- [[HTTP와 HTTPS]] · [[DNS]] — 스킴·host 해석
- [[Docker nginx 포트 없이 접속]] — 포트 생략과 기본 포트(80/443)
- [[CORS]] · [[웹사이트 보안]] — origin(scheme+host+port) 기준의 보안
- [[curl]] · [[S3 Presigned URL]] — URL로 요청·쿼리 파라미터 서명
- [[REST API]] — path·query로 자원·조건을 표현

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — URL 6부분(scheme·userinfo·host·port·path·query·fragment, 스킴+host만 필수), 프래그먼트는 서버 미전송(클라이언트 처리), origin=scheme+host+port(같아야 same-origin, path/query/fragment 제외), URI⊃URL/URN(URL=위치·URN=이름, `urn:isbn:`), 퍼센트 인코딩(`%XX`·안전문자 A-Za-z0-9-._~)을 MDN·Wikipedia(Same-origin·Percent-encoding)·ByteByteGo 등으로 확인.
