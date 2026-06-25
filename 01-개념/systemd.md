---
type: 개념
tags: [IT, 리눅스, 운영체제, DevOps]
created: 2026-06-25
aliases: [systemd, 시스템d, systemctl]
---

# systemd

## 한 줄 정의
대부분의 리눅스 배포판에서 쓰는 **시스템·서비스 관리자**. 부팅 후 가장 먼저 뜨는 **PID 1** 프로세스로, 다른 모든 서비스의 시작·중지·감시를 담당한다.

## 자세히

### 무엇을 하나
- 커널이 부팅을 마치면 **첫 사용자 공간 프로세스(PID 1)** 로 systemd가 뜨고, 이후 모든 서비스를 띄우고 관리한다. (옛 `SysVinit`/`init` 스크립트를 대체)
- 단순 부팅뿐 아니라 **서비스 감시·재시작, 로그 수집, 타이머(크론 대체), 소켓 활성화, 마운트** 등을 통합 관리.

### 유닛(Unit) — systemd가 다루는 모든 것
- systemd가 관리하는 모든 자원을 **유닛**이라 부르고, 각 유닛은 **유닛 파일**(설정 파일)로 정의된다.
- 주요 유닛 타입:
  - **`.service`** — 데몬/프로세스 (가장 많이 씀). 옛 init 스크립트에 해당.
  - **`.target`** — 여러 유닛을 묶는 **동기화 지점**. 옛 *런레벨(runlevel)* 을 대체 (예: `multi-user.target`, `graphical.target`).
  - **`.timer`** — 시간 기반 실행 (cron 대체).
  - **`.socket`** — 소켓 활성화: 요청이 들어오면 그때 서비스를 띄움.
  - **`.mount` / `.automount`** — 파일시스템 마운트.
- 유닛 간 **의존성**(`After=`, `Requires=`, `Wants=`)으로 부팅 순서와 관계를 정의한다.

### systemctl — 제어 명령
- systemd를 다루는 **중심 도구**.
  - `systemctl start|stop|restart|reload <서비스>` — 즉시 제어 (지금 켜고 끔)
  - `systemctl enable|disable <서비스>` — **부팅 시 자동 시작** 여부 (지금 상태와 별개)
  - `systemctl status <서비스>` — 상태·최근 로그 확인
  - `systemctl daemon-reload` — 유닛 파일을 고친 뒤 다시 읽기
- 핵심 구분: **`start`(지금) ≠ `enable`(부팅 시)**. 둘 다 해야 "지금도 켜지고 재부팅해도 켜진다".

### journald — 통합 로그
- `systemd-journald`가 커널·서비스·앱 로그를 **한 곳에 구조화된 바이너리 형식**으로 모은다.
- `journalctl -u <서비스>` 로 특정 서비스 로그를, `journalctl -f` 로 실시간 추적.

## 왜 중요한가
- 리눅스 서버에서 **서비스를 데몬으로 띄우고, 죽으면 자동 재시작하고, 부팅 시 자동 실행**시키는 표준 방법.
- 내가 만든 앱(FastAPI, 봇, 백그라운드 워커 등)을 `.service` 파일 하나로 안정적으로 운영할 수 있다.
- 도커 컨테이너 안에서는 보통 systemd를 쓰지 않지만(컨테이너는 프로세스 1개 원칙), **호스트 서버 운영**에선 거의 필수 지식.

## 관련 개념
- [[프로세스와 스레드]] — systemd는 PID 1로 모든 프로세스의 부모·감시자
- [[환경 변수]] — 유닛 파일의 `Environment=` / `EnvironmentFile=` 로 서비스에 환경 변수 주입
- [[컨테이너와 Docker]] — 컨테이너는 systemd 대신 단일 프로세스, 운영 철학 대비
- [[FastAPI]] — 직접 만든 서버를 `.service`로 등록해 데몬화하는 전형적 사례

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — PID 1 시스템·서비스 관리자, 유닛/유닛 파일(.service·.target·.timer·.socket), systemctl(start vs enable), 타깃=런레벨 대체, journald 구조화 로그를 Red Hat·SUSE·DigitalOcean 등 복수 출처로 확인.
