# 04-뉴스-보안 자동 생성 — 설계

- 작성일: 2026-11-11
- 상태: 승인됨 (구현 계획 작성 전)

## 목표

기존 IT 뉴스 자동화(`04-뉴스/<DATE>.md`)와 별도로, 매일 보안 브리핑 노트 `04-뉴스-보안/<DATE>-보안.md`를 자동 생성한다.

- 수집 범위: 기관 보안권고, 벤더 패치/취약점(CVE), 침해사고·위협 동향, 정책·트렌드를 **모두** 다룬다.
- 출처: **공식 사이트(1차 출처) 기준**, 언어 제한 없음(한·영·일·중·독·불 등).
- 작성 언어: 한국어. 비한국어 원문은 원제목을 병기한다.
- 기존 `04-뉴스`의 `## 🔐 개발 / 보안` 섹션은 **변경하지 않는다**(일부 중복 허용).

## 비목표

- 기존 뉴스 프롬프트(`scripts/news-prompt.txt`)·노트 형식 변경
- 새 launchd 작업 추가
- 과거 날짜 소급 생성 기능

## 실행 구조

현행: launchd `com.nahkim.itnote-news` → `~/it-note-job/run.sh`(저장소 밖, 버전관리 안 됨) → 미러 `~/it-note-job/IT-note`에서 `claude -p` → 커밋·push → 볼트 `git pull --ff-only`.

변경: `run.sh`가 작업 목록 `[뉴스, 보안]`을 **순차** 실행한다.

| 항목 | 뉴스 | 보안 |
|---|---|---|
| 프롬프트 | `scripts/news-prompt.txt` | `scripts/security-prompt.txt` (신규) |
| 출처 목록 | — | `scripts/security-sources.md` (신규, 프롬프트가 읽음) |
| 결과 파일 | `04-뉴스/<DATE>.md` | `04-뉴스-보안/<DATE>-보안.md` |
| claude 타임아웃 | 1500s | 2100s (다국어 출처가 많아 더 길게) |
| 재시도 | 2회 | 2회 |
| 커밋 메시지 | `docs(뉴스): IT 뉴스 <DATE>` | `docs(보안): 보안 브리핑 <DATE>` |

- 작업별로 바뀌는 값(프롬프트·폴더·파일명 패턴·타임아웃·커밋 접두어)을 인자로 받는 함수 `run_job`으로 기존 3)~커밋 단계를 묶는다.
- 락·워치독·`run_limited`·mirror pull/push·볼트 동기화·셀프테스트는 **한 번만** 실행(현행 유지).
- "이미 존재하면 스킵"과 성공/실패 판정은 **작업별**로 한다. 한 작업의 실패가 다른 작업이나 push·볼트 동기화를 막지 않는다.
- 실패 알림 문구에 작업명을 넣는다(예: "실패: 2026-11-12 보안 노트를 만들지 못했습니다").
- 최종 종료 코드: 둘 중 하나라도 실패하면 1.
- 자정 넘김 대응(시도마다 TODAY 재계산), "날짜가 달라도 새 노트면 인정" 로직은 작업별 폴더 기준으로 동일하게 적용.

## 파일명 규칙

`04-뉴스-보안/<DATE>-보안.md` — 뉴스 노트와 basename이 겹치면 기존 `[[2026-11-10]]` 위키링크가 모호해지므로 `-보안` 접미사를 붙인다. 보안 노트 간 연속성 링크는 `[[<전날>-보안]]`.

## 노트 형식

```markdown
---
type: 보안뉴스
tags: [IT, 보안, 뉴스]
날짜: <DATE>
---

# 🔐 보안 브리핑 — <DATE>

> [[<직전 보안 노트>]]에서 이어짐 · 같은 날 IT 뉴스: [[<DATE>]] — 오늘의 흐름 요약 2~3줄

## 🚨 오늘 바로 할 일
- [ ] (구체 조치 3~5개: 제품·수정 버전·대상)

## 🏛️ 기관 보안권고
- 🇰🇷 **KISA** — 한국어 요약 …
- 🇯🇵 **JPCERT/CC** — 한국어 요약 … (원문: 「…」)

## 🩹 취약점·패치
| CVE | 제품 | CVSS | 실악용(KEV) | 수정 버전 | 출처 |
|---|---|---|---|---|---|

## 🕵️ 침해사고·위협 동향
## 📈 정책·트렌드
## 🔑 오늘의 키워드
## 📌 출처
- [KO] [제목](URL) · [EN] … · [JA] … · [ZH] …

---
> ✅ <DATE> 교차검증 — (무엇을 어떤 출처로 확인했는지)
> ⚠️ (정정·미확정 사항이 있으면)
```

규칙:
- 수집 기간: 직전 보안 노트 날짜 이후 ~ 오늘(첫 실행은 최근 24시간).
- 해당 내용이 없는 섹션은 "특이사항 없음" — 채우려고 지어내지 않는다.
- 비한국어 원문 항목은 `(원문: 「…」)`로 원제목 병기. 번역이 애매한 용어는 원문 표현을 함께 적는다.
- `[[위키링크]]`는 `01-개념/`에 실제 존재하는 노트에만 단다.
- 출처 링크마다 언어 태그 `[KO]/[EN]/[JA]/[ZH]/[DE]/[FR]` 등.

## 출처 정책 (`scripts/security-sources.md`)

| 구분 | 출처 |
|---|---|
| 🇰🇷 KO | KISA 보호나라/KrCERT 보안공지, 국가사이버안보센터(NCSC), 금융보안원, AhnLab ASEC |
| 🇺🇸 EN | CISA (KEV 카탈로그·Advisories·ICS Advisories), NVD, FBI IC3 |
| 🇯🇵 JA | JPCERT/CC, IPA, JVN |
| 🇨🇳🇹🇼 ZH | CNVD, CNNVD, CNCERT, TWCERT/CC |
| 🇪🇺 EU권 | ENISA, CERT-EU, 🇩🇪 BSI, 🇫🇷 CERT-FR(ANSSI), 🇬🇧 NCSC UK |
| 🌏 기타 | 🇦🇺 ACSC, 🇨🇦 Canadian Centre for Cyber Security, 🇸🇬 CSA |
| 벤더 PSIRT | Microsoft MSRC, Google(Chrome Releases·Android 보안 게시판), Apple 보안 업데이트, Cisco, Fortinet, Palo Alto Networks, Ivanti, Oracle, Adobe, Mozilla, Broadcom/VMware, SAP, GitHub Advisory Database |
| 위협 인텔 | Google GTIG/Mandiant, Microsoft Threat Intelligence, Cisco Talos, Palo Alto Unit 42, Kaspersky Securelist, ESET, Check Point Research |

검증 규칙:
- 모든 항목에 **1차 공식 출처 최소 1개**.
- CVE·CVSS·버전·피해 규모 등 구체 사실은 **서로 다른 2개 출처로 교차검증**. 두 번째 출처는 다른 공식 출처 또는 보안 전문 매체(BleepingComputer, The Hacker News, SecurityWeek, 보안뉴스 등).
- 공식 출처가 없는 정보는 제외하거나 `미확정`으로 표기.
- 사이트 접속 실패(차단·타임아웃)는 다른 출처로 대체하고, 실패한 주요 출처는 푸터 `⚠️`에 기록.

## 프롬프트 (`scripts/security-prompt.txt`) 요건

`news-prompt.txt`와 같은 골격을 따른다:
0) 작업 위치 고정 — 미러 안에서만, 볼트(`~/Documents/...`) 접근 금지(TCC EPERM).
1) KST 날짜 결정, `04-뉴스-보안/<DATE>-보안.md` 존재 시 즉시 종료.
2) 형식 파악 — 최신 보안 노트(없으면 이 스펙의 형식), 같은 날 `04-뉴스/<DATE>.md`(있으면), `01-개념/` 목록, `scripts/security-sources.md`.
3) 수집·검증 — 출처 정책대로.
4) 작성 — 노트 형식대로. `04-뉴스-보안/<DATE>-보안.md` 외 파일 수정 금지.
5) 저장 — `git add` 해당 파일, `docs(보안): 보안 브리핑 <DATE>` + Co-Authored-By 줄로 커밋, master에 push(충돌 시 `pull --rebase` 후 재시도).

## 일회성 수작업

- `04-뉴스-보안/` 폴더 생성.
- `00-Index/대문.md`의 `## 📰 뉴스` 아래에 보안 아카이브 진입 링크 추가(기존 `[[04-뉴스/README|IT 뉴스 아카이브]]` 형식을 따라 `04-뉴스-보안/README.md` 생성 여부는 `04-뉴스/README.md` 내용을 보고 맞춘다).
- 미러에서 커밋·push(볼트에서 직접 커밋하지 않는다 — 볼트 ff-only 동기화가 깨진다).

## 테스트

1. `run.sh` 문법 검사: `zsh -n run.sh`.
2. 보안 프롬프트 단독 수동 실행(미러에서 `claude -p "$(cat scripts/security-prompt.txt)"`) → 노트 품질·형식·출처 언어 다양성 확인. 뉴스 작업은 오늘자 노트가 있어 스킵된다.
3. `run.sh` 전체 실행(`launchctl kickstart`): 뉴스 SKIP, 보안 SKIP(2에서 생성됨) 경로와 로그 확인. 보안 노트를 지운 상태에서 한 번 더 돌려 생성·커밋·push·볼트 동기화까지 확인.
4. 실패 경로: 보안 프롬프트 경로를 일시적으로 틀리게 해 보안만 FAIL·알림, 뉴스·push는 정상인지 확인.
5. `run.sh` 수정 전 `run.sh.bak-2026-11-11` 백업.
