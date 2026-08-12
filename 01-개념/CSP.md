---
type: 개념
domain: 보안
tags: [IT, 웹, 보안, 브라우저, HTTP]
created: 2026-08-12
aliases: [CSP, 콘텐츠 보안 정책, Content Security Policy, strict-dynamic, nonce]
---

# CSP (Content Security Policy, 콘텐츠 보안 정책)

## 한 줄 정의
"이 페이지에서 **어떤 출처의 스크립트·이미지·스타일만 실행/로드해도 되는지**"를 서버가 HTTP 헤더로 선언하고, **브라우저가 강제**하는 보안 정책. [[XSS]] 피해를 줄이는 2차 방어선.

## 자세히

### 어떻게 동작하나
서버가 응답에 헤더를 붙인다:
```
Content-Security-Policy: script-src 'nonce-{매요청_랜덤값}' 'strict-dynamic'; object-src 'none'; base-uri 'none';
```
브라우저는 이 목록에 없는 스크립트를 **실행 자체를 거부**한다. 공격자가 [[XSS]]로 `<script>`를 심는 데 성공해도, **정책에 없으면 안 돌아간다** → "취약점은 있었지만 피해는 없었다"를 만드는 장치.

### 주요 지시자(directive)
- `default-src` — 명시 안 된 리소스 종류의 기본값.
- `script-src` / `style-src` / `img-src` / `connect-src` / `font-src` — 종류별 허용 출처.
- `frame-ancestors` — 나를 iframe으로 감쌀 수 있는 사이트(= 클릭재킹 방지, `X-Frame-Options`의 후계).
- `object-src 'none'` · `base-uri 'none'` — 플러그인·`<base>` 태그 악용 차단. 거의 항상 넣는다.
- `report-to` / `report-uri` — 위반 리포트 수집 엔드포인트.

### 도메인 허용목록은 사실상 실패한 접근
`script-src https://cdn.example.com` 식으로 **도메인을 나열**하는 방식은 실무에서 잘 깨진다: CDN에 JSONP 엔드포인트나 취약한 라이브러리가 하나만 있어도 우회되고, 서드파티가 늘수록 목록이 무의미해진다. 그래서 현재 권장은 **strict CSP**:

- **nonce 방식** — 요청마다 **암호학적으로 안전한 난수**를 생성해 헤더와 `<script nonce="…">`에 동시에 넣는다. 공격자는 그 값을 미리 알 수 없다.
  - ⚠️ 모든 `<script>`에 자동으로 nonce를 박아주는 미들웨어를 만들면 **공격자가 주입한 스크립트에도 nonce가 붙어** 정책이 무력화된다.
  - nonce는 **매 응답마다 달라야** 하므로, 정적 HTML 캐싱과 궁합이 나쁘다(템플릿 엔진 필요).
- **hash 방식** — 인라인 스크립트의 해시를 등록. 정적 사이트에 적합.
- **`'strict-dynamic'`** — nonce로 신뢰된 스크립트가 **동적으로 추가한 스크립트도 신뢰**. 런타임에 스크립트를 주입하는 현대 프레임워크·태그 매니저와 호환되게 해준다.
- **`'unsafe-inline'`·`'unsafe-eval'`은 넣는 순간 CSP의 의미가 대부분 사라진다.**

### 도입 절차 (현실적인 순서)
1. **`Content-Security-Policy-Report-Only`** 로 먼저 배포 → 아무것도 차단하지 않고 위반만 리포트로 수집.
2. 리포트 보며 인라인 스크립트·외부 리소스 정리.
3. 위반이 잦아들면 **강제 모드**로 전환.

> CSP는 **입력 검증·출력 인코딩을 대체하지 않는다.** 방어의 마지막 겹일 뿐이다.

## 왜 중요한가
- XSS는 완전히 없애기 어렵다 → **"한 번은 뚫린다"를 전제로 피해를 봉쇄**하는 장치.
- `frame-ancestors`·`upgrade-insecure-requests` 등으로 클릭재킹·혼합 콘텐츠까지 한 헤더에서 다룬다.
- 보안 헤더 중 **설정 난이도가 가장 높고 효과도 가장 큰** 항목. Report-Only 단계를 건너뛰면 서비스가 깨진다.

## 관련 개념
- [[XSS]] — CSP가 완화하려는 바로 그 공격
- [[HTTP 헤더]] — CSP는 응답 헤더로 전달
- [[동일 출처 정책]] · [[CORS]] — 브라우저가 강제하는 다른 축의 규칙
- [[웹사이트 보안]] — HSTS·nosniff 등 다른 보안 헤더와 함께
- [[서비스 워커]] — 스크립트 로딩 경로가 겹쳐 CSP 설정에 걸리기 쉬움

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — nonce/hash 기반 strict CSP 권장(도메인 허용목록의 한계), `'strict-dynamic'`이 신뢰된 스크립트가 동적 삽입한 스크립트로 신뢰를 전파한다는 점, nonce는 요청마다 암호학적으로 강한 값이어야 하고 모든 script 태그에 일괄 주입하면 무력화된다는 주의, `object-src 'none'; base-uri 'none'` 권장 조합, Report-Only 선배포 후 강제 전환 절차를 MDN·OWASP CSP Cheat Sheet·web.dev(strict-csp) 등 복수 출처로 확인.
