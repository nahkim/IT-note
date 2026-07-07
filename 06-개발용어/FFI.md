---
type: 용어
tags: [IT, 개발용어]
created: 2026-07-07
aliases: [FFI, Foreign Function Interface, 외부 함수 인터페이스]
---

# FFI (Foreign Function Interface)

**한 줄 뜻**: 한 언어에서 **다른 언어(주로 C/C++ 같은 [[네이티브 코드]])로 작성된 함수를 호출**하는 메커니즘.

**부연**:
- 왜 쓰나 — OS/하드웨어 **네이티브 API 접근**, **성능**(무거운 연산을 C/Rust로), 기존 라이브러리 재사용.
- 예: Python **ctypes/cffi**, Java **JNI/JNA**, Rust **FFI**(`extern "C"`), Node **N-API**.
- 대개 고수준 언어가 저수준(시스템) 언어의 기능을 끌어다 쓰는 방향. → 그 결과물을 언어별로 쓰기 좋게 감싼 게 **[[바인딩]]**.

**관련**: [[바인딩]] · [[네이티브 코드]]

---
> ✅ 교차검증 — FFI(한 언어에서 타 언어 루틴 호출, C/C++ 등 네이티브 대상), ctypes·JNI·Rust FFI 예시를 Wikipedia(FFI) 등으로 확인.
