---
type: 개념
domain: 보안
tags: [IT, 보안, 암호학, 인증, 웹훅, API]
created: 2026-10-29
aliases: [HMAC, HMAC 서명, Hash-based Message Authentication Code, 메시지 인증 코드, MAC, HMAC-SHA256, RFC 2104, 웹훅 서명]
---

# HMAC (Hash-based Message Authentication Code)

## 한 줄 정의
**공유 비밀키 + 해시 함수**로 메시지의 "지문"을 만들어, 받는 쪽이 **"이 메시지가 키를 가진 상대가 보낸 것이고, 중간에 한 바이트도 바뀌지 않았다"** 를 확인하게 하는 방식. **RFC 2104**(1997). 실무에서는 흔히 "**HMAC 서명**"이라고 부르지만, 엄밀히는 서명이 아니라 **MAC(메시지 인증 코드)** 이다.

## 자세히

### 왜 그냥 해시로는 안 되나
- `SHA256(메시지)` — 누구나 계산할 수 있다. 공격자가 메시지를 바꾸고 해시도 새로 계산해 붙이면 끝. **무결성은 보장해도 "누가 보냈는지"는 보장 못 한다.**
- `SHA256(키 ‖ 메시지)` — 키가 들어갔으니 될 것 같지만, SHA-256·SHA-1·MD5 같은 Merkle–Damgård 계열은 **길이 확장 공격(length extension attack)** 에 뚫린다. 키를 몰라도 `H(키 ‖ 메시지)`만 보면 `H(키 ‖ 메시지 ‖ 패딩 ‖ 공격자_데이터)`를 계산할 수 있다.
- HMAC은 이 문제를 **해시를 두 번, 키를 두 번 섞는 구조**로 막는다.

### 계산 방식
```
HMAC(K, m) = H( (K' ⊕ opad) ‖ H( (K' ⊕ ipad) ‖ m ) )

K'   = 키를 해시 블록 크기(SHA-256은 64바이트)에 맞춘 값
       - 블록보다 길면 먼저 H(K)로 줄이고, 짧으면 0으로 채움
ipad = 0x36 을 블록 크기만큼 반복   (inner padding)
opad = 0x5c 을 블록 크기만큼 반복   (outer padding)
```
- **안쪽 해시**: 키와 메시지를 섞는다.
- **바깥쪽 해시**: 그 결과를 다시 키로 감싼다 → 안쪽 결과를 늘려 붙여도 바깥 해시가 달라지므로 **길이 확장 공격이 통하지 않는다.**
- 이름은 쓰는 해시를 붙여 부른다: `HMAC-SHA256`, `HMAC-SHA512`, `HMAC-SHA1`(레거시) …
- 직접 구현하지 말고 언어 표준 라이브러리를 쓴다.

```python
import hmac, hashlib

sig = hmac.new(secret, raw_body, hashlib.sha256).hexdigest()
ok = hmac.compare_digest(sig, received_sig)   # ← == 비교 금지
```
```js
const sig = crypto.createHmac('sha256', secret).update(rawBody).digest('hex');
const ok = crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(receivedSig)); // 길이 다르면 throw → 먼저 길이 확인
```

### 보내는 쪽 / 받는 쪽 흐름
```
[보내는 쪽]                                   [받는 쪽]
 body + (timestamp)                            같은 body + timestamp로
 → HMAC(secret, …) 계산                        → HMAC(secret, …) 직접 다시 계산
 → 헤더에 서명 실어 전송  ───────────────▶     → 헤더의 서명과 상수 시간 비교
                                               → 시간 차이가 허용 범위 안인지 확인
```
**핵심은 "받는 쪽이 직접 다시 계산해서 맞춰본다"** 는 것. 서명을 복호화하는 게 아니다(HMAC은 [[암호화와 해싱|해시]] 계열이라 되돌릴 수 없다).

### 실제로 어디서 쓰이나
| 쓰임 | 형태 |
|---|---|
| **웹훅 검증** — Stripe | `Stripe-Signature: t=<timestamp>,v1=<hex>` — `"{t}.{raw_body}"`를 HMAC-SHA256. SDK 기본 허용 오차 **300초** |
| **웹훅 검증** — GitHub | `X-Hub-Signature-256: sha256=<hex>` — raw body만 서명(타임스탬프 없음 → `X-GitHub-Delivery` ID로 중복 제거) |
| **웹훅 검증** — Slack | `X-Slack-Signature: v0=<hex>` — `"v0:{timestamp}:{body}"`를 서명 |
| **AWS SigV4** | 요청 정규화 문자열을 `AWS4-HMAC-SHA256`으로 서명 → [[S3 Presigned URL]] |
| **JWT `HS256`** | 헤더.페이로드를 HMAC-SHA256 → [[쿠키 세션 JWT]] |
| **API 요청 서명** | 거래소·결제 API 등: `access_key` + `HMAC(secret_key, 요청)` → [[API 토큰]] |
| **쿠키·세션 무결성** | 서버가 쿠키 값에 HMAC을 붙여 변조 감지(Express `cookie-signature`, Rails 서명 쿠키 등) |
| **기타 프로토콜 내부** | TLS 1.3 키 유도(HKDF), TOTP/HOTP(OTP 앱의 6자리 코드) |

### 구현할 때 실수하는 지점
- ⚠️ **`==`로 비교하지 말 것** — 일반 문자열 비교는 첫 불일치 바이트에서 바로 끝난다. 응답 시간 차이로 서명을 한 바이트씩 맞혀가는 **타이밍 공격**이 가능. `hmac.compare_digest` / `crypto.timingSafeEqual` / `MessageDigest.isEqual` 같은 **상수 시간 비교**를 쓴다.
- ⚠️ **raw body로 검증할 것** — 프레임워크가 JSON을 파싱했다가 다시 직렬화하면 공백·키 순서·유니코드 이스케이프가 달라져 바이트가 바뀐다 → 정상 요청도 검증 실패. 파싱 **전** 원본 바이트를 잡아둬야 한다(→ [[JSON과 직렬화]]). Express라면 `express.raw()`.
- ⚠️ **재전송(replay) 방어는 HMAC이 해주지 않는다** — 정상 요청을 통째로 녹화해 다시 보내면 서명도 그대로 유효하다. 그래서 **타임스탬프를 서명 대상에 넣고 허용 시간(보통 5분)을 넘으면 거부**하거나, nonce/이벤트 ID로 중복을 거른다.
- ⚠️ **무엇을 서명했는지가 곧 보호 범위** — body만 서명하면 URL·쿼리·헤더는 바꿔치기 가능. AWS SigV4가 메서드·경로·쿼리·헤더를 모두 정규화해 서명하는 이유.
- **키 관리** — 키는 해시 출력 길이 이상(HMAC-SHA256이면 32바이트 이상)의 랜덤 값. 코드·저장소에 하드코딩 금지, 비밀 저장소에 두고 교체(rotation) 시 구·신 키를 잠시 둘 다 허용한다.

### 헷갈리는 것들
- **HMAC ≠ 디지털 서명** — 
  | | HMAC | 디지털 서명(RSA·ECDSA·Ed25519) |
  |---|---|---|
  | 키 | **대칭** — 같은 비밀키를 양쪽이 공유 | **비대칭** — 개인키로 서명, 공개키로 검증 |
  | 검증할 수 있는 사람 | 키를 가진 쪽만 | 공개키만 있으면 누구나 |
  | 부인 방지 | ❌ 양쪽 다 서명을 만들 수 있으니 "누가" 만들었는지 제3자에게 증명 불가 | ✅ 개인키 소유자만 만들 수 있음 |
  | 속도 | 매우 빠름 | 상대적으로 느림 |

  그래서 **두 당사자가 서로만 확인하면 되는 경우**(웹훅, 내부 API)는 HMAC, **여러 검증자·부인 방지가 필요한 경우**(코드 서명, JWT `RS256`/`ES256`, 인증서)는 디지털 서명을 쓴다 → [[SSH 공개키 인증]], [[애드혹 서명 vs 정식 서명]].
- **HMAC ≠ 암호화** — 메시지 내용은 **평문 그대로** 간다. 기밀성이 필요하면 TLS나 별도 암호화가 필요하다.
- **HMAC ≠ 비밀번호 해싱** — 비밀번호 저장은 일부러 느린 bcrypt·Argon2를 쓴다(→ [[워크 팩터]]). HMAC은 빠르라고 만든 것.

## 왜 중요한가
- **웹훅 받는 엔드포인트를 만들면 반드시 마주친다.** 웹훅 URL은 공개돼 있으니, 서명 검증이 없으면 아무나 "결제 완료" 이벤트를 위조해 보낼 수 있다.
- 외부 API(AWS, 결제·거래소 API)를 SDK 없이 직접 호출하려면 HMAC 서명을 손으로 맞춰야 한다. **"서명이 안 맞는다" 디버깅의 대부분은 raw body·정규화·인코딩 문제**다.
- HMAC 자체는 깨진 적 없는 튼튼한 방식이지만, **사고는 거의 항상 주변 구현(비교 방식, 재전송, 키 유출)에서** 난다.

## 관련 개념
- [[암호화와 해싱]] — HMAC의 바탕이 되는 해시 함수
- [[쿠키 세션 JWT]] — JWT `HS256` = HMAC-SHA256
- [[S3 Presigned URL]] — AWS SigV4(`AWS4-HMAC-SHA256`)의 실제 사례
- [[API 토큰]] · [[Basic Auth와 Bearer 인증]] — 토큰을 그대로 보내는 방식 vs 요청마다 서명하는 방식
- [[SSH 공개키 인증]] — 비대칭 서명과의 비교
- [[JSON과 직렬화]] — raw body로 검증해야 하는 이유
- [[인증과 인가]] — HMAC은 "메시지 출처 인증", 사용자 인증과는 다른 층위
- [[OWASP Top 10]] — 암호화 실패(A02)·무결성 실패(A08) 맥락

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증** — Stripe 웹훅 헤더가 `t=<timestamp>,v1=<signature>` 형식이고 타임스탬프와 raw body를 함께 서명하며 SDK 기본 허용 오차가 **300초**라는 점(stripe-node `DEFAULT_TOLERANCE: 300`, stripe-ruby `DEFAULT_TOLERANCE = 300`), GitHub 웹훅이 타임스탬프 없이 raw body만 서명한다는 점을 Stripe SDK 문서·소스와 해설 글로 확인. HMAC 구조(RFC 2104, ipad `0x36`/opad `0x5c`), 길이 확장 공격, 상수 시간 비교, GitHub `sha256=` / Slack `v0=` 형식은 표준 문서 기준의 일반 지식으로 작성 — GitHub·Slack 공식 문서와는 따로 대조하지 않음.
