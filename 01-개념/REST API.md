---
type: 개념
tags: [IT, 웹, API, 기초]
created: 2026-06-11
---

# REST API (RESTful API)

## 한 줄 정의
모든 것을 **자원(resource)**으로 보고, [[HTTP와 HTTPS|HTTP]] 메서드로 그 자원을 다루도록 설계한 웹 API 스타일.

## 자세히
- **REST = Representational State Transfer**. Roy Fielding이 2000년 박사 논문에서 제안한 **아키텍처 스타일**(엄밀한 표준·프로토콜이 아니다).
- 핵심 발상: 데이터를 **자원**으로 보고 **URI(주소)**로 식별한 뒤, **HTTP 메서드**로 행동을 표현한다.
  - 예: `GET /users/1`(1번 유저 조회), `POST /users`(유저 생성), `DELETE /users/1`(삭제).
- 대표 제약(6가지) 중 실무에서 가장 중요한 것들:
  - **무상태(Stateless)** — 서버가 세션을 기억하지 않는다. 모든 요청이 필요한 정보(인증 토큰 등)를 **스스로** 담아야 한다 → [[수평 확장]]에 유리.
  - **클라이언트-서버 분리**, **캐시 가능(Cacheable)**, **계층 구조(Layered)**, **균일 인터페이스(Uniform Interface)**.
- 응답 데이터 형식은 보통 **JSON**.
- 대안/이웃: GraphQL(필요한 필드만 요청), gRPC(고성능 내부 통신).

## 왜 중요한가
- 웹·모바일 백엔드 API의 사실상 표준 스타일. 주니어가 가장 많이 만들고 호출하게 되는 형태다.
- "무상태" 원칙 덕분에 서버를 여러 대로 늘리기 쉬워 [[로드 밸런서]]·[[수평 확장]]과 잘 맞는다.

## 관련 개념
- [[HTTP와 HTTPS]] — REST가 올라타는 메서드·상태 코드의 토대
- [[API 게이트웨이]] — 여러 REST 서비스의 공통 진입점
- [[쿠키 세션 JWT]] — 무상태 REST에서 인증을 싣는 방법(주로 JWT)
- [[FastAPI]] — REST API를 만드는 대표 파이썬 프레임워크

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — REST의 정의(Fielding 2000), 6가지 제약, 무상태·자원/URI·HTTP 메서드 매핑을 restfulapi.net·IBM·BrowserStack 등 복수 출처로 2회 확인.
