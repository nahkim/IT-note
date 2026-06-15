---
type: 실습
tags: [IT, 실습, MLOps]
created: 2026-06-10
난이도: 쉬움
소요시간: 약 30분
완료: false
---

# 🧪 BentoML 첫 프로젝트 만들기 (감정 분석 API 서빙)

## 한 줄 요약
Hugging Face 감정 분석 모델을 [[BentoML]]로 감싸 **API 서버 → Bento 빌드 → Docker 이미지**까지 한 번에 경험해 본다.

## 무엇을 만드나
- **결과물**: 문장을 보내면 긍정/부정을 돌려주는 REST API (`POST /analyze`)
- **사용 기술**: [[BentoML]] + Hugging Face Transformers
- **핵심**: 모델을 직접 학습하지 않고, 공개 모델을 *서빙*하는 흐름을 익힌다.

## 준비물
- Python 3.9+ 환경
- 패키지 설치:
  ```bash
  pip install bentoml torch transformers
  ```

## 따라하기 (단계별)

### 1. 서비스 코드 작성 — `service.py`
- `@bentoml.service`를 클래스에, `@bentoml.api`를 메서드에 붙이는 게 전부다.
- `__init__`에서 모델을 **한 번만** 로드하고, API 메서드는 추론만 담당한다. (코드는 아래 "코드 / 예시" 참고)

### 2. 로컬 서버 실행
```bash
bentoml serve service:SentimentAnalysis
# service.py 한 개만 있으면 그냥 `bentoml serve` 도 동작한다
```
- `service:SentimentAnalysis` = "`service.py` 모듈의 `SentimentAnalysis` 클래스".
- 기본 주소 `http://localhost:3000`, 엔드포인트는 `/analyze`.
- 브라우저로 접속하면 **Swagger UI**가 떠서 API를 바로 눌러볼 수 있다.

### 3. API 호출해 보기
```bash
curl -X POST http://localhost:3000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "BentoML is surprisingly easy!"}'
# → {"label": "POSITIVE", "score": 0.99...}
```

### 4. Bento로 빌드 (배포 패키지 만들기)
- `bentofile.yaml`에 빌드 설정을 적고 `bentoml build` 실행 → 코드+모델+의존성이 하나의 **Bento**로 묶인다.
- 만들어진 Bento 확인: `bentoml list`

### 5. Docker 이미지로 만들기
```bash
# <bento_tag> 는 `bentoml list` 에 뜬 이름:버전 (예: sentiment_analysis:latest)
bentoml containerize <bento_tag>
# → docker run -p 3000:3000 <bento_tag> 로 어디서든 실행
# 참고: `bentoml build --containerize` 하면 빌드+이미지화를 한 번에
```

## 코드 / 예시
```python
# service.py
import bentoml
from transformers import pipeline

@bentoml.service(
    resources={"cpu": "2"},
    traffic={"timeout": 60},
)
class SentimentAnalysis:
    def __init__(self) -> None:
        # 서비스가 뜰 때 모델을 한 번만 로드
        self.pipeline = pipeline("sentiment-analysis")

    @bentoml.api
    def analyze(self, text: str) -> dict:
        result = self.pipeline(text)[0]
        return {"label": result["label"], "score": float(result["score"])}
```

```yaml
# bentofile.yaml — bentoml build 가 읽는 설정
service: "service:SentimentAnalysis"
labels:
  owner: nahkim
include:
  - "*.py"
python:
  packages:
    - torch
    - transformers
```

## 막혔던 점 / 트러블슈팅
- **첫 실행이 느리다** → `pipeline("sentiment-analysis")`이 모델을 처음 한 번 다운로드한다. 두 번째부터는 캐시되어 빠르다.
- **`torch` 설치 용량이 크다** → CPU만 쓸 거면 PyTorch CPU 빌드를 설치하면 가볍다.
- **`containerize` 태그를 모르겠다** → `bentoml list`로 정확한 `이름:버전`을 먼저 확인.

## 기억할 점
> "`@bentoml.service` 클래스 = 배포 단위, `@bentoml.api` 메서드 = 엔드포인트." — 이 두 줄이 BentoML의 전부다.
> "모델 로드는 `__init__`에서 한 번만. API 메서드 안에서 매번 로드하면 느려진다."
> "**Bento**는 모델·코드·의존성을 한 덩어리로 묶은 표준 패키지라, 빌드만 하면 어디서든 똑같이 뜬다."

## 등장하는 개념
- [[BentoML]] — 이 실습의 주인공(서빙 프레임워크)
- [[LLM]] · [[RAG]] — 같은 구조로 확장할 수 있는 대상
- [[수평 확장]] · [[로드 밸런서]] — 트래픽이 늘면 적용할 다음 단계

## 다음으로 해볼 것 / 내 생각
- **성능**: `@bentoml.api(batchable=True)`로 적응형 배칭을 켜 처리량 올리기
- **배포**: `bentoml deploy`로 BentoCloud(관리형 플랫폼)나 쿠버네티스에 올리기
- **LLM**: `pipeline` 대신 vLLM/OpenLLM을 끼우면 같은 구조로 LLM API가 된다 → [[LLM]] · [[RAG]]
-
