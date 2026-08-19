---
type: 개념
domain: 보안
tags: [IT, 보안, 인증, 웹, OAuth]
created: 2026-08-18
aliases: [PKCE, 픽시, Proof Key for Code Exchange, RFC 7636, code_verifier, code_challenge, S256, 인가 코드 가로채기]
---

# PKCE (Proof Key for Code Exchange)

## 한 줄 정의
[[OAuth]] **인가 코드(Authorization Code) 흐름에서, 코드를 중간에 탈취당해도 토큰으로 바꾸지 못하게** 막는 확장. 요청마다 **일회용 비밀(code_verifier)** 을 만들어 "코드를 요청한 그 클라이언트"만 교환할 수 있게 한다. **RFC 7636**(2015), 보통 "**픽시**"라고 읽는다.

## 자세히

### 무엇을 막으려고 만들어졌나 — 인가 코드 가로채기
인가 코드 흐름의 마지막은 **코드 → 토큰 교환**이다. 원래 이 교환을 지키는 건 `client_secret`인데, 문제는 시크릿을 숨길 수 없는 클라이언트가 있다는 것.

- **퍼블릭 클라이언트(public client)** — 모바일 앱·SPA·CLI·데스크톱 앱. 바이너리를 뜯거나 JS 번들을 열면 시크릿이 그대로 나온다. 그래서 **애초에 시크릿을 안 준다.**
- 여기에 **커스텀 스킴 리다이렉트**(`myapp://callback`)의 구멍이 겹친다. OS는 같은 스킴을 등록한 앱이 여럿이면 어느 쪽이 받을지 보장하지 않는다 → **악성 앱이 리다이렉트를 가로채 코드를 주워간다.**
- 시크릿이 없거나 이미 알려져 있으니, 코드만 있으면 **공격자가 그대로 토큰 교환에 성공**한다. 이것이 **authorization code interception attack**.

### 동작 — 해시만 흘려보내고 원본은 손에 쥔다
```
1. 클라이언트: code_verifier 생성
      랜덤 문자열, [A-Z] [a-z] [0-9] - . _ ~ 로 43~128자, 요청마다 새로

2.            code_challenge = BASE64URL( SHA256(code_verifier) )

3. GET /authorize?response_type=code&client_id=…
                 &code_challenge=<challenge>&code_challenge_method=S256
      → 인가 서버가 발급할 코드에 challenge를 묶어 저장

4. ← 리다이렉트로 인가 코드 수신          ※ 여기서 탈취당했다고 가정

5. POST /token   code=<코드>&code_verifier=<원본 verifier>
      → 서버가 verifier를 SHA256 해서 저장해둔 challenge와 비교
      → 불일치 / 누락이면 거부
```

**핵심은 비대칭이다.** 네트워크·리다이렉트·브라우저 히스토리에 흘러다니는 건 **해시(challenge)** 뿐이고, **원본(verifier)** 은 클라이언트 메모리에만 있다. 코드를 훔친 쪽은 5번에서 원본을 못 대므로 막힌다.

> 즉 PKCE는 **미리 심어두는 정적 시크릿(`client_secret`) 대신, 요청마다 즉석에서 만드는 동적 시크릿**이다. 유출돼도 그 한 번의 흐름에서만 의미가 있다.

### `S256` vs `plain`
| method | code_challenge | 평가 |
|---|---|---|
| **`S256`** | `BASE64URL(SHA256(verifier))` | **사실상 필수.** 흘러다니는 값에서 원본을 되돌릴 수 없다 |
| `plain` | `verifier` 그대로 | SHA-256을 못 쓰는 환경용 fallback. 인가 요청과 토큰 요청이 **같은 값**을 실어 나르므로 가로채면 무력화 |

- ⚠️ **다운그레이드 공격 주의** — 공격자가 요청에서 `code_challenge`를 떼어내거나 method를 `plain`으로 낮추려 시도할 수 있다. 그래서 방어의 책임은 **인가 서버**에 있다: PKCE를 요구하는데 `code_challenge`가 없으면 인가 단계에서 `invalid_request`로 거부하고, **challenge와 함께 발급한 코드는 verifier 없는 토큰 요청을 반드시 거부**해야 한다. 클라이언트만 잘 짜서는 안 된다.

### 지금(2026) 기준 위상 — 옵션이 아니라 기본값
- **RFC 9700** — *Best Current Practice for OAuth 2.0 Security* (2025년 1월, **BCP 240**). 퍼블릭 클라이언트는 PKCE **필수**, confidential 클라이언트에도 권장, **인가 서버는 PKCE를 지원해야 한다(MUST)**.
- **OAuth 2.1 초안** — 인가 코드 흐름 **전반**에 PKCE 요구(OIDC `nonce`로 보호되는 일부 confidential 케이스만 좁게 예외). 같은 맥락에서 **implicit grant는 폐기**됐다.
- 정리하면, **"시크릿 못 숨기는 앱용 보조 장치"에서 → 인가 코드 흐름의 표준 구성요소**로 위상이 바뀌었다. 새로 만든다면 confidential 클라이언트라도 그냥 켜는 게 맞다.

### 헷갈리는 것들
- **PKCE ≠ `state`** — 목적이 다르다.
  - `state`: **[[CSRF]] 방어** — "지금 돌아온 이 응답이 *내가 시작한* 흐름의 것인가"
  - PKCE: **코드 탈취 방어** — "이 코드를 교환하려는 게 *코드를 요청한 그 클라이언트*인가"
  - RFC 9700은 CSRF 방어를 **PKCE·`nonce`·`state` 중 하나**로 하라고 정리하지만, 둘은 서로를 대체하는 관계가 아니라 **겹치는 부분이 있을 뿐**이다.
- **PKCE ≠ 리다이렉트 URI 검증 면제** — 정확한(exact match) 리다이렉트 URI 등록·검증은 그대로 필요하다.
- **PKCE ≠ 클라이언트 인증** — verifier는 "이 흐름의 연속성"을 증명할 뿐 **클라이언트가 누구인지**를 증명하지 않는다. 그래서 confidential 클라이언트는 여전히 시크릿(또는 mTLS·private_key_jwt)을 함께 쓴다.
- **code_verifier는 저장하지 말 것** — 흐름이 끝나면 버리는 값이다. localStorage 등에 남기면 만들어둔 이점이 사라진다 → [[브라우저 저장소]].

## 왜 중요한가
- **모바일 앱·SPA에서 로그인을 붙이는 순간 만나는 기본기.** 소셜 로그인, 외부 API 연동, CLI 로그인(브라우저 띄우는 방식)까지 전부 이 흐름을 탄다.
- 과거 퍼블릭 클라이언트의 대안이던 **implicit grant**(토큰을 URL 프래그먼트로 바로 던지기)는 토큰 노출 위험 때문에 폐기됐고, **그 자리를 "인가 코드 + PKCE"가 대체**했다. 옛 자료를 보고 implicit로 구현하면 지금 기준으로는 틀린 설계다.
- 서버(인가 서버) 쪽 구현·검토를 한다면, **거부 조건을 제대로 구현했는지**가 곧 보안 수준이다(다운그레이드 차단).

## 관련 개념
- [[OAuth]] — PKCE가 붙는 인가 코드 흐름의 본체
- [[OIDC]] — 로그인까지 필요할 때. `nonce`와 역할이 겹치는 지점이 있다
- [[인증과 인가]] — PKCE는 인증이 아니라 **흐름의 무결성**을 지키는 장치
- [[CSRF]] — `state`가 막는 것과의 차이
- [[쿠키 세션 JWT]] — 교환해서 받은 토큰을 어디에 어떻게 둘 것인가
- [[암호화와 해싱]] — SHA-256 단방향 해시가 PKCE의 전제
- [[클라이언트 앱]] · [[브라우저 저장소]] — 퍼블릭 클라이언트가 시크릿을 못 숨기는 이유
- [[OWASP Top 10]] — 인증·인가 실패(A01/A07) 맥락

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — PKCE가 **RFC 7636**(인가 코드 가로채기 공격 대응)이라는 정의와 **code_verifier: `[A-Z]/[a-z]/[0-9]/-._~`, 최소 43자·최대 128자**, **`S256` = BASE64URL(SHA256(verifier))**, `plain`은 fallback이라는 점, **인가 서버가 PKCE를 요구하는데 `code_challenge`가 없으면 `invalid_request`로 거부해야 하고 verifier 없는 토큰 요청을 거부함으로써 다운그레이드를 막는다**는 서버 측 책임, 그리고 **RFC 9700**(*Best Current Practice for OAuth 2.0 Security*, **2025년 1월 · BCP 240**)이 퍼블릭 클라이언트에 PKCE를 요구하고 인가 서버의 PKCE 지원을 MUST로 두었다는 점, **OAuth 2.1 초안이 인가 코드 흐름 전반에 PKCE를 요구하고 implicit grant를 폐기**했다는 점을 RFC Editor·IETF datatracker(RFC 7636 / RFC 9700)·Authlete 문서·WorkOS·Scalekit 해설 등 복수 출처로 확인.
