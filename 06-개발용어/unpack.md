---
type: 용어
tags: [IT, 개발용어]
created: 2026-07-01
aliases: [unpack, 언팩, 압축 해제, 구조 분해, destructuring, 언패킹]
---

# unpack

**한 줄 뜻**: 뭉쳐 있는 것을 **풀어 헤치는 것**. 맥락에 따라 ① 압축/아카이브 풀기, ② 여러 변수로 분해(destructuring), ③ 바이트를 구조화 데이터로 역변환.

**부연**:
- **압축 해제(archive)** — zip/tar 등에서 파일을 꺼냄(unzip). 묶기(pack/압축)의 반대.
- **구조 분해 할당(destructuring / unpacking)** — 한 번에 여러 변수로 풀기: `a, b = (1, 2)`(Python), `const [x, y] = arr`(JS). `*args`·스프레드도 언패킹.
- **역직렬화 계열** — `struct.unpack`은 바이너리 바이트를 값 튜플로 해석(pack의 반대). 파일 포맷·네트워크 프로토콜·C 연동에 사용. → [[JSON과 직렬화]]

**관련**: [[JSON과 직렬화]] · [[함수형 프로그래밍]]

---
> ✅ 교차검증 — unpack의 세 의미(아카이브 압축 해제 unzip, 구조 분해 할당 destructuring, `struct.unpack` 바이너리 역직렬화)를 MDN·Python 문서·복수 자료로 확인.
