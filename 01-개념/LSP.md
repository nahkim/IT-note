---
type: 개념
domain: CS기초
tags: [IT, 개발도구, 에디터, 프로토콜, 언어]
created: 2026-09-02
aliases: [LSP, Language Server Protocol, 언어 서버 프로토콜, 랭기지 서버, language server, 언어 서버, rust-analyzer, gopls, clangd, pyright, tsserver, DAP, Debug Adapter Protocol, BSP, Build Server Protocol, 리스코프 치환 원칙, Liskov Substitution Principle, 행위 하위 타입, behavioral subtyping]
---

# LSP (Language Server Protocol)

## 한 줄 정의
**에디터와 "언어를 이해하는 부분"을 분리하는 프로토콜.** 자동완성·정의로 이동·오류 밑줄 같은 기능을 에디터마다 언어마다 따로 만들던 것을, **언어별 서버 하나 + 에디터별 클라이언트 하나**로 바꿨다. [[JSON과 직렬화|JSON]]-RPC 2.0 메시지를 주고받는 게 전부다.

> ⚠️ 약자가 같은 **리스코프 치환 원칙(Liskov Substitution Principle)** 과 자주 혼동된다 — 아래 [별도 절](#️-헷갈리는-이름--lsp는-두-개다) 참고.

## 자세히

### 왜 나왔나 — N×M 문제
LSP 이전에는 **에디터 N개 × 언어 M개 = N×M 개의 통합**을 각각 만들어야 했다. VS Code용 파이썬 지원, Vim용 파이썬 지원, Emacs용 파이썬 지원… 그리고 언어가 하나 늘면 전부 다시.

```
[LSP 없음]  에디터 3 × 언어 4 = 12개를 각각 구현
[LSP 있음]  에디터 3 + 언어 4 = 7개 (에디터는 클라이언트 1개, 언어는 서버 1개)
```

**N×M을 N+M으로 내리는 것** — 이것이 LSP의 전부이고, 뒤에 나온 DAP·BSP·MCP가 그대로 물려받은 발상이다. 2016년 Microsoft가 VS Code에서 쓰던 방식을 Red Hat·Codenvy와 함께 공개 사양으로 풀었다.

### 구조 — 별도 프로세스로 도는 "언어 전문가"
```
   에디터 (클라이언트)                        언어 서버 (별도 프로세스)
 ┌────────────────────┐                    ┌──────────────────────────┐
 │ 커서 위치·파일 변경  │ ─ JSON-RPC 2.0 ─→ │ 파싱 · 타입 추론 · 인덱스 │
 │ 결과를 UI로 그리기   │ ←─ stdio/socket ─ │ (rust-analyzer, gopls…)  │
 └────────────────────┘                    └──────────────────────────┘
```
- **별도 프로세스**라는 점이 핵심이다. 서버가 뻗어도 에디터는 살아 있고, **언어 서버를 그 언어 자체로 짤 수 있다**(rust-analyzer는 Rust, gopls는 Go로 작성). 컴파일러 팀이 만든 정확한 분석기를 에디터가 그대로 빌려 쓰는 구조.
- **메시지 프레이밍** — `Content-Length: 123\r\n\r\n{JSON}`. HTTP를 닮았지만 HTTP는 아니고, 보통 stdin/stdout([[표준 스트림]])이나 파이프·소켓으로 흐른다.
- **핸드셰이크에서 기능을 협상한다** — `initialize` 요청에서 클라이언트와 서버가 **capabilities**를 교환한다("나는 인레이 힌트 표시 가능", "나는 pull 방식 진단 지원"). 그래서 **같은 언어 서버가 에디터마다 다르게 동작한다.** LSP 관련 "왜 저기선 되는데 여기선 안 되지?"의 대부분이 여기서 나온다.

### 대표 요청들
| 요청 | 하는 일 | 에디터에서 보이는 모습 |
|---|---|---|
| `textDocument/completion` | 자동완성 후보 | 팝업 목록 |
| `textDocument/definition` | 정의 위치 | "정의로 이동"(F12) |
| `textDocument/hover` | 타입·문서 요약 | 마우스 올렸을 때 툴팁 |
| `textDocument/references` | 참조 전부 | "사용처 찾기" |
| `textDocument/rename` | 심볼 이름 변경 | 프로젝트 전역 리네임 |
| `textDocument/codeAction` | 빠른 수정·리팩터링 | 💡 전구 아이콘 |
| `textDocument/publishDiagnostics` | 서버가 **밀어주는** 오류·경고 | 빨간 물결 밑줄 |
| `textDocument/diagnostic` | 클라이언트가 **당겨오는** 진단 (3.17) | 같은 밑줄, 요청 시점만 다름 |
| `textDocument/semanticTokens` | 의미 기반 하이라이팅 (3.16) | 변수/함수/타입 색이 정확해짐 |
| `textDocument/inlayHint` | 추론된 타입·인자 이름 (3.17) | 코드 사이 회색 힌트 |

> **진단이 push → pull로 옮겨간 이유**: 서버가 아무 때나 밀어주면 에디터는 언제 화면을 갱신해야 할지 모르고 낭비도 크다. "지금 보이는 파일의 진단을 달라"고 **클라이언트가 요청**하는 편이 제어하기 쉽다.

### ⚠️ 위치 표현은 UTF-16이 기본 — 한글·이모지에서 어긋나는 이유
LSP의 `character` 오프셋은 **UTF-16 코드 단위**가 기본값이다(JavaScript/VS Code 태생의 유산). UTF-8로 세는 서버와 붙으면 **한글·이모지가 있는 줄에서 위치가 밀린다** — 밑줄이 엉뚱한 데 그려지는 고전적 버그.
- 3.17부터 `general.positionEncodings`(클라이언트) ↔ `capabilities.positionEncoding`(서버)로 **utf-8 / utf-16 / utf-32를 협상**할 수 있다. 한글 텍스트를 많이 다루면 반드시 확인할 항목.

### 버전 감각
- **3.17이 사실상의 기준선**이고, **3.18은 2026년 9월 현재도 "under development"** 상태다(문서는 3.18을 current로 표시하지만 개발 중이라고 명시).
- 3.18 신규 항목은 `@since 3.18.0`으로 표시 — `SnippetTextEdit`(워크스페이스 편집에 스니펫), **진단 메시지에 `MarkupContent`**(서식 있는 오류 메시지), 문서 필터의 상대 glob 패턴, `Command`의 `tooltip` 등.
- 실무에서 중요한 건 사양 번호가 아니라 **"내 클라이언트와 서버가 어떤 capability를 켰나"** 다.

### 생태계
- **서버** — rust-analyzer(Rust) · gopls(Go) · clangd(C/C++) · pyright(Python) · typescript-language-server(TS/JS) · jdtls(Java) · lua-language-server 등.
- **클라이언트** — VS Code, **Neovim(내장 클라이언트)**, Emacs(eglot·lsp-mode), Helix, Zed, Sublime. JetBrains는 자체 분석 엔진을 쓰지만 플러그인 개발자용 LSP API를 제공한다.
- ⚠️ **가볍지 않다.** rust-analyzer·pyright는 대형 프로젝트에서 RAM·CPU를 상당히 먹는다. 모노레포에서 에디터가 무거워지는 원인의 상당 부분이 언어 서버 인덱싱이다.

### 같은 발상의 형제 프로토콜들
| 프로토콜 | 무엇을 표준화하나 |
|---|---|
| **LSP** | 에디터 ↔ 언어 지식 |
| **DAP** (Debug Adapter Protocol) | 에디터 ↔ 디버거 (중단점·스텝 실행) |
| **BSP** (Build Server Protocol) | 언어 서버 ↔ 빌드 시스템 |
| **MCP** (Model Context Protocol) | AI 앱 ↔ 외부 도구·데이터 |

**MCP는 LSP에서 영감을 받았다고 명시**한다 — "에디터 N × 언어 M"이 "AI 앱 N × 도구 M"으로 바뀐 것뿐이고, 역시 JSON-RPC 2.0을 쓴다. LSP를 이해하면 [[MCP]]의 설계 의도가 그냥 읽힌다.

### AI 코딩 에이전트가 LSP를 쓰는 이유
**grep은 문자열을 알고, LSP는 심볼을 안다.** `handleClick`을 문자열로 찾으면 주석·문서·동명이인까지 다 걸리지만, `textDocument/references`는 **정확히 그 심볼의 참조**만 준다. 이름 변경, 타입 확인, 호출처 추적처럼 정확성이 필요한 작업에서 차이가 크다.
- Claude Code는 공식 LSP 플러그인(TypeScript·Python·Go·Rust·Java 등 12개 언어)으로 정의 이동·참조 검색·진단을 에이전트 도구로 노출한다. → [[AI 에이전트]]
- 반대로 말하면, **LSP가 붙지 않은 언어에서 에이전트는 [[정규표현식]]·문자열 검색 수준으로 내려간다.**

### 한계
- **파일·커서 위치 중심**이라 프로젝트 전역 분석(호출 그래프, 대규모 구조 변경)엔 약하다.
- **빌드 시스템을 모른다** → 코드 생성·매크로·모노레포에서 심볼을 놓친다. 이 틈을 메우려는 게 BSP.
- **인덱싱 비용을 매번 각자 로컬에서 지불한다.** 그래서 대규모 코드 검색 서비스(GitHub·Sourcegraph)는 LSP 대신 **LSIF·SCIP** 같은 사전 계산 인덱스 포맷을 쓴다.
- **서버의 진단 = 컴파일 결과가 아니다.** pyright와 mypy가 서로 다른 판정을 내리는 것처럼, 밑줄이 없다고 빌드가 통과하는 것은 아니다.

## ⚠️ 헷갈리는 이름 — LSP는 두 개다
| 표기 | 정체 |
|---|---|
| **LSP** = Language Server Protocol | **이 노트의 주제.** 에디터 ↔ 언어 서버 프로토콜 |
| **LSP** = Liskov Substitution Principle | **리스코프 치환 원칙.** [[객체지향 프로그래밍]] 설계 원칙 **SOLID의 'L'** |

**리스코프 치환 원칙**은 **Barbara Liskov가 1987년 OOPSLA 기조연설 "Data abstraction and hierarchy"** 에서 비공식 규칙으로 제시하고, **1994년 Jeannette Wing과 함께 행위 하위 타입(behavioral subtyping)** 으로 정식화한 것이다.

> *"타입 T의 객체에 대해 증명되는 성질 φ는, T의 하위 타입 S의 객체에도 성립해야 한다."*

쉽게는 **"부모 타입을 쓰던 코드에 자식 타입을 끼워 넣어도 깨지지 않아야 한다"**. 상속이 `is-a`처럼 보여도 **행동까지 대체 가능한지**는 별개라는 경고이고, 정사각형-직사각형(원-타원) 문제가 대표 예시다.

**구분법**: 에디터·자동완성·서버 이야기면 **프로토콜**, 상속·설계 원칙 이야기면 **치환 원칙**.

## 왜 중요한가
- **에디터를 갈아타도 언어 기능이 따라온다.** 도구 선택이 자유로워진 실질적 이유이고, Neovim·Helix·Zed 같은 후발 에디터가 짧은 시간에 실용적이 된 배경이다.
- **"표준 프로토콜로 N×M을 N+M으로"** 라는 패턴을 가장 깔끔하게 보여주는 사례다. DAP·BSP·[[MCP]]가 같은 틀을 반복하는 걸 보면, 이건 언어 도구만의 이야기가 아니라 **재사용 가능한 설계 교훈**이다.
- **AI 코딩 도구의 정확도 기반**이 되었다. 문자열 검색과 심볼 이해의 차이는 리팩터링·영향 범위 분석에서 결정적이다.
- 에디터가 왜 무거워지고 왜 IDE마다 오류 표시가 다른지(**capability 협상 · 인덱싱 비용**)를 설명해 준다.

## 관련 개념
- [[컴파일러와 인터프리터]] — 파싱·타입 검사를 "편집 중에 상시로" 돌리는 것이 언어 서버
- [[툴체인]] — 언어 서버는 툴체인의 편집기 쪽 얼굴
- [[JSON과 직렬화]] — JSON-RPC 2.0 메시지
- [[표준 스트림]] · [[프로세스와 스레드]] — stdio로 통신하는 별도 프로세스 모델
- [[MCP]] — LSP에서 영감을 받은 AI 도구용 프로토콜
- [[AI 에이전트]] — LSP를 도구로 소비하는 쪽
- [[정규표현식]] — 문자열 기반 검색의 한계(심볼 이해와의 대비)
- [[객체지향 프로그래밍]] — 이름이 같은 리스코프 치환 원칙(SOLID의 L)

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — LSP가 **JSON-RPC 2.0 기반**이고 메시지가 **`Content-Length` 헤더 + `\r\n\r\n` + UTF-8 JSON 본문**으로 프레이밍된다는 점, `initialize` 단계의 **capability 협상**, **위치 오프셋 기본이 UTF-16이며 `general.positionEncodings` ↔ `capabilities.positionEncoding`로 utf-8/utf-16/utf-32를 협상**한다는 점을 LSP 사양 문서(3.17·3.18)로 확인. **3.18은 2026년 9월 현재도 "under development"** 로 명시돼 있고 `@since 3.18.0` 항목에 **SnippetTextEdit·진단 메시지의 MarkupContent(`markupMessageSupport`)·문서 필터의 상대 glob 패턴·Command tooltip**이 포함된다는 점, **pull 방식 진단과 inlay hint가 3.17 계열 기능**이라는 점도 같은 문서로 확인. LSP가 **2016년 Microsoft(VS Code) + Red Hat·Codenvy**에서 공개 사양이 되었고 **N×M → N+M** 문제 해결이 핵심 동기라는 점, **MCP가 LSP에서 영감을 받아 같은 M×N→M+N 구조와 JSON-RPC 2.0을 채택**했다는 점을 MCP 사양·해설 자료로 확인. 대표 서버(rust-analyzer·gopls·clangd·pyright·typescript-language-server·jdtls)와 **pyright·rust-analyzer의 높은 메모리 사용**, **Claude Code가 12개 언어 공식 LSP 플러그인으로 정의·참조·진단을 도구로 노출**한다는 점도 확인. 이름이 같은 **리스코프 치환 원칙**은 **Barbara Liskov의 1987년 OOPSLA 기조연설 "Data abstraction and hierarchy"** 에서 비공식 규칙으로 제시되고 **1994년 Jeannette Wing과의 공동 작업에서 행위 하위 타입으로 정식화**되었으며 **SOLID의 'L'**, 정사각형-직사각형/원-타원 문제가 대표 예라는 점을 Wikipedia·관련 해설로 확인.
