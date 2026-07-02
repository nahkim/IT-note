---
type: 개념
tags: [IT, 보안, 웹]
created: 2026-07-02
aliases: [OWASP Top 10, OWASP, 오와스프]
---

# OWASP Top 10

## 한 줄 정의
**OWASP**(Open Worldwide Application Security Project)가 **웹 애플리케이션에서 가장 흔하고 위험한 보안 위험 10가지**를 실제 취약점 데이터 기반으로 추려 발표하는 표준 목록. 웹 보안의 사실상 체크리스트. **현재 최신은 2025 판**(2025년 11월 발표 → 2026년 1월 최종 공개).

## 자세히

### OWASP Top 10:2025 (현재 최신)
1. **A01 Broken Access Control (접근 통제 실패)** — 권한 없는 자원·기능 접근. 여전히 1위. (2021의 SSRF가 이 항목으로 흡수) → [[인증과 인가]]
2. **A02 Security Misconfiguration (보안 설정 오류)** — 기본 계정·불필요 기능·과도한 권한 노출 등. (2021 A05 → 2위로 상승)
3. **A03 Software Supply Chain Failures (소프트웨어 공급망 실패)** — *신규/확장*. 취약·구형 컴포넌트를 넘어 **빌드·배포·의존성 전반**의 공급망 위협으로 범위 확대. → [[CI-CD]]
4. **A04 Cryptographic Failures (암호화 실패)** — 약한 알고리즘·평문 저장/전송 등. (2021 A02 → 하락) → [[암호화와 해싱]]
5. **A05 Injection (인젝션)** — SQL·OS 명령·XSS 등 **신뢰되지 않은 입력이 코드로 실행**. (2021 A03 → 하락)
6. **A06 Insecure Design (안전하지 않은 설계)** — 구현 버그와 별개인 **설계 단계의 결함**.
7. **A07 Authentication Failures (인증 실패)** — 취약한 로그인·세션 관리. → [[쿠키 세션 JWT]] · [[인증과 인가]]
8. **A08 Software or Data Integrity Failures (무결성 실패)** — 검증 없는 업데이트·역직렬화·파이프라인 변조.
9. **A09 Security Logging and Alerting Failures (로깅·경보 실패)** — 탐지·대응을 어렵게 하는 로깅/알림 부재.
10. **A10 Mishandling of Exceptional Conditions (예외 상황 처리 미흡)** — *신규*. 오류·예외를 잘못 처리해 생기는 정보 노출·비정상 동작.

### 2021 → 2025 주요 변화
- **신규 2개** — A03 소프트웨어 공급망 실패, A10 예외 상황 처리 미흡.
- **SSRF 독립 항목 삭제** — 2021의 A10 SSRF는 **A01 접근 통제로 흡수**(실무에선 여전히 중요 — 예: [[2026-06-24|Cisco Unified CM SSRF]] 실악용).
- **순위 이동** — 보안 설정 오류 ↑(A05→A02), 암호화 실패 ↓(A02→A04), 인젝션 ↓(A03→A05).
- **명칭 변경** — A07 "Identification and Authentication Failures"→"Authentication Failures", A09 "…Monitoring…"→"…Alerting…".
- **데이터 규모** — 약 400개(2021) → **589개 CWE**(2025) 분석.

### 성격·주의
- **완전한 체크리스트가 아니라 '가장 흔한 위험'의 인식 도구** — 10개를 다 막았다고 안전한 건 아니다.
- 3~4년 주기로 실제 데이터 기반 갱신 → **어느 판(version)인지** 항상 확인. 항목·순위가 달라진다.
- 다른 OWASP Top 10도 있음 — **API Security Top 10**, **LLM Applications Top 10**(생성형 AI), Mobile 등 별도 목록.

## 왜 중요한가
- 웹 보안의 **공통 언어이자 최소 기준선**. 개발·코드 리뷰·보안 감사·컴플라이언스·교육에서 널리 인용된다.
- "무엇부터 막아야 하나"의 **우선순위를 데이터로** 제시 — 특히 1위 접근 통제·신규 공급망 항목은 실무 최다 사고 영역.

## 관련 개념
- [[인증과 인가]] — A01 접근 통제 · A07 인증
- [[암호화와 해싱]] — A04 암호화 실패
- [[관계형 데이터베이스와 SQL]] — A05 인젝션(SQL 인젝션)
- [[CI-CD]] — A03 공급망 · A08 무결성(파이프라인)
- [[HTTP와 HTTPS]] · [[HTTP 헤더]] · [[CORS]] — 전송 보안·설정
- [[쿠키 세션 JWT]] · [[OAuth]] — 인증·세션 관리

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — 최신은 **OWASP Top 10:2025**(2025-11 발표·2026-01 최종). 공식 목록 A01 Broken Access Control · A02 Security Misconfiguration · A03 Software Supply Chain Failures(신규) · A04 Cryptographic Failures · A05 Injection · A06 Insecure Design · A07 Authentication Failures · A08 Software or Data Integrity Failures · A09 Security Logging and Alerting Failures · A10 Mishandling of Exceptional Conditions(신규), SSRF의 A01 흡수·589 CWE 분석을 OWASP 공식(owasp.org/Top10/2025)·Qualys/GitLab 분석으로 확인.
