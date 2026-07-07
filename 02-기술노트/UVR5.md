---
type: 기술노트
tags: [IT, 노트, 오디오, AI, STT]
출처: (웹 교차검증 정리 — UVR GUI 공식 GitHub · audio-separator)
종류: 정리
읽은날: 2026-07-03
별점: 
aliases: [UVR5, Ultimate Vocal Remover, UVR, 보컬 리무버]
---

# 📝 UVR5 (Ultimate Vocal Remover 5) — 오디오 소스 분리

## 한 줄 요약
UVR5는 딥러닝으로 오디오에서 **보컬·반주 등 소스(stem)를 분리**하는 오픈소스 GUI 도구(Win/Mac/Linux). 음악 제작·카라오케뿐 아니라 **STT 전처리(음악·잡음 제거로 말소리만 남기기)**에도 쓰인다.

## 핵심 내용

### 1. 무엇을 하나 — 소스 분리(source separation)
- **보컬 ↔ 반주(Instrumental)** 분리가 기본.
- **4-stem 분리**(보컬·드럼·베이스·기타) — 주로 Demucs 모델.
- **디리버브(de-reverb)·디에코(de-echo)·디노이즈(de-noise)**, 리드/백킹 보컬 분리 등 특수 모델.
- (구분) 이건 "무엇이 섞여 있나"를 **소리 성분으로 나누는 것** — "누가 언제 말했나"인 [[화자 분리]](diarization)와는 다른 문제.

### 2. 모델 — 아키텍처(계열)와 기능별 선택
**아키텍처(계열)**
- **VR Architecture**(`.pth`, tsurumeso) — 스펙트로그램 기반. **디리버브·디노이즈·카라오케** 특수 처리 모델이 여기 많다.
- **MDX-Net**(`.onnx`, Kuielab·Woosung Choi) — 보컬/반주 **정밀 분리의 주력**.
- **MDX23C / MDXC** — MDX 후속, 고품질 보컬·반주.
- **Demucs**(Meta, Adéfossez) — **파형 기반 다중 stem**(v4 `htdemucs`), 6-stem도 지원.
- **RoFormer**(BS-Roformer·Mel-Band Roformer) — **현재 최상위 품질**의 신세대(원클릭 보컬/반주). 최신 빌드·`audio-separator`에서 사용.
- **앙상블(Ensemble)** — 여러 모델 결과를 결합(품질↑·속도↓).

**기능별 대표 모델 (뭘 고를까)**
| 목적 | 대표 모델 | 비고 |
|---|---|---|
| **보컬 추출**(아카펠라) | Kim Vocal 2 · MDX-NET **Voc_FT** · **BS/Mel-Band RoFormer** | RoFormer가 현재 최고 품질 |
| **반주 추출**(Instrumental) | UVR-MDX-NET **Inst HQ 3~5** · **MDX23C-InstVoc HQ** | 보컬 잔재 최소화 |
| **4-stem**(보컬·드럼·베이스·기타) | **htdemucs** · **htdemucs_ft**(정밀·느림) | Demucs v4 |
| **6-stem**(+피아노·기타) | **htdemucs_6s** | 악기별 분리 |
| **카라오케**(리드↔백킹 보컬) | **6_HP-Karaoke-UVR** · MDX-NET **Karaoke 2** | 리드만 제거, 코러스 유지 |
| **디리버브·디에코**(잔향/울림 제거) | **UVR-DeEcho-DeReverb** · De-Echo Normal/Aggressive · MDX **Reverb HQ** | STT 전처리에 유용 |
| **디노이즈**(배경 잡음) | **UVR-DeNoise** · DeNoise Lite | |
| **군중 소리 제거** | UVR-MDX-NET **Crowd HQ** | 라이브/관중 |

### 3. 어떻게 쓰나
- 입력 오디오(MP3/FLAC/OGG/[[WAV]] 등, FFmpeg 지원) → 모델 선택 → 분리된 stem 출력.
- **GPU 가속** — NVIDIA는 **CUDA**([[CUDA]]·[[nvidia-smi]]로 확인), Mac M시리즈는 **MPS**(Demucs v4·MDX-Net). CPU도 되지만 느림.
- 품질 vs 속도 트레이드오프: 큰 모델·앙상블·높은 오버랩은 좋지만 느리고 VRAM을 많이 씀.

### 4. STT 파이프라인에서의 위치
- 녹음 오디오에 **배경 음악·잡음**이 섞이면 STT 인식률이 떨어진다 → UVR5로 **보컬(말소리)만 추출**해 전처리하면 정확도↑.
- 흐름: [[오디오 녹음 파이프라인|녹음(PCM→WAV)]] → **UVR5 소스 분리(보컬 추출)** → [[화자 분리]] → [[STT 음성 인식]].

### 5. 헤드리스/자동화
- GUI 대신 **`audio-separator`(PyPI)** 라이브러리로 같은 UVR 모델을 **CLI·파이썬 파이프라인**에서 사용 → 서버/배치 처리에 적합.

## 코드 / 예시
```bash
# GUI 대신 라이브러리로 자동화 (UVR 모델 그대로 사용)
pip install "audio-separator[gpu]"
audio-separator input.wav --model_filename UVR-MDX-NET-Inst_HQ_3.onnx
# → input_(Vocals).wav, input_(Instrumental).wav 생성
```
```
[녹음: PCM→WAV] ─▶ [UVR5 소스 분리] ─▶ 보컬.wav ─▶ [화자 분리] ─▶ [STT]
                         │
                         └▶ 반주.wav (버림/따로 사용)
```

## 기억할 문장 / 핵심 포인트
> "UVR5는 **소리를 성분으로 나눈다**(보컬/반주). '누가 말했나'를 나누는 [[화자 분리]]와 목적이 다르다."
> STT 앞단에서 **음악·잡음을 걷어내는 전처리**로 쓰면 인식률이 오른다 — 단, 분리 아티팩트가 생길 수 있어 모델·품질 설정이 중요.
> 자동화가 필요하면 GUI(UVR5) 대신 **`audio-separator`** 라이브러리.

## 등장하는 개념
- [[STT 음성 인식]] — UVR5 전처리의 최종 목적지
- [[화자 분리]] — "누가 언제"(diarization), UVR5의 소스 분리와 구분
- [[오디오 녹음 파이프라인]] · [[PCM]] · [[WAV]] — 입력 오디오의 형태
- [[CUDA]] · [[nvidia-smi]] — GPU 가속·자원 확인
- [[온디바이스]] — 로컬에서 도는 추론(클라우드 안 거침)

## 내 생각 / 적용할 점
-

---
> ✅ **웹 교차검증 완료** — UVR5(오픈소스 GUI v5.6·Win/Mac/Linux, Anjok07/aufr33), 아키텍처 VR(tsurumeso)/MDX-Net(Kuielab·Woosung Choi)/MDX23C/Demucs(Meta)/신세대 RoFormer(BS·Mel-Band)+앙상블, 기능별 대표 모델(보컬 Kim Vocal 2·Voc_FT·RoFormer / 반주 Inst HQ·MDX23C-InstVoc / 4·6-stem htdemucs(_ft/_6s) / 카라오케 6_HP-Karaoke / 디리버브 DeEcho-DeReverb·Reverb HQ / 디노이즈 DeNoise / 군중 Crowd HQ), GPU(CUDA·Mac MPS), 헤드리스 `audio-separator`(PyPI)를 UVR 공식 GitHub·audio-separator·복수 UVR 모델 가이드로 확인.
