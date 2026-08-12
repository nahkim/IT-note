---
type: 개념
domain: 보안
tags: [IT, 웹, 보안, 브라우저, 기초]
created: 2026-08-12
aliases: [CSRF, XSRF, 크로스 사이트 요청 위조, Cross-Site Request Forgery, SameSite]
---

# CSRF (Cross-Site Request Forgery, 크로스 사이트 요청 위조)

## 한 줄 정의
로그인된 사용자의 브라우저가 **쿠키를 자동으로 실어 보낸다는 성질**을 악용해, 공격자 사이트가 **사용자 이름으로 원치 않는 요청**을 보내게 만드는 공격.

## 자세히

### 원리 — 브라우저의 "친절함"이 취약점이 된다
브라우저는 `bank.com`으로 가는 요청이면 **어느 페이지에서 시작됐든** `bank.com` 쿠키를 자동으로 붙인다. 그래서:

```html
<!-- evil.com 에 심어둔 폼. 페이지 열자마자 자동 전송 -->
<form action="https://bank.com/transfer" method="POST">
  <input name="to" value="attacker"><input name="amount" value="1000000">
</form>
<script>document.forms[0].submit()</script>
```
사용자가 `bank.com`에 로그인된 상태로 `evil.com`을 열기만 하면 **송금이 실행**된다.

> 🔑 핵심 포인트: 공격자는 **응답을 읽지 못한다**([[동일 출처 정책]]이 막음). 하지만 **요청을 보내는 것 자체**는 막히지 않는다 → "쓰기(부작용)"만 노리는 공격.

### 막는 법
1. **`SameSite` 쿠키** — 오늘날의 1차 방어.
   - `Strict`: 외부 사이트에서 온 요청엔 쿠키를 아예 안 붙임(가장 안전, 외부 링크로 들어오면 로그아웃처럼 보임).
   - `Lax`: **최상위 GET 내비게이션**에만 붙임 → 외부 폼 POST·AJAX는 차단하면서 "링크 타고 들어와도 로그인 유지". 균형점.
   - `None`: 제한 없음 — 반드시 `Secure` 필요(크로스 사이트 임베드용).
   - **Chromium 계열은 SameSite 미지정 시 `Lax`로 취급**(Chrome 80, 2020년부터). ⚠️ Firefox·Safari는 이 기본값을 적용하지 않으므로 **서버에서 명시**해야 한다.
2. **CSRF 토큰(동기화 토큰)** — 서버가 세션마다 예측 불가능한 토큰을 발급, 폼·요청에 실어 검증. 공격자는 그 값을 알 수 없다. 프레임워크 기본 제공(Django·Spring Security·Rails).
3. **`Origin` / `Referer` 헤더 검증** — 요청이 어느 출처에서 왔는지 서버가 확인.
4. **재인증·2차 확인** — 송금·비밀번호 변경 등 위험 작업엔 비밀번호 재입력·MFA.
5. **안전한 메서드 규약** — GET은 절대 상태를 바꾸지 않게. (`GET /delete?id=1`은 그 자체로 CSRF 표적)

> ⚠️ **[[XSS]]가 있으면 CSRF 방어는 무의미하다.** 심어진 스크립트가 같은 출처에서 토큰을 읽어 정상 요청을 만들 수 있기 때문. 그래서 XSS를 먼저 막아야 한다.

### 3rd-party 쿠키 종말과의 관계
Safari(ITP)는 서드파티 쿠키를 기본 차단하고, Firefox는 Total Cookie Protection으로 사이트별 분리(파티셔닝)한다. 크로스 사이트 쿠키가 점점 안 붙는 방향으로 가면서 **고전적 CSRF 표면은 줄고 있지만**, SameSite 우회 기법(메서드 오버라이드, 같은 사이트 내 취약점 경유 등)이 있어 **토큰 방어는 여전히 유효**하다.

## 왜 중요한가
- "인증이 됐는데 왜 뚫리지?"의 대표 사례 — **인증(누구인가)** 은 통과했지만 **의도(진짜 원했는가)** 를 검증하지 않아서 생긴다.
- SameSite 기본값 변화 때문에 **OAuth 콜백·결제 리다이렉트·iframe 임베드가 갑자기 깨지는** 실무 이슈의 원인이기도 하다.

## 관련 개념
- [[XSS]] — 자주 혼동되지만 방향이 반대. XSS가 있으면 CSRF 방어가 무너짐
- [[동일 출처 정책]] — "요청은 가지만 응답은 못 읽는다"의 근거
- [[쿠키 세션 JWT]] — 쿠키 자동 전송이 원인, `SameSite`·`HttpOnly`·`Secure`가 대책
- [[CORS]] — 크로스 출처 "읽기"를 다루는 반대편 규칙
- [[인증과 인가]] · [[웹사이트 보안]] · [[OWASP Top 10]]

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — CSRF 원리(쿠키 자동 전송·응답은 못 읽음), SameSite `Strict`/`Lax`/`None`의 차이와 **Chromium 계열의 미지정 시 Lax 기본값(Chrome 80, 2020~)** 및 Firefox·Safari는 해당 기본값을 적용하지 않는다는 점, Safari ITP·Firefox Total Cookie Protection의 서드파티 쿠키 처리, CSRF 토큰·Origin 검증·재인증 방어와 "XSS가 있으면 CSRF 방어 무력화"를 OWASP·PortSwigger·MDN 등 복수 출처로 확인.
