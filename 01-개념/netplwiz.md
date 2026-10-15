---
type: 개념
domain: 인프라
tags: [IT, 윈도우, 운영체제, 계정, 자동로그인, 보안]
created: 2026-10-14
aliases: [netplwiz, control userpasswords2, 사용자 계정 대화상자, 윈도우 자동 로그인]
---

# netplwiz

## 한 줄 정의
Windows의 **고급 "사용자 계정" 대화상자**를 여는 실행 명령. `Win + R` → `netplwiz` 로 열며, 주로 **비밀번호 없이 자동 로그인**을 켜거나, 로컬 계정을 추가·삭제하고 관리자/표준 그룹을 바꿀 때 쓴다.

## 여는 방법
| 방법 | 비고 |
|---|---|
| `Win + R` → `netplwiz` | 가장 흔한 방법 |
| `Win + R` → `control userpasswords2` | **같은 창**이 열린다(별칭) |
| cmd / PowerShell 에서 `netplwiz` | 관리자 권한 확인(UAC) 창이 뜰 수 있음 |

> 이름은 "**net**work **pl**aces **wiz**ard"에서 온 것으로 알려져 있지만, 지금은 네트워크와 상관없이 계정 관리 창이다.

## 창 구성
### ① 사용자 탭
- **"사용자 이름과 암호를 입력해야 이 컴퓨터를 사용할 수 있음"** 체크박스 ← 핵심
  - **체크 해제** → 확인 → 자동 로그인할 계정의 비밀번호 입력 → 다음 부팅부터 **로그인 화면 없이 바로 바탕화면**.
- **추가 / 제거** — 로컬 계정 또는 Microsoft 계정 추가·삭제.
- **속성 → 그룹 멤버 자격** — 표준 사용자 / 관리자 / 기타(Remote Desktop Users 등) 전환.
- **암호 재설정** — 선택한 로컬 계정 비밀번호 변경(현재 로그인한 계정은 `Ctrl+Alt+Del`로 변경하라고 안내).

### ② 고급 탭
- **고급 사용자 관리** → `lusrmgr.msc`(로컬 사용자 및 그룹, Pro 이상 에디션)로 이동.
- **보안 로그인** — 로그인 전에 `Ctrl+Alt+Del`을 누르도록 강제(가짜 로그인 화면 대비).

## 자동 로그인은 어떻게 동작하나
체크박스를 끄면 Windows가 **Winlogon 레지스트리**에 자동 로그인 정보를 기록한다.

```
HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon
  AutoAdminLogon   = "1"        ← 자동 로그인 켜짐
  DefaultUserName  = "계정명"
  DefaultDomainName= "PC명 또는 도메인"
```

- netplwiz로 설정하면 **비밀번호는 평문 레지스트리(`DefaultPassword`)가 아니라 LSA Secret**에 암호화되어 저장된다.
- 레지스트리를 **직접** 고쳐 `DefaultPassword`를 넣으면 → **평문**으로 남는다. 그래서 수동 편집보다 netplwiz나 Sysinternals **Autologon**(역시 LSA Secret 사용)이 낫다.
- 단, LSA Secret도 **관리자 권한만 있으면 복원 가능**한 수준의 보호다. "안전하게 숨김"이 아니라 "평문보다 낫다" 정도.

## 체크박스가 안 보일 때 (Windows 10 2004+ / 11)
**"보안 강화를 위해 이 장치에서 Microsoft 계정에 대해 Windows Hello 로그인만 허용"** 옵션이 켜져 있으면 체크박스가 **숨겨진다**.

해결 둘 중 하나:
1. **설정 → 계정 → 로그인 옵션** → 위 Windows Hello 전용 옵션 **끄기** → netplwiz 다시 열기.
2. 레지스트리 값 변경:
   ```
   HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device
     DevicePasswordLessBuildVersion = 0   (기본값 2 → 0)
   ```

> Microsoft 계정 + PIN만 쓰는 PC라면, 자동 로그인 시 입력하는 비밀번호는 **PIN이 아니라 Microsoft 계정 비밀번호**다. PIN을 넣으면 조용히 실패하고 로그인 화면이 다시 뜬다.

## 언제 쓰나 / 쓰면 안 되나
| 상황 | 판단 |
|---|---|
| 키오스크·사이니지·전시용 PC, 무인 재부팅 후 프로그램이 자동 실행돼야 하는 장비 | ✅ 자동 로그인 적합 (전용 저권한 계정으로) |
| 집에 혼자 쓰는 데스크톱 | △ 편의 vs 물리 접근 위험 판단 |
| 노트북·회사 업무 PC·도메인 가입 PC | ❌ 분실·도난 시 **누구나 바로 바탕화면** — 보안 정책([[ISMS]] 등) 위반 소지 |

- 자동 로그인 PC는 **BitLocker를 켜도** 부팅만 하면 계정이 열리므로, 디스크 암호화의 의미가 크게 줄어든다.
- 도메인 PC는 그룹 정책이 Winlogon 값을 덮어쓰거나, 정책상 자동 로그인이 막혀 있는 경우가 많다.

## 되돌리기
netplwiz에서 체크박스를 **다시 체크** → 확인. 그러면 `AutoAdminLogon`이 0이 되고 저장된 비밀번호도 정리된다(수동으로 넣은 `DefaultPassword`가 있다면 직접 삭제).

## 관련 개념
- [[ISMS]] — 계정·접근통제 관점에서 자동 로그인은 점검 항목
- [[RBAC]] — 관리자/표준 사용자 그룹 = 역할 기반 권한의 OS 버전
- [[systemd]] — 리눅스에서 "부팅 후 자동 실행"을 다루는 쪽(윈도우는 자동 로그인 + 시작 프로그램/작업 스케줄러)

## 내 생각 / 질문
- 무인 장비라면 자동 로그인 대신 **서비스(Windows Service)나 작업 스케줄러 "로그온 여부와 관계없이 실행"** 으로 풀 수 있는지 먼저 검토할 것.
- `lusrmgr.msc`, `secpol.msc`, `gpedit.msc` 같은 다른 `.msc` 관리 도구들도 정리해 볼 만하다.
