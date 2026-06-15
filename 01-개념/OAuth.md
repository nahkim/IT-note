---
type: 개념
tags: [IT, 보안, 웹, 기초]
created: 2026-06-11
aliases: [OAuth, OAuth2, OIDC, OpenID Connect]
---

# OAuth 2.0 (그리고 OpenID Connect)

## 한 줄 정의
비밀번호를 넘기지 않고도 **"내 데이터에 대한 접근 권한"을 제3자 앱에 위임**하게 해주는 인가(authorization) 표준.

## 자세히
- 예: 어떤 앱이 "구글로 로그인"을 제공할 때, 내 구글 비밀번호는 앱에 주지 않고 **구글이 발급한 토큰**으로 제한된 접근만 허용하는 것.
- 4가지 역할:
  - **Resource Owner** — 데이터의 주인(보통 사용자).
  - **Client** — 그 데이터에 접근하려는 앱.
  - **Authorization Server** — 사용자를 확인하고 **토큰을 발급**하는 서버(구글 등).
  - **Resource Server** — 실제 데이터를 가진 API 서버.
- 흐름의 결과로 **Access Token**(보통 짧은 수명)이 발급되고, 클라이언트는 이 토큰으로 자원에 접근한다. 토큰이 만료돼도 Refresh Token으로 재발급.
- **중요한 구분**:
  - **OAuth 2.0 = 인가(authorization)** 프레임워크. 그 자체로는 "이 사람이 누구인지(인증)"를 표준화해 알려주지 않는다.
  - **OpenID Connect(OIDC)** = OAuth 2.0 **위에 얹은 인증(authentication) 계층**. 사용자 신원 정보를 담은 **ID Token(JWT)**을 추가로 발급한다.
  - 즉 "로그인(너 누구야)"까지 필요하면 OIDC, "데이터 접근 권한만" 필요하면 OAuth 2.0.

## 왜 중요한가
- "소셜 로그인", 외부 API 연동(캘린더·드라이브 등) 모든 곳에 쓰이는 산업 표준.
- OAuth(인가)와 OIDC(인증)를 섞어 이해하면 로그인 설계가 어긋난다 → [[인증과 인가]] 구분이 전제.

## 관련 개념
- [[인증과 인가]] — OAuth=인가, OIDC=인증이라는 핵심 구분
- [[쿠키 세션 JWT]] — access/ID 토큰이 흔히 JWT
- [[API 게이트웨이]] — 토큰 검증을 공통 관문에서 처리하기도

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — OAuth 4역할(owner·client·auth server·resource server)·access token·"OAuth는 인가, OIDC는 그 위 인증 계층(ID Token)"을 Okta·Microsoft Learn·Kong 등 복수 출처로 2회 확인.
