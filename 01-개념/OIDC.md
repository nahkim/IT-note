---
type: 개념
tags: [IT, 보안, 웹, 기초]
created: 2026-06-17
aliases: [OIDC, OpenID Connect, ID 토큰, ID Token]
---

# OIDC (OpenID Connect)

## 한 줄 정의
[[OAuth|OAuth 2.0]] **위에 얹은 인증(authentication) 표준 계층**. "이 사람이 누구인지"를 **ID 토큰(JWT)**으로 알려준다.

## 자세히
- **배경 — 왜 OIDC가 생겼나**: [[OAuth|OAuth 2.0]](RFC 6749, 2012)는 **인가(권한 위임)용으로만** 설계됐는데, 사람들이 이를 "구글로 로그인" 같은 **인증에 갖다 쓰기 시작**했다. 문제는 ① 제공자마다 "사용자 정보" 응답 형식이 제각각이고 ② **그게 진짜인지 검증할 표준이 없었으며** ③ access token을 인증에 쓰는 건 보안상 위험했다. 그래서 **2014년 OpenID 재단**이 **OIDC**를 OAuth 2.0 위에 얹는 **얇은 인증 표준 계층**으로 만들었다 — 통일된 ID 토큰·클레임·검증 규칙을 정해 **어느 앱·어느 제공자든 같은 방식으로 로그인**이 호환되게 한 것. (즉 OIDC는 "JWT payload" 자체가 아니라, *그 payload에 무엇을 담고 어떻게 믿을지 정한 표준*의 이름)
- **OAuth는 인가(authorization)만** 다룬다(데이터 접근 권한 위임). 그 자체로는 "로그인한 사용자가 누구인지"를 표준화해 알려주지 않는다. **OIDC가 그 위에 인증(신원 확인)을 얹는다.** → [[인증과 인가]]
- 핵심 추가물 = **ID 토큰(ID Token)**: 사용자 인증 사실과 신원 정보를 담은 **JWT**. ([[쿠키 세션 JWT|JWT]])
  - 주요 클레임: **`iss`**(발급자) · **`sub`**(사용자 고유 ID) · **`aud`**(대상 클라이언트) · `exp`(만료) · `iat`(발급시각) · `nonce`(재생 공격 방지).
  - **신원 정보는 모두 JWT의 `payload`에** 담긴다(아래). 단 payload는 암호화가 아니라 **Base64url 인코딩**이라 누구나 읽고 위조 가능 → **검증 순서를 지켜야** 신뢰할 수 있다.

```jsonc
// ID 토큰 = 헤더.페이로드.서명  (점으로 구분, 각 조각은 Base64url)
// ↓ 가운데 payload를 디코드하면 ── "누구인지"가 여기 ──
{
  "iss": "https://accounts.google.com",  // 발급자(IdP)
  "sub": "110169482...",                 // 사용자 고유 ID ← 신원의 핵심
  "aud": "my-app-client-id",             // 이 토큰을 받을 앱
  "email": "user@example.com",           // openid + email 스코프일 때 포함
  "exp": 1781000000, "iat": 1780996400, "nonce": "a1b2c3"
}
```

**검증 순서 (payload를 믿기 전에):** ① **서명 검증** — 발급자(IdP) 공개키(JWKS, `/.well-known/openid-configuration`로 위치 발견)로 위변조·발급자 확인 → ② `iss`·`aud`·`exp`·`nonce` 일치 확인 → ③ 통과한 뒤에야 `sub`·`email` 등 payload를 신뢰. (이 순서를 건너뛰면 `sub`를 남의 ID로 바꾼 가짜 토큰에 속는다.)
- **두 토큰의 역할 구분** (자주 헷갈림):
  - **ID 토큰** = "누구인가" → **클라이언트(앱)**가 읽음 (OIDC, 인증).
  - **액세스 토큰** = "무엇을 할 수 있나" → **리소스 서버(API)**가 읽음 (OAuth, 인가).
- **스코프**: `openid` 스코프가 **반드시** 포함돼야 OIDC로 동작(+ `profile`·`email` 등으로 추가 정보 요청).
- **표준 흐름**: 보통 **Authorization Code Flow** — `/authorize`로 로그인·동의 → 인가 코드 → `/token`에서 **ID 토큰 + 액세스 토큰(+리프레시 토큰)** 교환 → 필요 시 **UserInfo** 엔드포인트로 프로필 보강.
- **디스커버리**: `/.well-known/openid-configuration` 한 번 호출로 엔드포인트·지원 스코프·서명 공개키(JWKS) 위치를 자동 발견 → 서명 검증에 사용.

## 왜 중요한가
- **"구글/애플로 로그인" 같은 소셜 로그인과 SSO의 사실상 표준.** 직접 비밀번호를 다루지 않고 신원을 위임받는다.
- "OAuth만 쓰면 인증이 되는 줄" 오해하면 보안 구멍이 생긴다 — **접근 권한(OAuth) vs 신원 확인(OIDC)**을 분리해 이해해야 한다.

## 관련 개념
- [[OAuth]] — OIDC가 올라타는 인가 프레임워크(OIDC = OAuth + 인증 계층)
- [[인증과 인가]] — OIDC=인증, OAuth=인가라는 핵심 구분
- [[쿠키 세션 JWT]] — ID 토큰이 곧 JWT(서명·검증 원리 동일)
- [[HTTP와 HTTPS]] — authorize/token/UserInfo 엔드포인트가 HTTP(S)로 동작

## 내 생각 / 질문
-

---
> ✅ **웹 2회 교차검증** — OIDC=OAuth 2.0 위 인증 계층, ID 토큰(JWT)·클레임(iss/sub/aud), ID토큰(인증/클라이언트) vs 액세스토큰(인가/API), `openid` 스코프, Authorization Code Flow, `/.well-known/openid-configuration` 디스커버리를 OpenID 스펙·Auth0·Okta·Microsoft·oauth.net로 확인. 배경(OAuth 2.0 = RFC 6749·2012, 인가 전용 / OIDC = 2014.2 OpenID 재단, OAuth 인증 오용 보완)도 openid.net·Okta·facilelogin로 확인.
