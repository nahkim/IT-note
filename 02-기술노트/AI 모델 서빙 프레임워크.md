---
type: 기술노트
tags: [IT, 노트, AI, MLOps, 서빙]
출처: 각 프로젝트 공식 문서/저장소 + 비교 자료 (vLLM·TGI·NVIDIA·SGLang 등, 2025~2026 기준)
종류: 정리
읽은날: 2026-06-17
별점:
---

# 📝 AI 모델 서빙 전용 프레임워크 (Model Serving Frameworks)

## 한 줄 요약
학습이 끝난 모델을 **빠르고·죽지 않고·싸게** API로 띄우는 게 서빙이고, 이걸 전담하는 도구들은 크게 **① 추론 엔진(빠르게)·② 서빙 서버(안정적으로)·③ 로컬 런타임(간단하게)** 세 층으로 나뉜다.

## 핵심 내용

### 1. 왜 "전용" 프레임워크가 필요한가
- 모델을 [[FastAPI]]로 직접 감싸 `model.predict()`를 호출하면 **돌긴 돈다.** 하지만 트래픽이 늘면 무너진다.
- 특히 [[LLM]]은 일반 모델과 다른 고통이 있다:
  - 출력이 **토큰 단위로 한 개씩** 생성된다(autoregressive) → 요청마다 길이가 제각각.
  - [[Transformer]]의 **KV 캐시**가 GPU 메모리를 잡아먹는다 → 메모리 관리가 곧 처리량.
  - 요청을 그냥 모아 배치하면(static batching) 긴 요청 하나 때문에 짧은 요청들이 다 기다린다.
- 전용 서빙 프레임워크는 이 문제(메모리·배칭·스케줄링·직렬화·도커라이즈)를 **표준화·자동화**해 준다.

### 2. 핵심 기술 두 가지 (LLM 서빙의 심장)
1. **연속 배칭(Continuous / In-flight Batching)** — 배치를 요청 단위가 아니라 **토큰 생성 매 스텝마다** 새로 구성한다. 끝난 요청은 빠지고 새 요청이 빈자리로 들어와 GPU가 쉬지 않는다.
2. **PagedAttention** — KV 캐시를 OS의 가상 메모리처럼 **작은 블록(page)** 으로 쪼개 관리한다. 메모리 낭비(파편화)를 없애 같은 GPU에 더 많은 요청을 태운다. vLLM이 도입한 대표 기법.
   - 사촌 격으로 **RadixAttention**(SGLang): 여러 요청이 **앞부분(prefix)을 공유**하면 KV 캐시를 재사용해 중복 연산을 줄인다.

### 3. 세 가지 층으로 나눠 보기

#### ① 범용 모델 서버 (프레임워크 무관, 프로덕션 배포)
- **NVIDIA Triton Inference Server** — TensorFlow·PyTorch·ONNX·TensorRT 등 **무슨 프레임워크든** 받아 HTTP/gRPC로 서빙. 배칭·헬스체크·메트릭·멀티모델을 기본 제공. *2025-03 NVIDIA Dynamo 플랫폼에 편입되며 'Dynamo Triton'으로 명칭 변경.*
- **TensorFlow Serving** — TF/Keras 모델 전용의 고전적·안정적 서버.
- **TorchServe** — PyTorch 공식 서버였으나 **2025-08 저장소 아카이브 + 'Limited Maintenance'**. 신규 프로젝트엔 권장하지 않음(보안 패치 없음).
- **[[BentoML]]** — 파이썬 코드로 서비스 정의 → Bento로 패키징 → 도커/K8s 배포까지 묶는 워크플로 중심 프레임워크. 적응형 배칭 지원.

#### ② LLM 특화 추론 엔진 (속도·처리량)
- **vLLM** — PagedAttention + 연속 배칭의 원조. 오픈소스 LLM 서빙의 **사실상 표준**. V1 엔진으로 처리량 개선. HF Transformers 대비 수~수십 배 throughput.
- **NVIDIA TensorRT-LLM** — NVIDIA GPU에 **컴파일·최적화**(커널 퓨전·양자화·in-flight batching)하는 엔진. 보통 Triton 위에 얹어 서빙한다. NVIDIA 환경에서 최고 성능.
- **SGLang** — RadixAttention·구조화 출력(structured generation)·프로그래밍 가능한 추론 파이프라인에 강점. 7~8B급에서 vLLM보다 높은 처리량을 보이기도.
- **LMDeploy** — NVIDIA에서 throughput 벤치마크 상위권을 자주 차지.
- **Hugging Face TGI** — HF 생태계 표준이었으나 **2025-12 유지보수 모드(버그 픽스만)**. HF도 신규엔 vLLM/SGLang 권장. (단, TRT-LLM·vLLM을 백엔드로 쓰는 멀티백엔드 지원 추가됨.)

#### ③ 로컬 / 엣지 런타임 (간편함·이식성)
- **Ollama** — 명령 한 줄로 로컬에서 LLM 실행. 개발·프로토타이핑·온프레미스에 최적.
- **llama.cpp** — C/C++ 기반, CPU·양자화에 강해 **리소스 제약 환경(엣지)** 의 강자. (Ollama도 내부적으로 이 계열을 활용.)

#### ④ 쿠버네티스 네이티브 (운영·확장)
- **KServe** — [[쿠버네티스]] 위에서 모델을 CRD로 선언적으로 배포·오토스케일(0까지 축소 포함). 위 엔진들을 런타임으로 끼워 쓴다.
- **Ray Serve** — Ray 기반 분산 서빙. 여러 모델을 엮은 추론 그래프·파이썬 친화적 스케일아웃에 강점.

### 4. 무엇을 고를까 (의사결정 가이드)
- **대규모 LLM API**를 띄운다 → vLLM(범용 표준) / NVIDIA 전용이면 TensorRT-LLM(+Triton) / 구조화 출력·prefix 공유 많으면 SGLang.
- **여러 종류 모델**(비전·추천·LLM 혼재)을 한 서버로 → Triton.
- **패키징~배포 워크플로**까지 한 번에 → [[BentoML]].
- **K8s에서 선언적 운영·오토스케일** → KServe / Ray Serve (안에 vLLM 등을 런타임으로).
- **내 노트북·온프레미스에서 가볍게** → Ollama / llama.cpp.

> ⚠️ 추론 엔진(vLLM·TRT-LLM)과 서빙 서버(Triton·KServe)는 **경쟁이 아니라 층이 다르다.** 보통 "엔진을 서버 안에 끼워" 같이 쓴다.

## 코드 / 예시
```
[요청]
  │
  ▼
[게이트웨이/[[로드 밸런서]]]
  │
  ▼
┌───────────────── 서빙 서버 ─────────────────┐
│  (Triton / KServe / Ray Serve / BentoML)    │   ← 라우팅·배칭·메트릭·오토스케일
│        └── 추론 엔진 ───────────────┐        │
│            (vLLM / TensorRT-LLM /  │        │   ← 연속 배칭·PagedAttention
│             SGLang) + KV 캐시       │        │
│                  └── GPU ───────────┘        │
└─────────────────────────────────────────────┘
  │
  ▼  [[수평 확장]] — 트래픽 늘면 복제본(replica) 증설
```

```bash
# 예: vLLM을 OpenAI 호환 API 서버로 한 줄 실행
vllm serve meta-llama/Llama-3.1-8B-Instruct
# → http://localhost:8000/v1/chat/completions 로 호출
```

## 기억할 문장 / 핵심 포인트
> "서빙의 90%는 **메모리(KV 캐시)와 배칭** 싸움이다 — PagedAttention과 연속 배칭이 판도를 바꿨다."
> "**추론 엔진 ≠ 서빙 서버.** 빠르게 돌리는 층과 안정적으로 운영하는 층을 헷갈리지 말 것."
> "프레임워크는 **죽고 살아난다** — TGI는 유지보수 모드, TorchServe는 아카이브. 도입 전 *현재 활성 상태*를 꼭 확인."

## 등장하는 개념
- [[BentoML]] · [[LLM]] · [[Transformer]] — 서빙 대상과 그 특성
- [[FastAPI]] — 직접 감쌀 때의 출발점(그리고 한계)
- [[RAG]] — 파이프라인을 서비스로 내보낼 때의 서빙 계층
- [[쿠버네티스]] · [[컨테이너와 Docker]] — 배포·운영 기반
- [[수평 확장]] · [[로드 밸런서]] · [[캐시]] · [[토큰]] — 확장과 성능의 기초
- 실습: [[BentoML 첫 프로젝트 만들기]]

## 내 생각 / 적용할 점
-
