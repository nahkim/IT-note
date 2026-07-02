---
type: 용어
tags: [IT, 개발용어]
created: 2026-07-01
aliases: [busy loop, 바쁜 대기, busy waiting, busy-wait, spin loop, 스핀]
---

# busy loop (바쁜 대기)

**한 줄 뜻**: CPU를 **놓지 않고** 조건이 만족될 때까지 계속 도는 루프. "될 때까지 계속 확인"하느라 **대기하는 동안 CPU를 낭비**한다. (= busy waiting / spinning)

**부연**:
- 스레드가 잠들지(블로킹) 않고 `while (!조건) {}`처럼 루프를 돌며 반복 확인 → **컨텍스트 스위치가 없어** 아주 짧은 대기엔 빠르지만, 길어지면 CPU를 태운다.
- **스핀락(spinlock)** — 락을 얻을 때까지 spin하는 busy loop. 멀티코어에서 임계구역이 매우 짧을 때 유리.
- **CPU 레벨의 폴링**과 통함 — 잠들었다 깨우는 이벤트/인터럽트 방식의 반대. → [[폴링]]
- 보통 짧은 `sleep`·yield나 이벤트 대기(조건 변수 등)로 바꿔 낭비를 줄인다.

**관련**: [[폴링]] · [[동시성 문제]] · [[프로세스와 스레드]]

---
> ✅ 교차검증 — busy waiting(=busy loop/spinning: CPU를 점유한 채 반복 확인)·스핀락을 Wikipedia·Baeldung으로 확인.
