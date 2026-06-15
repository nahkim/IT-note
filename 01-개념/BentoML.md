---
type: 개념
tags: [IT, AI, MLOps]
created: 2026-06-10
---

# BentoML (벤토ML)

## 한 줄 정의
학습이 끝난 머신러닝·AI 모델을 **API 서버로 감싸 배포**할 수 있게 패키징·서빙해주는 파이썬 오픈소스 프레임워크.

## 자세히
- 모델을 **만드는 일**과 실제 서비스로 **띄우는 일**은 다르다. BentoML은 그 사이의 간극(모델 서빙·배포)을 채운다.
- 핵심 개념 3가지:
  - **Service** — `@bentoml.service`를 붙인 파이썬 클래스가 API의 단위. 메서드에 `@bentoml.api`를 붙이면 그게 엔드포인트가 된다.
  - **Bento** — 모델 + 코드 + 의존성 + 설정을 한 덩어리로 묶은 **표준 배포 패키지**(빌드 산출물). `bentoml build`로 만든다.
  - **Model Store** — 모델을 버전과 함께 저장하는 로컬 저장소.
- 흐름: `bentoml serve`로 로컬에서 API 서버 실행 → `bentoml build`로 Bento 빌드 → `bentoml containerize`로 Docker 이미지 생성.
- 성능 기능: **적응형 배칭(adaptive batching)**으로 요청을 자동으로 묶어 GPU 처리량을 높이고, 워커 병렬 실행·GPU·비동기를 지원한다.
- 입력/출력은 **타입 힌트 + Pydantic**으로 자동 검증되고, Swagger(OpenAPI) 문서가 자동 생성된다.
- PyTorch, TensorFlow, scikit-learn, XGBoost, ONNX, Hugging Face Transformers 등 다양한 프레임워크를 지원한다.
- LLM 서빙: **vLLM** 연동, 오픈소스 LLM을 OpenAI 호환 API로 띄우는 자매 프로젝트 **OpenLLM**.
- 배포처: Docker·쿠버네티스, 그리고 관리형 배포 플랫폼 **BentoCloud**.

## 왜 중요한가
- 모델을 [[FastAPI]]로 직접 감싸며 반복하던 일(직렬화·배칭·도커라이즈·스케일링)을 **표준화**해 준다.
- [[RAG]]·[[LLM]] 파이프라인을 실제 서비스로 내보낼 때 **서빙 계층**을 담당한다.
- 여러 모델을 엮은 추론 그래프를 하나의 서비스로 묶고, 트래픽이 늘면 [[수평 확장]]·[[로드 밸런서]]로 키울 수 있다.

## 관련 개념
- [[LLM]] — BentoML로 서빙하는 대표적인 모델
- [[RAG]] — RAG 파이프라인을 API로 배포할 때의 서빙 계층
- [[수평 확장]] · [[로드 밸런서]] — 트래픽 증가 시 복제본을 늘려 분산
- 실습: [[BentoML 첫 프로젝트 만들기]]

## 내 생각 / 질문
-
