---
type: 기술노트
tags: [IT, 노트, 오디오, Windows, macOS]
출처: (웹 교차검증 정리 — Microsoft Core Audio · Apple Core Audio 문서)
종류: 정리
읽은날: 2026-07-07
별점: 
aliases: [오디오 캡처 API, WASAPI, Windows Audio Session API, Core Audio, CoreAudio, AUHAL, 오디오 API]
---

# 📝 오디오 캡처 API — WASAPI(Windows) · Core Audio(macOS)

## 한 줄 요약
앱이 마이크·스피커에서 [[PCM]]을 **직접 캡처/재생**하는 **플랫폼별 저수준 오디오 API**. Windows는 **WASAPI**, macOS는 **Core Audio**. 둘 다 [[오디오 녹음 파이프라인|녹음 파이프라인]]의 "**콜백이 PCM을 버퍼에 쌓는**" 앞단을 담당하며, 개념이 서로 대응된다.

## 핵심 내용

### 1. WASAPI (Windows)
- Windows Core Audio(Vista+), 옛 MME(waveIn)·DirectSound를 대체. 흐름: MMDevice → `IAudioClient` → **`IAudioCaptureClient`(녹음)/`IAudioRenderClient`(재생)**.
- **공유 모드(Shared)** — 오디오 엔진(믹서) 경유, 여러 앱 공존(지연↑, Win10 `AudioClient3`로 저지연 가능).
- **독점 모드(Exclusive)** — 엔드포인트 독점·믹서 우회 → 최저 지연·비트퍼펙트(그동안 타 앱 무음).
- **이벤트 드리븐** 캡처, **루프백 캡처**(시스템 출력 녹음, **공유 모드 전용**).

### 2. Core Audio (macOS / iOS)
- Apple의 저수준 오디오 프레임워크.
- **AUHAL(AudioUnit HAL)** — 특정 장치 입출력 유닛. **hog mode**로 장치를 **독점**(믹서 우회) → WASAPI **독점 모드에 대응**.
- **render callback** — 출력/입력이 데이터를 필요로 할 때 호출되는 **실시간 콜백**(= WASAPI 이벤트 드리븐; **블로킹 금지** 원칙 동일).
- 상위 API: **AVAudioEngine**(노드 기반, 현대 Swift), **Audio Queue Services**(버퍼 콜백, 쉬움·상대적 고지연).
- **시스템 소리 캡처**(= 루프백): **Core Audio Process Taps**(macOS 14.2+, 오디오 전용·깔끔) 또는 **ScreenCaptureKit**(13+). ⚠️ AVAudioEngine은 CATap 집계장치로 재타깃이 안 됨 → 오디오만 필요하면 **Core Audio Tap 직접** 사용.

### 3. 개념 대응표
| 개념 | Windows (WASAPI) | macOS (Core Audio) |
|---|---|---|
| 저수준 장치 I/O | `IAudioClient` | **AUHAL**(AudioUnit) |
| 장치 독점 | **Exclusive mode** | **Hog mode** |
| 공유(믹서 경유) | **Shared mode** | 기본 HAL(믹서) |
| 실시간 콜백 | 이벤트 드리븐 | **render callback** |
| 시스템 소리 녹음 | **루프백**(공유 전용) | **Core Audio Tap** / ScreenCaptureKit |
| 상위 프레임워크 | WinRT AudioGraph 등 | **AVAudioEngine** / Audio Queue |

### 4. 크로스플랫폼
- Linux는 **ALSA / PulseAudio / PipeWire / JACK**. WASAPI·Core Audio는 각각 Windows·macOS 담당.
- 한 코드로 다루려면 **PortAudio · miniaudio · RtAudio** 같은 추상화가 내부에서 WASAPI/CoreAudio/ALSA를 골라 준다 → 파이프라인은 이걸 쓰면 플랫폼 차이를 덜 신경 쓴다.

### 5. 공통 원칙 (플랫폼 불문)
- 캡처/렌더 **콜백은 실시간 스레드** → **복사만 하고 즉시 반환**, 디스크 쓰기·인코딩은 **백그라운드**로. (→ [[오디오 녹음 파이프라인]]의 제1원칙)

## 코드 / 예시 — 흐름은 동일
```
[마이크 / 시스템 출력(루프백·Tap)]
   │  WASAPI 캡처  ↔  Core Audio render callback
   ▼
 PCM 패킷  ──(콜백에서 '복사만')──▶ [링 버퍼]
                                     │ 백그라운드 스레드 flush
                                     ▼
                              WAV / STT 전처리(UVR5)
```

## 기억할 문장 / 핵심 포인트
> "Windows = **WASAPI**, macOS = **Core Audio**. 독점 = **Exclusive ↔ Hog**, 시스템 녹음 = **루프백 ↔ Core Audio Tap** 으로 서로 대응."
> 크로스플랫폼이면 직접 API 대신 **PortAudio/miniaudio** 한 겹 위에서.
> 어느 쪽이든 **콜백은 논블로킹**(복사만) — 나머지는 백그라운드.

## 등장하는 개념
- [[오디오 녹음 파이프라인]] — 이 API들이 그 '앞단(콜백)'
- [[PCM]] · [[WAV]] · [[버퍼]] · [[콜백]] · [[flush]] — 캡처 데이터·처리
- [[레이턴시]] — 공유/독점·shared/hog의 핵심 차이
- [[STT 음성 인식]] · [[UVR5]] — 캡처 이후 파이프라인
- [[폴링]] — 타이머 드리븐 vs 이벤트/콜백 드리븐 대비

## 내 생각 / 적용할 점
-

---
> ✅ **웹 교차검증 완료** — WASAPI(Windows Core Audio: 공유 vs 독점, 이벤트 드리븐, 루프백=공유 전용, Win10 AudioClient3)와 macOS Core Audio(AUHAL·hog mode 독점, render callback, AVAudioEngine/Audio Queue, 시스템 캡처=Core Audio Process Taps(14.2+)/ScreenCaptureKit)의 개념 대응, Linux ALSA/JACK·크로스플랫폼 PortAudio/miniaudio를 Microsoft Learn·Apple Developer 문서로 확인.
