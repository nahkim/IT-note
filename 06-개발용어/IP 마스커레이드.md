---
type: 용어
tags: [IT, 개발용어, 네트워크]
created: 2026-07-01
aliases: [IP 마스커레이드, IP masquerade, 마스커레이드, MASQUERADE, IP 마스커레이딩]
---

# IP 마스커레이드 (IP Masquerade)

**한 줄 뜻**: 사설 IP를 가진 여러 기기가 **하나의 공인 IP를 공유해** 인터넷에 나가게 하는 **NAT 기법**. 리눅스 iptables의 `MASQUERADE` 타깃으로, **SNAT(출발지 주소 변환)의 한 형태**.

**부연**:
- 라우터가 나가는 패킷의 **출발지 사설 IP를 공인 IP로 바꾸고**, 포트로 연결을 추적한다. 응답이 오면 다시 원래 사설 IP·포트로 되돌려 전달. → 가정용 공유기가 하는 바로 그 일.
- iptables에선 `nat` 테이블의 **POSTROUTING 체인**에 규칙을 건다.
- **SNAT과의 차이** — 일반 SNAT은 공인 IP를 고정 지정, MASQUERADE는 **나가는 인터페이스의 IP를 동적으로** 사용 → IP가 자주 바뀌는 회선(DHCP·동적 IP)에 적합.

**관련**: [[TCP-IP]] · [[HTTP와 HTTPS]]

---
> ✅ 교차검증 — IP 마스커레이드(다대일 NAT, 사설 IP 다수가 공인 IP 1개 공유, iptables `MASQUERADE`=동적 SNAT, POSTROUTING)를 O'Reilly Linux NAG·GeeksforGeeks·TLDP HOWTO로 확인.
