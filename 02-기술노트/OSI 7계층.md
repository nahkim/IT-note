---
type: 기술노트
tags: [IT, 노트, 네트워크]
출처: (웹 교차검증 정리 — ISO/IEC 7498 · Check Point · Imperva)
종류: 정리
읽은날: 2026-07-03
별점: 
aliases: [OSI 7계층, OSI 모델, OSI, ISO layer, ISO 계층, 7 layer]
---

# 📝 OSI 7계층 (ISO 네트워크 참조 모델)

## 한 줄 요약
OSI 7계층은 **ISO가 만든 네트워크 통신 참조 모델**(1984, ISO/IEC 7498). 통신 과정을 7단계로 쪼개 **각 계층이 한 가지 역할만** 맡게 한다. 실무에선 "그건 L3 문제", "L7 로드밸런서"처럼 **계층 번호로 소통하는 공용어**.

## 핵심 내용

### 1. 7계층 (아래 L1 → 위 L7)
| L | 계층 | 역할 | PDU | 예시·장비 |
|---|---|---|---|---|
| **7** | Application (응용) | 사용자 앱 프로토콜 | data | HTTP·DNS·SMTP·FTP |
| **6** | Presentation (표현) | 인코딩·암호화·압축 | data | TLS·문자셋·[[JSON과 직렬화]] |
| **5** | Session (세션) | 연결 수립·유지·종료 | data | 세션 관리 |
| **4** | Transport (전송) | 종단 간 전달·포트·신뢰성 | 세그먼트/데이터그램 | **TCP·UDP** |
| **3** | Network (네트워크) | 라우팅·논리 주소 | 패킷(packet) | **IP**·ICMP·라우터 |
| **2** | Data Link (데이터링크) | 인접 노드 간·MAC·오류검출 | 프레임(frame) | 이더넷·**스위치** |
| **1** | Physical (물리) | 비트·전기/광 신호·전송 매체 | 비트(bit) | 케이블·리피터·허브 |

### 2. 캡슐화 (계층이 협력하는 방식)
- **보낼 때** — 데이터가 L7 → L1로 내려가며 각 계층이 **자기 헤더를 덧붙인다**(캡슐화).
- **받을 때** — L1 → L7로 올라가며 **헤더를 하나씩 벗긴다**(역캡슐화).
- 덕분에 각 계층은 **자기 일만** 하고, 아래 계층이 어떻게 나르는지는 몰라도 된다(관심사 분리 → 한 계층 기술을 바꿔도 나머지 영향 최소).

### 3. OSI vs TCP/IP 모델
- **TCP/IP 4계층**에 매핑: OSI **5·6·7 → Application**, **4 → Transport**, **3 → Internet**, **1·2 → Network Access**.
- 요지: **OSI는 모두가 인용하는 '번호판'**(개념·용어), **TCP/IP는 실제로 패킷을 나르는 스택**(현실 구현, → [[TCP-IP]]).

### 4. 실무에서 자주 쓰는 표현
- **L2 스위치**(MAC 기반) vs **L3 라우터**(IP 기반).
- **L4 로드밸런서**(IP·포트로 분배, 빠르고 프로토콜 무관) vs **L7 로드밸런서**(HTTP의 경로·호스트·쿠키로 분배) → [[로드 밸런서]] · [[리버스 프록시]].
- "**L7에서 논다**" = 애플리케이션 계층. **HTTPS = HTTP(L7) over TLS**(암호화, 대략 표현계층 L6 — 실무상 L4~L7 사이에 걸친다고도).

## 코드 / 예시
```
[보내는 쪽]                         [받는 쪽]
 L7 App     데이터                    L7 App     ▲ 헤더 다 벗김
 L6 Present +표현/암호화               L6 Present │
 L5 Session +세션                     L5 Session │  (역캡슐화)
 L4 Trans   +TCP헤더(세그먼트)         L4 Trans   │
 L3 Net     +IP헤더(패킷)              L3 Net     │
 L2 Link    +MAC헤더(프레임)           L2 Link    │
 L1 Phys    비트 ────────────────▶ 매체 ───▶ L1 Phys
                       (캡슐화하며 내려감 → 물리 매체 → 올라오며 벗김)
```

## 기억할 문장 / 핵심 포인트
> "**OSI는 번호판, TCP/IP는 실제 차.**" — 대화·설계는 OSI 계층 번호로 하고, 실제 통신은 TCP/IP 스택이 한다.
> 암기법(L1→L7): **P**lease **D**o **N**ot **T**hrow **S**ausage **P**izza **A**way (Physical·Data link·Network·Transport·Session·Presentation·Application).
> "L4냐 L7이냐"는 로드밸런서·프록시·방화벽을 고를 때 늘 나오는 질문 — **어느 계층 정보로 판단하느냐**의 차이.

## 등장하는 개념
- [[TCP-IP]] — OSI를 실제로 구현한 4계층 스택
- [[HTTP와 HTTPS]] · [[DNS]] — 대표적 L7 프로토콜
- [[HTTP 헤더]] · [[JSON과 직렬화]] — L7 데이터 / L6 표현
- [[암호화와 해싱]] — TLS(표현계층 부근) 암호화
- [[로드 밸런서]] · [[리버스 프록시]] — L4 vs L7 분배의 실제

## 내 생각 / 적용할 점
-

---
> ✅ **웹 교차검증 완료** — OSI 7계층(ISO 1984·ISO/IEC 7498), 각 계층 역할과 PDU(bit·frame·packet·segment/datagram·data), 캡슐화, TCP/IP 매핑(OSI 5-6-7→App, 1-2→Network Access), "OSI는 번호판·TCP/IP는 실제 스택", L4 vs L7 로드밸런싱을 Check Point·Imperva·ComputingForGeeks 등으로 확인.
