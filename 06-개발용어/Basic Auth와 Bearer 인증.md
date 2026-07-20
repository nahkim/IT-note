---
type: 용어
tags: [IT, 개발용어, 웹, 보안, 인증]
created: 2026-07-16
aliases: [Basic Auth, Basic Authentication, 기본 인증, Bearer 인증, Bearer Authentication, Bearer Token, Authorization 헤더]
---

# Basic Auth와 Bearer 인증 (HTTP 인증 스킴)

**한 줄 뜻**: HTTP `Authorization` 헤더로 자격증명을 실어 보내는 **두 가지 대표 방식**. **Basic** = 아이디·비밀번호를 그대로 · **Bearer** = 발급받은 **토큰**을 제시.

**부연**:
- **Basic Auth** (RFC 7617) — `Authorization: Basic <base64(user:password)>`.
  - base64는 **암호화가 아니라 가역 인코딩** → 누구나 되돌려 읽음. **반드시 [[HTTP와 HTTPS|HTTPS]]** 위에서만.
  - 상태 없이 **매 요청마다** 아이디·비밀번호를 실어 보냄. 단순하지만 자격증명 노출·회수 어려움이 약점.
- **Bearer 인증** (RFC 6750, OAuth 2.0) — `Authorization: Bearer <token>`.
  - **"Bearer(소지자)"** = 이 토큰을 **가진 자면 누구나** 접근 가능(별도 키 증명 없음) → 토큰을 **저장·전송 시 반드시 보호**, 짧은 수명·회수 가능하게.
  - 토큰은 불투명(opaque) 문자열이거나 [[쿠키 세션 JWT|JWT]]. [[API 토큰]]·OAuth 액세스 토큰을 보낼 때 쓰는 표준 방식.
- **비교** — Basic은 *비밀번호 자체*를, Bearer는 *발급된 토큰*을 보낸다. 토큰은 권한을 좁히고([[API 토큰]]) 폐기·만료가 쉬워, 오늘날 API 인증은 대개 Bearer.

**관련**: [[API 토큰]] · [[HTTP 헤더]] · [[HTTP와 HTTPS]] · [[OAuth]] · [[인증과 인가]]

---
> ✅ 교차검증 — Basic(RFC 7617, base64 가역 인코딩·HTTPS 필수)과 Bearer(RFC 6750 OAuth 2.0, 소지자가 곧 접근권·토큰 보호 필수) 정의·차이를 MDN·RFC Editor·Swagger·Postman으로 확인.
