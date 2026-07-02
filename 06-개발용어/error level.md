---
type: 용어
tags: [IT, 개발용어]
created: 2026-07-01
aliases: [error level, errorlevel, 종료 코드, exit code, 반환 코드]
---

# error level (종료 코드 / ERRORLEVEL)

**한 줄 뜻**: 프로그램이 끝날 때 반환하는 **종료 코드(exit code)** — 특히 Windows 배치의 `ERRORLEVEL`. **0 = 성공, 0이 아니면 오류**를 뜻한다.

**부연**:
- **Windows CMD** — `%ERRORLEVEL%`가 마지막 명령의 종료 코드를 담는다. **Unix/셸**에선 `$?`가 같은 역할.
- 스크립트는 이 값으로 성공/실패를 분기한다. 예: [[curl]] `-f`는 4xx·5xx면 0이 아닌 종료 코드를 반환 → 배치·CI에서 실패 처리.
- (혼동 주의) **로그 레벨의 ERROR와는 다름** — 그건 로그 심각도(DEBUG/INFO/WARN/ERROR) 이야기이고, 여기서 error level은 '프로세스 종료 코드'.

**관련**: [[curl]] · [[프로세스와 스레드]]

---
> ✅ 교차검증 — Windows 배치 `ERRORLEVEL`(마지막 명령의 종료 코드, 0=성공/비0=오류)와 Unix `$?`의 대응을 ss64·복수 배치 문서로 확인.
