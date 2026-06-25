---
type: 개념
tags: [IT, 프론트엔드, 데스크톱앱, Rust]
created: 2026-06-25
aliases: [Tauri, 타우리]
---

# Tauri (타우리)

## 한 줄 정의
웹 기술(HTML/CSS/JS)로 UI를 만들고 **Rust 백엔드**로 묶어, 가볍고 빠른 **데스크톱·모바일 앱**을 만드는 크로스플랫폼 프레임워크. Electron의 대안.

## 자세히

### 핵심 구조
- **OS에 내장된 웹뷰(WebView)를 그대로 사용** — Chromium을 통째로 번들하지 않는다.
  - Windows: WebView2 (Chromium 기반) · macOS/iOS: WKWebView (WebKit) · Linux: WebKitGTK · Android: System WebView.
- **백엔드는 Rust** — GC 없이 메모리 안전성을 보장하고, 무거운 런타임이 없어 가볍다.
- 프론트엔드(웹)와 백엔드(Rust)는 **IPC**로 통신: 프론트가 `invoke('명령')`을 호출하면 Rust에 정의한 **command** 함수가 실행된다.
- 어떤 웹 프레임워크든(React, Vue, Svelte, 순수 JS…) 빌드 결과물만 있으면 붙일 수 있다.

### Electron과의 차이 (가장 흔한 비교)
- **용량**: Electron은 앱마다 Chromium 전체를 포함해 설치본이 보통 수십~수백 MB. Tauri는 OS 웹뷰를 재사용해 **수 MB~십수 MB** 수준으로 크게 작다.
- **메모리·성능**: Chromium 프로세스를 따로 안 띄우니 메모리·시작 시간이 유리한 편.
- **언어**: Electron 백엔드는 Node.js(JS), Tauri는 Rust.
- **트레이드오프**: OS 웹뷰를 쓰기 때문에 **플랫폼마다 렌더링 엔진이 달라(WebKit vs Chromium)** 동작·CSS가 미묘하게 갈릴 수 있다. Electron은 어디서나 같은 Chromium이라 일관성은 높다.

### Tauri 2.0 (현재 안정 버전, 2024년 말 정식 출시)
- **모바일 지원 추가** — Windows/macOS/Linux + **iOS/Android**까지 하나의 코드베이스로. (Electron은 데스크톱 전용)
- **플러그인 시스템** — Rust 크레이트 기반으로 기능 확장(파일시스템, 알림, 업데이터 등).
- **권한(Permissions) 시스템** — 앱이 어떤 시스템 API를 쓸지 명시적으로 선언 → 보안 강화.

## 왜 중요한가
- "웹 기술로 데스크톱 앱"이 필요할 때 **Electron의 무거움(용량·메모리)** 을 피하는 대표적 선택지.
- v2부터는 데스크톱+모바일을 **한 코드베이스**로 노릴 수 있어 적용 범위가 넓어졌다.
- 단, 플랫폼별 웹뷰 차이와 Rust 학습 곡선은 도입 전에 고려할 점.

## 관련 개념
- [[서비스 워커]] · PWA — 설치 없이 "앱 같은 웹"을 노리는 다른 접근(웹뷰 대신 브라우저)
- [[가비지 컬렉션과 메모리]] — Tauri가 Rust로 GC 없이 메모리 안전성을 얻는 이유와 연결
- [[컨테이너와 Docker]] — "런타임을 통째로 싸느냐"의 대비 (Electron=Chromium 동봉 vs Tauri=OS 웹뷰 재사용)

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — OS 내장 웹뷰(WebView2/WKWebView/WebKitGTK) + Rust 백엔드 구조, Electron 대비 용량·메모리 이점, Tauri 2.0의 iOS/Android 모바일 지원·플러그인·권한 시스템을 공식 문서(v2.tauri.app)·복수 비교 자료로 확인.
