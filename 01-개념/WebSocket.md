---
type: 개념
tags: [IT, 웹, 네트워크, 기초]
created: 2026-06-11
aliases: [WebSocket, 웹소켓]
---

# WebSocket (웹소켓)

## 한 줄 정의
하나의 [[TCP-IP|TCP]] 연결 위에서 서버·클라이언트가 **양방향으로 실시간 통신**할 수 있게 유지되는 연결 프로토콜.

## 자세히
- [[HTTP와 HTTPS|HTTP]]는 "요청하면 응답"하는 단방향 왕복(클라이언트가 물어야 서버가 답함). 채팅·알림·실시간 시세처럼 **서버가 먼저 보내야** 하는 경우엔 불편하다.
- WebSocket은 **연결을 한 번 맺으면 끊지 않고 유지**(persistent), 양쪽이 **아무 때나 자유롭게**(full-duplex) 데이터를 주고받는다.
- 시작은 HTTP로: 클라이언트가 `Upgrade: websocket` 헤더로 요청 → 서버가 **`101 Switching Protocols`**로 응답하면 그때부터 WebSocket으로 전환(핸드셰이크).
- 주소 체계: **`ws://`**(평문) / **`wss://`**(TLS 암호화). 기본 포트는 HTTP처럼 80/443.
- 연결 후엔 HTTP 헤더(수백~수천 바이트)를 매번 안 붙여 **오버헤드가 작다**(프레임당 수 바이트).

## 왜 중요한가
- 실시간 채팅·알림·협업 편집·게임·라이브 대시보드의 표준 기술.
- "왜 폴링(주기적 새로고침) 대신 WebSocket을 쓰지?"의 답 — 지연·낭비를 줄인다.

## 관련 개념
- [[HTTP와 HTTPS]] — 핸드셰이크로 HTTP에서 전환, 한계를 보완하는 관계
- [[TCP-IP|TCP/IP]] — WebSocket이 올라타는 하위 연결
- [[REST API]] — 요청-응답형 API와 대비되는 실시간 통신

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — 단일 TCP·full-duplex·persistent, HTTP Upgrade→101 Switching Protocols 핸드셰이크, ws/wss(80/443), 낮은 오버헤드를 Wikipedia·websocket.org·Postman 등 복수 출처로 2회 확인.
