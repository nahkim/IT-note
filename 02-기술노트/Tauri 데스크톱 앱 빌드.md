---
type: 기술노트
domain: 프론트엔드
tags: [IT, 노트, Tauri, Rust, 빌드, 배포, CI-CD]
출처: Tauri 공식 문서 v2 (v2.tauri.app — Distribute / CLI / Updater)
종류: 정리
읽은날: 2026-08-12
별점: 
aliases: [Tauri 빌드, Tauri 데스크톱 앱 빌드, 타우리 빌드, tauri build]
---

# 📝 Tauri 데스크톱 앱 빌드 (흐름 · 로직 · 방법)

## 한 줄 요약
> **웹 빌드 → Rust 릴리즈 컴파일 → OS별 번들러**, 이 3단계가 `tauri build` 한 줄 안에서 순서대로 돌아가고, **번들 단계는 OS를 못 넘어가기 때문에** 3개 OS 설치본이 필요하면 CI 매트릭스로 각 OS에서 각각 빌드한다.

[[Tauri]]가 무엇인지(OS 웹뷰 + Rust 백엔드)는 개념 노트에서, 이 노트는 **"그래서 어떻게 실행 파일이 나오는가"** 만 다룬다.

## 핵심 내용

### 1. 먼저 프로젝트 구조 — 빌드가 무엇을 읽는가
```
my-app/
├─ package.json          # 프론트엔드(웹) 의존성 · dev/build 스크립트
├─ src/                  # 웹 UI 소스 (React·Vue·Svelte·순수 JS 아무거나)
├─ dist/                 # 웹 빌드 결과물 ← Tauri가 앱에 넣는 것
└─ src-tauri/            # ★ 여기가 Rust(네이티브) 쪽
   ├─ tauri.conf.json    # 앱 이름·버전·창 설정·번들 타깃·권한 — 빌드의 지휘서
   ├─ Cargo.toml         # Rust 의존성 (tauri, tauri-build, 플러그인 크레이트)
   ├─ capabilities/      # v2 권한(Permissions) 선언
   ├─ icons/             # 아이콘 (플랫폼별 크기로 미리 생성해 둠)
   └─ src/main.rs        # Rust 엔트리 — command 등록, 앱 실행
```
- **`tauri.conf.json`이 사실상 빌드 스펙**이다. 핵심 4개 키:
  - `build.frontendDist` — 앱에 포함할 **웹 빌드 결과 폴더**(예: `../dist`)
  - `build.devUrl` — 개발 중 웹뷰가 붙을 **dev 서버 주소**(예: `http://localhost:5173`)
  - `build.beforeDevCommand` / `build.beforeBuildCommand` — Tauri가 **자기 일 하기 전에 대신 실행해 주는 프론트엔드 명령**(`npm run dev` / `npm run build`)
  - `bundle.targets` — 어떤 설치본을 만들지 (`"all"` 또는 `["dmg","nsis"]` 등)

### 2. 개발 모드 흐름 (`tauri dev`) — 왜 빌드가 아닌가
```
tauri dev
 ├─ beforeDevCommand 실행  → Vite 등 dev 서버 뜸 (localhost:5173)
 ├─ 서버가 뜰 때까지 대기   (--no-dev-server-wait 로 생략 가능)
 ├─ cargo build (debug)    → Rust 바이너리 컴파일 (첫 빌드가 가장 느림)
 └─ 앱 창 실행 → 웹뷰가 devUrl 을 로드
```
- **웹 쪽 수정** → dev 서버의 HMR이 처리 → 즉시 반영([[핫리로드]]).
- **Rust 쪽 수정** → 파일 감시가 감지 → **Rust를 다시 컴파일하고 앱을 재시작**한다(`--no-watch`로 끌 수 있음). 그래서 "웹 고치면 빠르고, Rust 고치면 느리다"가 체감된다.
- 즉 dev에서는 **웹 자원이 앱에 들어있지 않다** — 웹뷰가 개발 서버를 원격으로 보고 있을 뿐. 배포본과 구조가 다르다는 점이 dev/build 차이의 핵심.

### 3. 릴리즈 빌드 흐름 (`tauri build`) — 실제 파이프라인
```
tauri build
 │
 ├─(1) beforeBuildCommand      : npm run build  → dist/ 에 정적 웹 산출물 생성
 │                                (Tauri는 이 폴더를 frontendDist 로 읽음)
 ├─(2) cargo build --release   : Rust 컴파일 + 웹 산출물을 바이너리에 임베드
 │                                → 최적화된 단일 실행 파일 (app.exe / app)
 ├─(3) beforeBundleCommand     : (선택) 번들 직전 후처리 훅
 └─(4) 번들러(bundler)          : OS별 설치본 포장 + 아이콘·메타데이터·서명
                                  → .msi / -setup.exe / .dmg / .app / .deb / .rpm / .AppImage
```
- 산출물 위치: `src-tauri/target/release/` (실행 파일), `src-tauri/target/release/bundle/<타깃>/` (설치본).
- **(2)와 (4)는 분리 가능**: `--no-bundle`로 컴파일만 하고, 나중에 번들만 따로 돌릴 수 있다. 서명·스토어용 설정을 다르게 줄 때 쓴다.
- `--debug`를 주면 릴리즈 형태로 번들하되 디버그 심볼·devtools를 남긴다 → **"배포본에서만 재현되는 버그"** 잡을 때 유용.
- 릴리즈 최적화(LTO, strip, opt-level) 설정은 `src-tauri/Cargo.toml`의 `[profile.release]`에서 손대면 용량이 눈에 띄게 줄어든다.

### 4. 번들 타깃 — 무엇이 나오나
| OS | 주요 타깃 | 비고 |
|---|---|---|
| Windows | `msi` (WiX v3), `nsis` (`-setup.exe`) | MSI는 **Windows에서만** 생성 가능(WiX가 Windows 전용). NSIS는 상대적으로 유연·크로스 빌드 가능 |
| macOS | `app` (.app 번들), `dmg` | `.app`은 `Contents/{MacOS,Resources,Frameworks}` + `Info.plist` 구조. `Entitlements.plist`로 샌드박스 권한 지정 |
| Linux | `deb`, `rpm`, `appimage` | AppImage는 의존성 동봉형(어디서나 실행), deb/rpm은 배포판 패키지. AUR·Snap·Flatpak도 지원 |
| 모바일(v2) | `tauri android build`, `tauri ios build` | Play 스토어 / App Store 경로 |

- Windows는 **WebView2 설치 방식**을 고를 수 있다(`bundle.windows.webviewInstallMode`): 기본 `downloadBootstrapper`(설치 시 다운로드, +0MB) / `embedBootstrapper`(~1.8MB) / `offlineInstaller`(~127MB) / `fixedVersion`(특정 버전 고정, ~180MB). **오프라인 사내 배포면 offlineInstaller·fixedVersion**을 검토.
- macOS 최소 지원 버전은 `bundle.macOS.minimumSystemVersion`(기본 10.13).

### 5. 크로스 컴파일이 안 되는 이유 → CI 매트릭스가 정답
- **Rust 컴파일 자체는 타깃 트리플을 바꿔 크로스 빌드가 가능**하지만, **번들 단계는 OS 네이티브 도구에 묶여 있다** — WiX(MSI)는 Windows 전용, `.dmg`/공증은 macOS 도구 필요, `.deb`/`.AppImage`는 Linux 필요.
- 그래서 공식 입장은 "**전 플랫폼 산출물이 필요하면 VM 또는 CI를 써라**". (Linux/macOS에서 NSIS를 `cargo-xwin`+LLD로 만드는 우회로는 있지만 "직접 빌드보다 까다롭고 테스트도 덜 됐다"고 문서가 명시)
- 실무 정석: **GitHub Actions 매트릭스로 OS마다 러너를 띄우고 각자 자기 OS 산출물을 만든다** → [[CI-CD|CI/CD]]가 선택이 아니라 필수인 지점.
  - 러너 예: `windows-latest`(x64), `macos-latest`(aarch64 + x86_64 각각, 또는 `universal-apple-darwin` 하나), `ubuntu-22.04`(x64/arm64)
  - `tauri-apps/tauri-action@v1`이 "빌드 → 산출물 수집 → GitHub Release 생성"까지 한다. `GITHUB_TOKEN`에 **write 권한** 필요.
  - Linux 러너는 WebKitGTK 등 **시스템 의존성 apt 설치 스텝이 따로 필요**하다(가장 흔한 CI 실패 원인).
  - 오래된 Ubuntu 러너를 쓰는 이유: **glibc는 하위 호환만 되므로 낮은 버전에서 빌드해야 넓게 돌아간다.**

### 6. 서명(Signing) — "빌드는 됐는데 안 열리는" 구간
- **macOS**: Developer ID 인증서로 코드 서명 + Apple **공증(notarization)** 을 받아야 Gatekeeper가 통과시킨다. 인증서 없이 배포하면 "손상되었습니다"가 뜨므로 CI에서는 최소한 **ad-hoc 서명**이라도 하라고 문서가 권한다. → [[애드혹 서명 vs 정식 서명]]
- **Windows**: 코드 서명 인증서가 없으면 SmartScreen 경고. (EV/OV 인증서, 또는 Azure Trusted Signing 류를 사용)
- **Linux**: 강제 서명 개념 없음 — 대신 AppImage 서명·저장소 GPG 서명이 관례.
- 결론: 서명은 **번들 단계에 끼어드는 별개 관심사**이고, 키·인증서는 전부 CI 시크릿([[환경 변수]])으로 주입한다.

### 7. 자동 업데이트(Updater) 로직 — 서명 키가 왜 또 나오나
1. `tauri signer generate -w ~/.tauri/myapp.key` → **개인키 + 공개키** 생성
2. **공개키**는 `tauri.conf.json`의 `plugins.updater.pubkey`에 박아 배포(공개해도 됨)
3. **개인키**는 빌드 시 `TAURI_SIGNING_PRIVATE_KEY` 환경 변수로 주입 → 번들러가 산출물마다 `.sig` 파일을 만든다 (**`.env` 파일로는 안 먹는다**)
4. 앱은 `endpoints`(정적 `latest.json` 또는 동적 서버)를 조회 → 새 버전이면 내려받아 **`.sig`를 공개키로 검증**한 뒤 설치
   - 엔드포인트 URL에는 `{{current_version}}` · `{{target}}` · `{{arch}}` 치환 변수를 쓸 수 있고, 동적 서버는 업데이트 없으면 `204`를 준다
5. 업데이트 대상 산출물: **Windows = MSI/NSIS, macOS = `.tar.gz`, Linux = AppImage**
> ⚠️ **개인키를 잃으면 그 앱에 더는 업데이트를 못 보낸다.** 키 백업이 릴리즈 인프라의 일부다.

### 8. 버전·의존성 규칙 (사고 자주 나는 곳)
- 버전 문자열은 `tauri.conf.json`의 `version`이 기준(또는 `package.json`에서 끌어옴). 플랫폼마다 허용 형식 제약이 있어 **`1.2.3` 형태의 semver를 벗어나면 번들이 실패**할 수 있다.
- **`@tauri-apps/api`(npm)와 `tauri`(crate)의 마이너 버전을 맞춰야 한다.** JS API가 Rust 쪽 구현에 기대기 때문. **플러그인은 npm 패키지와 crate 버전을 정확히 일치**시키는 게 안전하다.
- 즉 이 스택은 **npm 트리 + Cargo 트리 두 개를 동시에 관리**한다([[툴체인]]) — 어느 한쪽만 올리면 런타임에서 깨진다.

## 코드 / 예시

**최소 명령어 세트**
```bash
# 개발
npm run tauri dev

# 릴리즈 빌드 (현재 OS 기준, 전체 번들)
npm run tauri build

# 번들 타깃 지정
npm run tauri build -- --bundles dmg
npm run tauri build -- --bundles nsis,msi

# 컴파일만 (번들 생략) → 나중에 따로 포장
npm run tauri build -- --no-bundle

# 배포본 디버깅용 (심볼 유지)
npm run tauri build -- --debug

# 타깃 트리플 지정 (예: macOS 유니버설 바이너리)
npm run tauri build -- --target universal-apple-darwin

# CI에서 (프롬프트 없이)
npm run tauri build -- --ci
```

**tauri.conf.json 핵심 골격**
```json
{
  "productName": "my-app",
  "version": "1.2.3",
  "identifier": "com.example.myapp",
  "build": {
    "frontendDist": "../dist",
    "devUrl": "http://localhost:5173",
    "beforeDevCommand": "npm run dev",
    "beforeBuildCommand": "npm run build"
  },
  "bundle": {
    "active": true,
    "targets": ["dmg", "nsis", "deb", "appimage"],
    "icon": ["icons/32x32.png", "icons/icon.icns", "icons/icon.ico"],
    "windows": { "webviewInstallMode": { "type": "downloadBootstrapper" } },
    "macOS": { "minimumSystemVersion": "10.15" }
  },
  "plugins": {
    "updater": {
      "pubkey": "…공개키…",
      "endpoints": ["https://releases.example.com/{{target}}/{{current_version}}"]
    }
  }
}
```

**GitHub Actions 매트릭스(뼈대)**
```yaml
jobs:
  build:
    strategy:
      matrix:
        include:
          - { os: macos-latest,  args: "--target aarch64-apple-darwin" }
          - { os: macos-latest,  args: "--target x86_64-apple-darwin"  }
          - { os: ubuntu-22.04,  args: "" }
          - { os: windows-latest, args: "" }
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - if: matrix.os == 'ubuntu-22.04'
        run: sudo apt-get update && sudo apt-get install -y libwebkit2gtk-4.1-dev …
      - uses: actions/setup-node@v4
      - uses: dtolnay/rust-toolchain@stable
      - run: npm ci
      - uses: tauri-apps/tauri-action@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          TAURI_SIGNING_PRIVATE_KEY: ${{ secrets.TAURI_SIGNING_PRIVATE_KEY }}
        with:
          args: ${{ matrix.args }}
```

**전체 흐름 한 장**
```
 [웹 소스]        [Rust 소스]
    │                 │
 npm run build     cargo build --release
    │                 │
    └──── dist/ ──▶ 바이너리에 임베드 ──▶ target/release/app(.exe)
                              │
                              ▼  번들러 (OS 네이티브 도구 필요 ⚠️ 여기서 OS를 못 넘음)
              ┌───────────────┼───────────────┐
           Windows          macOS           Linux
        .msi / -setup.exe  .app / .dmg   .deb/.rpm/.AppImage
              │               │               │
              └──── 코드 서명 · (macOS 공증) ──┘
                              │
                    .sig 첨부 → latest.json 게시 → 앱이 자동 업데이트
```

## 기억할 문장 / 핵심 포인트
> **"`tauri build`는 웹 빌드 → Rust 릴리즈 컴파일 → OS 번들, 세 단계의 오케스트레이터다."** 각 단계가 왜 실패했는지 구분하는 것이 디버깅의 시작.
> **번들 단계가 OS에 묶여 있어서 크로스 컴파일이 막힌다** → 3-OS 배포는 CI 매트릭스로 푼다.
> **dev와 build는 구조가 다르다** — dev는 웹뷰가 dev 서버를 원격 로드, build는 웹 자원을 바이너리에 임베드. "dev에선 되는데 빌드하면 안 되는" 문제는 대개 여기(경로·CSP·권한)서 온다.
> **업데이터 개인키를 잃으면 업데이트 경로가 영구히 끊긴다.**

## 등장하는 개념
- [[Tauri]] — 구조(OS 웹뷰 + Rust 백엔드) 자체. 이 노트는 그 빌드/배포 편
- [[Wails]] · [[Tauri vs Wails]] — 같은 구조의 Go 버전과 비교
- [[CI-CD|CI/CD]] — 크로스 컴파일 제약을 매트릭스 빌드로 우회하는 곳
- [[릴리즈]] · [[Git 태그]] — 버전 태그 → CI 트리거 → 산출물 게시의 연결
- [[툴체인]] — npm 트리 + Cargo 트리를 함께 관리해야 하는 이유
- [[환경 변수]] — 서명 인증서·`TAURI_SIGNING_PRIVATE_KEY`를 CI 시크릿으로 주입
- [[암호화와 해싱]] — 업데이터의 공개키/개인키 서명 검증 원리
- [[핫리로드]] — `tauri dev`에서 웹은 HMR, Rust는 재컴파일+재시작
- [[크로스플랫폼]] · [[네이티브 앱]] · [[클라이언트 앱]] — 산출물이 놓이는 맥락
- [[CSP]] — 배포본에서 웹 자원 로드 정책이 dev와 달라지는 지점

## 내 생각 / 적용할 점
-

---
> ✅ **웹 교차검증 완료** — `tauri build`의 단계(beforeBuildCommand → cargo release → beforeBundleCommand → 번들)와 `--bundles/--target/--debug/--no-bundle/--ci` 옵션, 플랫폼별 번들 타깃(AppImage·deb·rpm·dmg·app·MSI(WiX, Windows 전용)·NSIS), WebView2 설치 모드 5종과 용량, macOS `.app` 구조·`minimumSystemVersion` 기본 10.13, 크로스 컴파일 미지원 → VM/CI 권고, `tauri-action` 매트릭스와 `GITHUB_TOKEN` write 권한, 업데이터의 `tauri signer generate`·`pubkey`·`TAURI_SIGNING_PRIVATE_KEY`(.env 불가)·`.sig`·플랫폼별 업데이트 산출물, `@tauri-apps/api`와 `tauri` crate 마이너 버전 일치 규칙을 공식 문서(v2.tauri.app: distribute / reference/cli / plugin/updater / develop)로 확인.
