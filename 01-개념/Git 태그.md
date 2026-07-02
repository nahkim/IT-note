---
type: 개념
tags: [IT, 도구, Git, 버전관리]
created: 2026-07-01
aliases: [Git 태그, git tag, lightweight 태그, annotated 태그]
---

# Git 태그 — lightweight vs annotated

## 한 줄 정의
태그(tag)는 특정 커밋에 붙이는 **'이름표'**(보통 릴리즈 버전 `v1.0.0` 표시). 만드는 방식이 둘 — **lightweight**(단순 포인터)와 **annotated**(메타데이터를 담은 정식 객체).

## 자세히

### 공통점
- 둘 다 **특정 커밋을 가리키는 이름**. 브랜치와 달리 **움직이지 않는 고정 지점**이다.
- 커밋 히스토리의 특정 순간(릴리즈·마일스톤)을 사람이 읽는 이름으로 표시하는 것이 목적.

### Lightweight 태그
- 그냥 **커밋을 가리키는 참조(ref)** — 이동하지 않는 북마크일 뿐.
- **추가 정보 없음**: 태거·날짜·메시지·서명이 전부 없다.
- 만들기: `git tag v1.0-tmp` (옵션 없이 이름만).
- 용도: **임시·개인·로컬** 표시. 보통 원격에 push하지 않는다.

### Annotated 태그
- Git 저장소에 **독립된 tag 객체**로 저장 — **태거 이름·이메일·날짜 + 태깅 메시지 + 체크섬**을 담는다.
- **GPG 서명** 가능(`-s`) → 나중에 진위 검증(`git tag -v <name>`).
- 만들기: `git tag -a v1.0.0 -m "첫 정식 릴리즈"` (서명은 `git tag -s v1.0.0 -m "..."`).
- 용도: **릴리즈·마일스톤** 등 공개·영구 표시. push 대상.

### 한눈에 비교
| 항목 | Lightweight | Annotated |
|---|---|---|
| 저장 방식 | ref(포인터)만 | **독립 tag 객체** |
| 태거·날짜·메시지 | ✗ | ✓ |
| GPG 서명·검증 | ✗ | ✓ |
| 만들기 | `git tag <name>` | `git tag -a <name> -m "..."` |
| 주 용도 | 임시·로컬 마킹 | 릴리즈·공개 |

### 알아둘 동작
- `git show <tag>` — annotated는 **태거·메시지까지**, lightweight는 가리키는 커밋만 보여준다.
- `git describe` — 기본은 **annotated 태그만** 사용(가장 가까운 태그 기준). lightweight까지 포함하려면 `--tags`.
- **push는 기본으로 안 됨** — `git push origin <tag>` 또는 `git push --tags`로 명시.
- 삭제 — 로컬 `git tag -d <name>`, 원격 `git push origin --delete <tag>`.

## 왜 중요한가
- **릴리즈엔 annotated가 정석** — 누가·언제·왜 태깅했는지 기록되고 **서명·검증**까지 되므로, 배포 이력의 신뢰성이 올라간다([[릴리즈]] 버전을 커밋에 고정).
- lightweight는 "지금 이 지점을 잠깐 표시" 용도. 실수로 push하면 릴리즈 이력이 지저분해질 수 있어 **목적에 맞게 구분**해서 쓴다.

## 관련 개념
- [[Git]] — 태그가 속한 버전 관리 도구
- [[릴리즈]] — 태그로 릴리즈 버전(SemVer)을 특정 커밋에 고정
- [[CI-CD]] — 태그 push를 트리거로 릴리즈 파이프라인 실행
- [[암호화와 해싱]] — annotated 태그의 GPG 서명·SHA 체크섬

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — lightweight(이름+커밋 포인터, 메타데이터·서명 없음, `git tag <name>`) vs annotated(태거·날짜·메시지·체크섬을 담은 독립 객체, GPG 서명 가능, `git tag -a`), 릴리즈엔 annotated 권장, `git describe`가 기본적으로 annotated만 사용하는 점을 Atlassian Git 튜토리얼·Pro Git 계열 자료로 확인.
