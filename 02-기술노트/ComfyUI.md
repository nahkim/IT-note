---
type: 기술노트
tags: [IT, 노트, AI, 생성형AI, 이미지]
출처: (웹 교차검증 정리 — ComfyUI/디퓨전 UI 비교 자료)
종류: 정리
읽은날: 2026-07-07
별점: 
aliases: [ComfyUI, 컴피유아이, 컨피유아이]
---

# 📝 ComfyUI — 노드 기반 생성형 AI 워크플로 GUI

## 한 줄 요약
ComfyUI는 **노드(그래프)를 연결해 이미지 생성 파이프라인을 조립**하는 오픈소스 GUI. Stable Diffusion·Flux 같은 **디퓨전 모델**을 "체크포인트 → 프롬프트 인코딩 → 샘플러 → VAE 디코드" 노드로 이어 돌린다. 세밀한 제어·재현성·확장성이 강점.

## 핵심 내용

### 1. 무엇이고, 왜 '노드'인가
- 각 단계가 노드: **Load Checkpoint → CLIP Text Encode(긍정/부정 프롬프트) → KSampler → VAE Decode → Save Image**. 선으로 연결한 그래프가 곧 워크플로.
- **바뀐 노드만 재실행**(증분 실행 → [[증분]])해서 폼 기반 A1111 대비 **약 33~41% 빠르고 VRAM ~14%↓**. 복잡한 워크플로일수록 격차가 크다.
- 워크플로가 **출력 PNG 메타데이터에 그대로 저장**돼 재현·공유가 쉽다.

### 2. 핵심 구성 요소(노드)
- **Checkpoint(모델)** — SD1.5/SDXL/**Flux** 등 가중치.
- **CLIP Text Encode** — 프롬프트를 조건 임베딩으로 변환([[임베딩]]).
- **KSampler** — 노이즈에서 latent를 만드는 핵심(sampler·scheduler·**steps·CFG·seed**).
- **VAE Decode** — latent → 실제 픽셀 이미지.
- 부가: **LoRA**(경량 파인튜닝 → [[파인튜닝]]) · **ControlNet/IP-Adapter**(구도·참조 제어) · 업스케일러 · AnimateDiff(영상).

### 3. vs Automatic1111 (A1111)
- **A1111** — Gradio **폼 UI**, 초보 친화·빠른 시작.
- **ComfyUI** — **노드 그래프**, 제어·성능·확장성↑(대신 디퓨전 이해 필요, 중급+). **Flux 등 최신 모델은 ComfyUI가 먼저/더 잘** 지원.

### 4. 확장·운영
- **커스텀 노드**(ComfyUI Manager)로 기능 확장 — 새 모델이 나오면 **노드만 추가**하면 되는 모듈 구조(future-proof).
- **API 모드**로 헤드리스 실행 → 서버·파이프라인 자동화.
- 로컬 GPU에서 실행([[온디바이스|로컬]]·[[CUDA]]·[[nvidia-smi]]로 VRAM 확인). 주력은 이미지지만 오디오/비디오 노드도 있음.

## 코드 / 예시 — 기본 txt2img 그래프
```
[Load Checkpoint]─┬─▶[CLIP Text Encode "a cat"](긍정)─┐
                  ├─▶[CLIP Text Encode "blurry"](부정)─┤
                  │                                     ▼
[Empty Latent]───────────────────────────────▶[KSampler]─▶[VAE Decode]─▶[Save Image]
```

## 기억할 문장 / 핵심 포인트
> "ComfyUI는 **디퓨전 파이프라인을 노드로 조립**한다 — 바뀐 노드만 다시 돌려([[증분]]) 빠르고, 워크플로가 그대로 재현·공유된다."
> 초보엔 A1111, **정밀 제어·Flux·프로덕션엔 ComfyUI**.

## 등장하는 개념
- [[임베딩]] — CLIP 프롬프트 인코딩
- [[파인튜닝]] — LoRA(경량 파인튜닝)로 스타일·개념 주입
- [[증분]] — 바뀐 노드만 재실행(증분 실행)
- [[CUDA]] · [[nvidia-smi]] — GPU 실행·VRAM 확인
- [[온디바이스]] · [[로컬 LLM과 셀프호스팅]] — 로컬에서 도는 생성 AI
- [[UVR5]] — 같은 결의 '로컬 AI 도구'(오디오 소스 분리)

## 내 생각 / 적용할 점
-

---
> ✅ **웹 교차검증 완료** — ComfyUI(노드 기반 디퓨전 워크플로 GUI: Checkpoint→CLIP Text Encode→KSampler→VAE Decode), 증분 실행으로 A1111 대비 ~33~41% 빠름·VRAM ~14%↓, 워크플로 PNG 메타데이터 저장, 커스텀 노드·Flux 지원, A1111(Gradio 폼)과의 차이를 복수 비교 자료로 확인.
