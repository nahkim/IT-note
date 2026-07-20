---
type: 개념
tags: [IT, AI, LLM, 서빙, MLOps]
created: 2026-06-29
aliases: [vLLM, PagedAttention]
---

# vLLM

## 한 줄 정의
LLM을 **빠르고 메모리 효율적으로 서빙·추론**하기 위한 오픈소스 엔진. 핵심은 GPU 메모리(KV 캐시)를 운영체제 가상메모리처럼 '페이지' 단위로 관리하는 **PagedAttention**과, 요청을 실시간으로 배치에 끼워 넣는 **연속 배칭(continuous batching)**. UC Berkeley Sky Computing Lab에서 2023년 시작.

## 자세히

### 무엇을 푸는가 (왜 필요한가)
LLM 추론에는 두 가지 큰 병목이 있다.
- **KV 캐시 메모리 단편화** — 자기회귀 생성은 앞서 만든 토큰들의 Key/Value를 저장해 재계산을 피한다([[토큰]] 단위로 쌓이는 **KV 캐시**). 시퀀스 길이에 비례해 커지는데, 길이를 미리 모르니 메모리를 크게 잡아두다 **낭비·단편화**가 생긴다.
- **정적 배칭으로 인한 GPU 저활용** — 출력 길이가 제각각인데 배치 안 모든 요청이 끝날 때까지 기다리면 GPU가 논다.

### 핵심 기술
- **PagedAttention** — KV 캐시를 **고정 크기 블록(page)**으로 쪼개 **비연속적으로** 할당하고 page table로 매핑한다(OS 가상메모리 paging에서 영감). → 내부 단편화 제거, **공통 프리픽스(시스템 프롬프트 등) 공유**, 같은 메모리 예산으로 **훨씬 많은 동시 요청** 처리.
- **연속 배칭(continuous batching)** — 배치 안에서 **끝난 시퀀스를 매 스텝 새 요청으로 즉시 교체**. 모두 끝날 때까지 기다리는 정적 배칭과 달리 GPU를 놀리지 않는다.
- **그 외 가속 기법** — speculative decoding(추측 디코딩), chunked prefill, FlashAttention, CUDA graphs, prefix caching 등.

### 쓰는 법 / 인터페이스
- **OpenAI 호환 API 서버** — `vllm serve <model>`로 띄우면 OpenAI의 Completions/Chat API와 호환된다 → 기존 OpenAI SDK 코드의 **drop-in 대체**. 파이썬 `LLM` 클래스로 오프라인 배치 추론도 가능.
- **분산 / 멀티 GPU** — 텐서 병렬(`tensor_parallel_size`)·파이프라인 병렬로 큰 모델을 여러 GPU·노드에 분할([[수평 확장]]).
- **양자화** — FP8·NVFP4·INT8/INT4·GPTQ·AWQ·GGUF 등 폭넓게 지원해 메모리·비용을 줄인다.

### 위치 / 생태계
- [[CUDA]] 위에서 최적화된 커널로 동작(주로 NVIDIA GPU, AMD 등도 지원). **PyTorch 기반**(Torch Compile 통합).
- 2025년 **PyTorch Foundation 호스팅 프로젝트**로 합류했고, 2000명이 넘는 기여자가 참여하는 **사실상 표준 오픈소스 추론 엔진**. 내부적으로 'V1' 엔진으로 아키텍처를 재작성해 성능·단순성을 높였다.

## 왜 중요한가
- **비용 절감** — 동일 하드웨어에서 단순 구현 대비 **수 배~수십 배 처리량**(HF Transformers 대비 14~24배, naive 서빙 대비 2~4배 주장). 처리량이 곧 GPU 비용이라, LLM 서비스 단가를 직접 낮춘다.
- **LLM 서빙의 디폴트** — 직접 추론 루프를 짜는 대신 모델만 얹으면 프로덕션급 처리량·동시성을 얻는다. [[FastAPI]]·[[BentoML]] 같은 상위 서빙 레이어 **뒤의 엔진**으로도 흔히 쓰인다.
- KV 캐시 관리를 'OS 페이징'으로 재해석한 **시스템 사고**가, 이후 다른 추론 엔진(SGLang 등)에도 영향을 준 분기점.

## 관련 개념
- [[LLM]] · [[Transformer]] — vLLM이 서빙하는 대상. KV 캐시는 어텐션에서 나온다
- [[로컬 LLM과 셀프호스팅]] — vLLM은 '셀프호스팅(서버 서빙)' 축의 대표 프로덕션 엔진(Ollama와 대비)
- [[CUDA]] · [[GPU vs CPU]] — vLLM의 고속 커널이 도는 토대(왜 GPU인가)
- [[nvidia-smi]] — 서빙 중 GPU 메모리·활용률 확인
- [[토큰]] — 토큰 단위 생성·KV 캐시의 기본 단위
- [[캐시]] — KV 캐시·prefix caching은 캐시 개념의 응용
- [[수평 확장]] — 텐서/파이프라인 병렬로 멀티 GPU 확장
- [[FastAPI]] · [[BentoML]] — 상위 API/서빙 레이어와 조합
- [[동기와 비동기]] — 연속 배칭·비동기 요청 처리의 바탕

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — vLLM(UC Berkeley Sky Computing Lab 출발, 고처리량·메모리 효율 LLM 추론·서빙 엔진), PagedAttention(KV 캐시를 OS 가상메모리식 페이지로 관리→단편화 제거·프리픽스 공유), 연속 배칭(정적 배칭 대비 GPU 저활용 해소), OpenAI 호환 서버·텐서/파이프라인 병렬·양자화(FP8/FP4/GPTQ/AWQ/GGUF 등), PyTorch 기반·2025년 PyTorch Foundation 호스팅 프로젝트·V1 엔진을 vLLM 공식 문서·Red Hat·PyTorch/UC Berkeley 발표·GitHub로 확인.
