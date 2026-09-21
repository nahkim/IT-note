---
type: 개념
domain: 프론트엔드
tags: [IT, 프론트엔드, React, UI, 디자인시스템, 개발도구]
created: 2026-09-09
aliases: [shadcn, shadcn/ui, shadcn ui, 샤드씨엔, 샤드시엔, 쉐드씨엔, 샤드씨엔유아이, Radix UI, 라딕스, Base UI, 베이스UI, React Aria, Tailwind CSS, 테일윈드, class-variance-authority, cva, cn 유틸, components.json, 컴포넌트 레지스트리, registry, npx shadcn add, shadcn CLI]
---

# shadcn/ui

## 한 줄 정의
**"설치하는 UI 라이브러리"가 아니라 "복사해 오는 컴포넌트 코드"다.** CLI로 버튼·다이얼로그 같은 컴포넌트의 **소스 파일을 내 저장소에 써넣고**, 그 순간부터 그 코드는 내 것이 된다. 공식 문서의 한 문장이 전부를 말한다 — *"This is not a component library. It is how you build your component library."*

> 이름이 세 가지로 쓰인다: **shadcn**(만든 사람의 핸들) · **shadcn/ui**(컴포넌트 모음) · **`shadcn`**(npm에 올라간 CLI 패키지).

## 자세히

### 무엇이 다른가 — `npm install`이 없다
```
[기존 UI 라이브러리 — MUI, Chakra, Ant Design]
  npm install @mui/material
  import { Button } from "@mui/material"
  → 코드는 node_modules 안. 바꾸려면 props·테마·CSS 오버라이드·래핑

[shadcn/ui]
  npx shadcn@latest add button
  → components/ui/button.tsx 파일이 내 repo에 생성됨 (git에 커밋)
  import { Button } from "@/components/ui/button"
  → 바꾸려면 그 파일을 그냥 연다
```

기존 라이브러리는 **"커스터마이징이 필요해지는 순간부터"** 싸움이 시작된다. 스타일을 억지로 덮고, 없는 컴포넌트는 다른 라이브러리에서 가져와 API가 안 맞는 채로 섞는다. shadcn/ui는 그 지점을 **"애초에 코드를 줘 버림"** 으로 우회한다.

### 3층 구조 — 각 층이 하는 일
```
┌─ 내가 소유하는 층 ────────────────────────────────┐
│ components/ui/button.tsx   ← 내 repo. 마음대로 수정  │  ← shadcn/ui가 주는 것
│  · cva()로 variant/size 정의                       │
│  · cn()으로 클래스 병합                              │
└──────────────────┬───────────────────────────────┘
                   │
┌─ 스타일 층 ────────┴───────────────────────────────┐
│ Tailwind CSS + CSS 변수(세만틱 토큰)                 │  ← 런타임 CSS-in-JS 없음
└──────────────────┬───────────────────────────────┘
                   │
┌─ 동작·접근성 층 ────┴───────────────────────────────┐
│ 헤드리스 프리미티브 (npm 의존성으로 남는 유일한 부분)     │
│  Base UI (기본) / Radix UI / React Aria             │
│  · 포커스 트랩, 키보드 내비게이션, ARIA, 포탈, 위치 계산  │
└─────────────────────────────────────────────────┘
```

- **헤드리스(headless) 프리미티브** = 겉모습이 전혀 없고 **동작과 접근성만** 담당하는 컴포넌트. 다이얼로그를 열면 배경 스크롤을 막고 포커스를 안에 가두고 `Esc`로 닫히게 하는, 직접 만들면 반드시 틀리는 부분이다.
- **`cva`**(class-variance-authority) = `variant="destructive" size="sm"` 같은 **변형을 타입 안전하게** 클래스 조합으로 매핑하는 작은 유틸.
- **`cn()`** = `clsx` + `tailwind-merge`. 나중에 넘긴 `className`이 기본 클래스를 **이기게** 만드는 병합기(`px-2`와 `px-4`가 같이 붙는 사고를 막는다). 2026년 9월부터는 두 패키지를 따로 조합하지 않고 독립 패키지 **`cn`** 에서 import한다.

### 실제 사용 흐름
```bash
# 1) 프로젝트 초기화 — 템플릿(Next.js/Vite/Astro/Laravel/React Router/TanStack Start) 선택
npx shadcn@latest init

# 2) 컴포넌트 추가 — 파일이 써지고 필요한 의존성이 설치된다
npx shadcn@latest add button dialog form

# 3) 쓰기 전에 뭐가 써질지 먼저 보기
npx shadcn@latest add button --dry-run   # 안 쓰고 계획만
npx shadcn@latest add button --diff      # 내 로컬 수정분과의 차이
npx shadcn@latest add button --view      # 소스만 열어보기
```

`init`이 만드는 **`components.json`** 이 이 시스템의 설정 파일이다 — 스타일, Tailwind CSS 파일 경로, `baseColor`, 경로 별칭(`@/components`), 사용할 레지스트리 목록. CLI가 **내 프로젝트 구조에 맞게 코드를 변환해서** 써주는 근거가 여기 있다. (복사·붙여넣기로 쓸 거면 이 파일은 필요 없다.)

### 테마 = CSS 변수 + 세만틱 토큰 쌍
```css
--primary: oklch(0.205 0 0);
--primary-foreground: oklch(0.985 0 0);
```
```tsx
<div className="bg-primary text-primary-foreground">Hello</div>
```
**표면 색(`primary`) ↔ 그 위에 얹히는 글자·아이콘 색(`primary-foreground`)** 을 **항상 쌍으로** 정의하는 것이 규칙이다. `background`/`foreground`, `card`/`card-foreground`, `muted`/`muted-foreground`… 이 관례 덕에 **컴포넌트 클래스를 하나도 안 고치고 앱 전체 색을 바꿀 수 있고**, 다크 모드는 `.dark` 선택자 안에서 **같은 토큰을 다시 정의**하는 것으로 끝난다.

### styles — 색만 바꾸는 게 아니다
2026년 기준 8종의 스타일이 있다: **Vega · Nova · Maia · Lyra · Mira · Luma · Rhea · Sera**. 색 팔레트가 아니라 **모서리 곡률·간격·그림자·밀도까지 바꾸는 시각적 기준선**이다(예: Luma는 macOS Tahoe에서 딴 둥근 기하와 부드러운 elevation).

구현 방식도 바뀌었다. 예전처럼 컴포넌트 파일에 Tailwind 유틸리티 문자열을 길게 박아 넣지 않고, `cn-button-variant-default` 같은 **의미 있는 클래스 이름**을 쓰고 실제 유틸리티는 스타일 CSS 파일이 `@apply`로 채운다. 결과적으로 컴포넌트 TSX는 얇아지고, **스타일 교체 = CSS 교체**가 된다.

```tsx
// bases/base/ui/button.tsx (발췌)
const buttonVariants = cva("cn-button group/button inline-flex …", {
  variants: { variant: { default: "cn-button-variant-default", … } },
})
```

### 레지스트리 — 이 프로젝트의 진짜 발명
"컴포넌트를 파일 단위로 배포하는 규격"이다. 레지스트리 항목은 **JSON 하나**(파일 내용 + npm 의존성 + 레지스트리 의존성)이고, CLI는 그걸 받아 내 프로젝트에 쓴다. 그래서 **누구나 자기 레지스트리를 만들 수 있다.**

```json title="components.json"
{ "registries": { "@acme": "https://acme.com/r/{name}.json" } }
```
```bash
npx shadcn@latest add @acme/login-form   # 네임스페이스로 남의 레지스트리에서 설치
```

- **네임스페이스 레지스트리**(`@registry/name`) — 2025년 8월 CLI 3.0
- **GitHub 레지스트리** — 공개 저장소를 그대로 레지스트리로(2026-06), **비공개 저장소도**(2026-08, `gh` CLI 자격증명이나 토큰으로 인증)
- 컴포넌트만이 아니라 **테마·블록·훅·문서·에이전트 규칙**까지 항목이 될 수 있다
- **`--preset`** — 색·폰트·radius·아이콘 라이브러리를 담은 디자인 시스템 설정을 짧은 코드 하나로(`init --preset a1Dg5eFl`). 프롬프트에 붙여 v0·Claude·Codex에 그대로 넘길 수 있다

### AI 도구와의 접점
- **MCP 서버** — `npx shadcn@latest mcp init --client claude`. 에이전트가 레지스트리를 **검색·조회·설치**한다. "acme 레지스트리 컴포넌트로 랜딩 페이지 만들어" 수준의 지시가 성립한다. → [[MCP]] · [[AI 에이전트]]
- **shadcn/skills** — `npx skills add shadcn/ui`. `shadcn info --json`으로 내 프로젝트 설정(프레임워크·Tailwind 버전·별칭·base 라이브러리·설치된 컴포넌트)을 읽어 에이전트에 물려준다. 에이전트가 **첫 시도에 맞는 코드**를 쓰게 하는 장치.
- **왜 AI와 잘 맞나** — 코드가 열려 있고 컴포넌트마다 API가 일관되므로, 모델이 **읽고 고치고 새로 만들** 수 있다. `node_modules` 안에 감춰진 추상화는 이게 안 된다. 공식 설계 원칙에 **AI-Ready**가 아예 항목으로 들어가 있다.

### 설계 원칙 (공식 문서)
| 원칙 | 뜻 |
|---|---|
| **Open Code** | 컴포넌트 최상층 코드는 수정을 위해 열려 있다 |
| **Composition** | 모든 컴포넌트가 같은 조합 가능한 인터페이스를 공유 → 예측 가능 |
| **Distribution** | 플랫파일 스키마 + CLI로 코드를 배포 |
| **Beautiful Defaults** | 손 안 대도 괜찮은 기본 스타일, 서로 어울리는 한 벌 |
| **AI-Ready** | LLM이 읽고 이해하고 개선할 수 있는 코드 |

### 타임라인 — 헤드리스 층이 갈아탄 이야기
| 시점 | 일 |
|---|---|
| **2023-01** | 개인 사이드 프로젝트로 시작(Radix + Tailwind 기반) |
| 2024-08 | CLI 패키지가 `shadcn-ui` → **`shadcn`** 으로, `npx shadcn init` |
| 2024-10 · 12 | React 19 · 모노레포 지원 |
| **2025-02** | **Tailwind CSS v4** 지원, 레지스트리 스키마 공개 |
| 2025-04 · 08 | MCP 도입 → **CLI 3.0**(네임스페이스 레지스트리, 인증, 레지스트리 엔진 재작성) |
| 2025-12 | `npx shadcn create` — Radix/Base UI 둘 다 선택 가능 |
| **2026-03** | **CLI v4** — skills, `--preset`, `--dry-run/--diff/--view`, 프로젝트 템플릿 |
| **2026-07-02** | **Base UI가 새 프로젝트의 기본값**(Radix는 계속 지원), 이후 **React Aria**도 1급 base로 추가 |
| 2026-09 | `cn` 유틸이 독립 패키지로 분리 |

**Base UI로 기본값이 옮겨간 배경**: Radix를 만든 사람들이 그 경험을 갖고 새로 만든 것이 Base UI다. shadcn 측은 *"운영 중인 앱에 할 수 있는 최악의 일이 컴포넌트 라이브러리를 갈아타는 것"* 이라며 교체 대신 **양쪽 다 지원**을 택했고, `shadcn/create` 사용자들이 Base UI를 Radix보다 2:1로 고르자 기본값만 바꿨다. **Radix는 폐기(deprecate)되지 않았고 마이그레이션은 강제되지 않는다.**

```bash
npx shadcn init -b radix          # Radix로 새로 시작
npx shadcn init --base aria       # React Aria로
npx shadcn@latest migrate radix   # 기존 프로젝트를 점진적으로 이전
```

### 트레이드오프 — 여기가 진짜 판단 지점
- **⚠️ 업데이트를 npm이 대신 해주지 않는다.** 내 파일이 되었으므로 상류(upstream)의 버그 수정·개선은 자동으로 안 온다. `--diff`로 확인하고 손으로(혹은 에이전트에게) 병합해야 한다. → [[형상관리]]
  - 단, **접근성·동작 로직은 헤드리스 프리미티브(`@base-ui/react` 등)에 있으므로 의존성 업데이트로 받는다.** 손으로 관리해야 하는 건 **디자인에 가까운 최상층**뿐이라는 게 이 구조의 방어 논리다.
- **⚠️ 코드 소유 = 유지보수 소유.** 팀원 각자가 `button.tsx`를 고치기 시작하면 디자인 시스템이 조용히 갈라진다. 규칙과 리뷰가 없으면 "복사해 오는 자유"가 그대로 부채가 된다.
- **⚠️ 레지스트리에서 오는 코드는 서드파티 코드다.** 남의 레지스트리·MCP를 통해 들어온 파일이 내 저장소로 바로 커밋된다 → `npm install`과 같은 공급망 신뢰 문제인데, **리뷰 지점이 코드 리뷰로 옮겨온다**는 차이가 있다. `--view`·`--dry-run`으로 먼저 보고, 출처 모르는 레지스트리는 붙이지 말 것. → [[XSS]]
- **Tailwind와 한 몸이다.** Tailwind를 안 쓰는 프로젝트에는 사실상 맞지 않는다.
- **React 중심.** Svelte·Vue·Solid 포팅은 커뮤니티 프로젝트이고 별개로 관리된다.
- **초기 스캐폴딩이 크다.** 컴포넌트 수십 개를 받으면 그만큼의 파일이 내 코드베이스 diff에 잡힌다.

### 다른 선택지와의 비교
| | 코드 위치 | 스타일 방식 | 커스터마이징 | 업데이트 |
|---|---|---|---|---|
| **shadcn/ui** | **내 repo** | Tailwind + CSS 변수 | 파일을 직접 수정 | 수동(`--diff`) |
| MUI / Ant Design | node_modules | 자체 테마 시스템 | props·theme·오버라이드 | `npm update` |
| Chakra UI | node_modules | 스타일 props | 테마 확장 | `npm update` |
| **Base UI / Radix / React Aria** | node_modules | **없음(헤드리스)** | 스타일을 내가 전부 | `npm update` |
| daisyUI | node_modules(CSS) | Tailwind 플러그인 | 클래스·테마 변수 | `npm update` |

즉 shadcn/ui는 **"헤드리스 라이브러리 + 예쁜 기본 스타일 + 그걸 내 repo로 옮겨주는 배포 도구"** 의 조합이고, 새로운 런타임을 하나도 추가하지 않는다.

### 규모 감각
2026년 9월 현재 GitHub **12만 스타 이상**, MIT 라이선스, CLI 최신 버전 **4.21.0**. 만든 사람은 핸들 **shadcn**으로만 알려진 Vercel의 디자인 엔지니어이고, Vercel의 **v0**이 생성하는 코드가 이 컴포넌트를 기본으로 쓴다.

## 왜 중요한가
- **"라이브러리 대신 코드를 배포한다"는 발상**이 프론트엔드의 기본값을 바꿨다. 추상화를 하나 더 얹어 커스터마이징을 막는 대신, **추상화를 걷어내고 소유권을 넘긴다.**
- **[[LSP]]와 같은 계열의 교훈** — 문제를 규격(플랫파일 스키마 + CLI)으로 옮기면 생태계가 알아서 자란다. 컴포넌트 레지스트리가 사실상의 표준이 되어 서드파티 블록·테마·유료 템플릿 시장이 그 위에 생겼다.
- **AI 코딩 시대에 유리한 구조**를 우연이 아니라 설계로 갖췄다. 에이전트가 고칠 수 있는 코드는 `node_modules` 밖에 있는 코드이고, MCP·skills·preset은 그 전제 위에 올라간 도구다. → [[프롬프트 엔지니어링]] · [[AI 에이전트]]
- **접근성 부채를 줄인다.** 다이얼로그·콤보박스·메뉴의 키보드·포커스·ARIA를 직접 구현하는 것은 거의 언제나 실패한다. 그 층만 의존성으로 남긴 분리가 실용적이다.
- 반대로 **"업데이트를 누가 책임지는가"** 를 팀이 명시적으로 결정하게 만든다. 편해 보이는 자유의 대가가 어디로 갔는지 아는 것이 도입 판단의 핵심이다.

## 관련 개념
- [[DOM]] — 컴포넌트가 최종적으로 만드는 것
- [[브라우저 렌더링 과정]] · [[리플로우]] — CSS 변수 기반 테마가 런타임 CSS-in-JS보다 유리한 이유
- [[MCP]] — 에이전트가 레지스트리를 도구로 쓰는 통로
- [[AI 에이전트]] · [[프롬프트 엔지니어링]] — skills·preset이 겨냥하는 사용자
- [[LSP]] — "규격으로 N×M을 N+M으로" 같은 발상
- [[JSON과 직렬화]] — 레지스트리 항목이 곧 JSON 문서
- [[형상관리]] · [[릴리즈]] — 컴포넌트를 커밋으로 관리한다는 선택의 결과
- [[클라이언트 앱]] · [[애플리케이션 형태]] — 어디에 쓰이는가
- [[개발자 도구]] — 생성된 클래스·CSS 변수를 확인하는 곳
- [[XSS]] — 외부 레지스트리 코드를 들이는 일의 신뢰 문제

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — 공식 문서(ui.shadcn.com)와 저장소(github.com/shadcn-ui/ui) 원문으로 확인. *"This is not a component library. It is how you build your component library."* 와 5개 설계 원칙(**Open Code · Composition · Distribution · Beautiful Defaults · AI-Ready**)은 `apps/v4/content/docs/(root)/index.mdx` 원문. 테마의 **세만틱 토큰 쌍 규칙**(`primary`/`primary-foreground`, `.dark` 선택자에서 같은 토큰 재정의)과 `components.json`의 `cssVariables`·`baseColor`·`style`은 `theming.mdx`·`components-json.mdx`로 확인. **base가 3종(`base`=Base UI / `radix` / `aria`)**, **style이 8종(Vega·Nova·Maia·Lyra·Mira·Luma·Rhea·Sera)** 인 것은 `apps/v4/registry/bases`·`apps/v4/registry/styles` 디렉터리 실물로 확인. `cn-button-variant-*` 방식의 스타일 분리는 `registry/bases/base/ui/button.tsx`와 `registry/styles/style-nova.css` 소스로 확인(`cva` + `cn` 사용, `import { cn } from "cn"`). **Base UI 기본값 전환은 2026-07-02**(Base UI 1.6.0·주간 6M+ 다운로드, shadcn/create에서 Base UI:Radix = 2:1, *"the worst thing you can do for your production app is switch component libraries"*, Radix 미폐기, `init -b radix`)이고 **React Aria 1급 base 추가는 2026-07-17**(`init --base aria`)임을 해당 changelog 원문으로 확인. **CLI v4는 2026-03-06**(skills·`--preset`·`--dry-run/--diff/--view`·템플릿), **CLI 3.0 + MCP는 2025-08**(네임스페이스 레지스트리·인증·엔진 재작성), **Tailwind v4는 2025-02**, **React 19는 2024-10**, **`npx shadcn init`으로의 CLI 개칭은 2024-08**, **GitHub 레지스트리 2026-06 / 비공개 GitHub 레지스트리 2026-08**, **`cn` 패키지 분리는 2026-09-03**으로 changelog 파일명·날짜에서 확인. `shadcn eject`(2026-05-31)로 `shadcn/tailwind.css` 인라인화가 가능한 것도 원문 확인. 저장소는 **2023-01-04 생성 · MIT · 스타 123,433**(GitHub API, 2026-09-09 조회), npm `shadcn` **latest 4.21.0**(registry.npmjs.org 조회). 제작자가 핸들 `shadcn`으로 활동하는 Vercel 디자인 엔지니어라는 점은 2차 자료(Vercel·해설 기사) 기준.
