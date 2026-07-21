---
type: 개념
tags: [IT, DevOps, 운영, 모니터링, 성능]
created: 2026-07-20
aliases: [APM, 애플리케이션 성능 모니터링, Application Performance Monitoring, Application Performance Management, 관측 가능성, Observability, 분산 추적, Distributed Tracing]
---

# APM (애플리케이션 성능 모니터링)

## 한 줄 정의
애플리케이션이 **얼마나 빠르고 안정적으로 도는지**를 **코드·요청 수준까지** 들여다보며 측정·진단하는 모니터링. 서버 자원만 보는 인프라 모니터링을 넘어 **"이 요청이 어느 서비스의 어느 코드에서 느려졌나"**까지 추적한다. (Application Performance **Monitoring**, 넓게는 **Management**)

## 자세히

### 무엇을 보나 — 핵심 지표
- **골든 시그널(Google SRE)** — **지연시간(latency)** · **트래픽/처리량(traffic)** · **에러율(errors)** · **포화도(saturation)**. 이 넷만 봐도 대부분의 문제 징후를 잡는다. → [[레이턴시]]
- **Apdex (Application Performance Index)** — 응답시간 임계값을 기준으로 사용자 만족도를 **0~1 점수**로 환산한 표준 지표.

### 관측 가능성의 3요소 (Metrics · Logs · Traces)
APM은 **관측 가능성(observability)**의 핵심 부분. 셋을 함께 본다:
- **메트릭(Metrics)** — 응답시간·처리량·에러율·자원 사용 등 수치.
- **로그(Logs)** — 시각이 찍힌 이벤트 기록.
- **트레이스(Traces)** — 요청이 서비스들을 지나간 경로.

### 분산 추적 (Distributed Tracing) — APM의 심장
- 요청 하나에 **Trace ID**를 붙여 서비스 경계를 넘나들며 전파. 각 구간이 **스팬(span)**(시작·종료 시각, 담당 서비스, 메타데이터)으로 기록된다.
- → [[마이크로서비스]]처럼 요청이 여러 서비스를 거칠 때 **"어디서 느려졌는지"**를 한눈에. 느린 메서드·쿼리 같은 **코드 레벨**까지 짚는다.

### 어떻게 동작하나
- 앱 런타임에 **에이전트/계측(instrumentation)**을 심어 트레이스·메트릭을 수집 → 백엔드로 전송 → 대시보드·알림.
- **OpenTelemetry(OTel)** — 벤더 중립 **계측 표준**. OTel로 심어두면 Datadog ↔ New Relic ↔ 오픈소스를 **앱 코드 수정 없이** 갈아탈 수 있다(OTLP 수집).

### 도구
- **상용**: Datadog · New Relic · Dynatrace · AppDynamics · Elastic APM.
- **오픈소스**: Pinpoint(네이버 발원, Java/PHP 바이트코드 계측·오버헤드 ~3%) · SkyWalking · Jaeger · Zipkin · SigNoz. 국내는 상용 **제니퍼(JENNIFER)**, 오픈소스 **스카우터(Scouter)**도 널리 쓰인다.

### ⚠️ 헷갈리는 다른 뜻
2000~2010년대 국내에선 **APM = Apache + PHP + MySQL** 웹 서버 스택을 뜻하기도 했다("APM 설치"). 오늘날 IT 실무의 APM은 대부분 위의 **성능 모니터링**을 가리킨다.

## 왜 중요한가
- 사용자 체감 성능(느림·에러)은 **매출·이탈과 직결**. APM은 장애를 **터지기 전에** 징후로 잡고, 터졌을 땐 **원인 지점을 분 단위로** 좁힌다.
- 분산 환경에선 요청이 수많은 서비스를 거쳐 **로그만으론 원인 추적이 사실상 불가능** → 분산 추적이 필수가 된다.
- 인프라 [[관제]]가 "서버가 살아있나"라면, APM은 "**애플리케이션이 제대로, 빠르게 도나**" — 층이 다르고 서로 보완한다.

## 관련 개념
- [[관제]] — 상시 감시·대응. APM은 그중 '애플리케이션 성능' 층을 코드까지 파고드는 도구
- [[마이크로서비스]] — 분산 추적이 특히 빛나는 무대
- [[레이턴시]] — APM이 가장 먼저 보는 지표
- [[로드 밸런서]] · [[수평 확장]] — 성능·포화도 판단이 스케일링 결정으로 이어짐
- [[서킷 브레이커]] · [[타임아웃]] — APM이 잡아낸 지연·장애에 대응하는 복원력 패턴

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — APM(코드·요청 수준까지 보는 성능 모니터링), 골든 시그널(지연·트래픽·에러·포화), Apdex(0~1 만족도), 관측가능성 3요소(metrics·logs·traces), 분산 추적(Trace ID·span), OpenTelemetry(벤더 중립 계측·OTLP), 도구(Datadog·New Relic·Dynatrace·Elastic·오픈소스 Pinpoint 등)를 Coralogix·Elastic·SigNoz·Uptrace 등으로 확인. Pinpoint(네이버 발원, Java/PHP 바이트코드 계측 ~3% 오버헤드)도 확인.
