---
type: 기술노트
tags: [IT, 노트, AI, 음성, STT, ASR]
출처: 각 모델 공식 문서 + Hugging Face Open ASR Leaderboard + 비교 자료 (Whisper·NVIDIA·Deepgram·AssemblyAI 등, 2025~2026 기준)
종류: 정리
읽은날: 2026-06-17
별점:
aliases: [STT, ASR, 음성 인식, Speech-to-Text]
---

# 📝 STT (음성 인식, Speech-to-Text / ASR)

## 한 줄 요약
**소리(음성 파형)를 글자(텍스트)로 바꾸는** 기술. 요즘은 거의 다 **Transformer 기반 딥러닝 모델**이고, 정확도(WER)·속도·언어 수·실시간 여부로 갈린다. "누가 말했나"까지 나누는 건 [[화자 분리]]의 몫.

## 핵심 내용

### 1. STT는 어떻게 동작하나 (파이프라인)
1. **전처리/특징 추출** — 파형을 짧은 프레임으로 잘라 **log-mel 스펙트로그램**(주파수 그림)으로 변환.
2. **음향 모델(Acoustic Model)** — 이 특징을 신경망에 넣어 음소/토큰 확률을 뽑는다. 핵심 부분.
3. **디코딩** — 확률 시퀀스를 실제 문장으로 변환. 옛날엔 별도 **언어 모델(LM)**·발음 사전을 붙였지만, 요즘 end-to-end 모델은 이걸 내부에 흡수.
4. (선택) **후처리** — 문장부호·대소문자·숫자 정규화, 단어별 타임스탬프.

### 2. 모델 구조(아키텍처) 세 갈래
- **Encoder-Decoder (seq2seq)** — 오디오를 인코딩하고 텍스트를 한 토큰씩 생성. **Whisper**가 대표. 다국어·문맥에 강하지만 환각(hallucination)·반복 위험.
- **CTC / Transducer (RNN-T·TDT)** — 프레임을 바로 토큰에 정렬. **스트리밍(실시간)**에 유리해 NVIDIA Parakeet, Deepgram 등이 채택.
- **Self-supervised 사전학습** — wav2vec 2.0·HuBERT처럼 라벨 없는 음성으로 먼저 학습 후 미세조정. 적은 라벨로도 강함. (Conformer = 컨볼루션+[[Transformer]] 인코더, 음성에서 사실상 표준 인코더)

### 3. 핵심 지표: WER (Word Error Rate)
- **WER = (대체 + 삭제 + 삽입) / 전체 단어 수.** 낮을수록 좋다. 일반 영어 벤치 기준 5% 안팎이면 최상위권.
- 단, **WER은 데이터셋·언어·노이즈에 따라 천차만별** — "자사 테스트셋 5%"와 "혼합 실제 데이터 18%"는 같은 모델일 수 있다. 벤치 숫자는 *조건과 함께* 봐야 한다.
- 그 외: **실시간성(latency)**, **RTF(Real-Time Factor)**, 지원 언어 수, 단어 타임스탬프·화자 분리 동시 제공 여부.

### 4. 대표 모델·서비스 (2025~2026)

#### 오픈소스 (직접 호스팅, GPU 필요·분당 과금 없음)
- **OpenAI Whisper large-v3** — 다국어 STT의 **사실상 표준**. 1.55B 파라미터, 99개+ 언어. 약한 지도학습(웹 68만 시간)으로 잡음·억양에 강건.
- **Whisper large-v3-turbo** — 디코더 층을 32→4로 줄여 **약 6배 빠른** 경량판(809M). 정확도는 원본 대비 1~2%p 내.
- **faster-whisper** — CTranslate2로 Whisper를 재구현해 같은 모델을 훨씬 빠르고 가볍게. 실무 배포 단골.
- **NVIDIA Parakeet** — 영어 중심, **매우 빠른 처리량**(TDT/RNN-T). 대량 일괄 처리·온프레미스에 강점.
- **NVIDIA Canary / Canary-Qwen 2.5B** — Hugging Face **Open ASR 리더보드 상위**(영어 WER ~5.6%). LLM 결합형.

#### 상용 API (호스팅·실시간·부가기능)
- **Deepgram Nova-3** — 낮은 지연(서브-300ms)·스트리밍 강점, 실시간 음성 AI에 인기.
- **AssemblyAI Universal-2** — 정확도 높은 스트리밍 + 화자 분리·요약 등 "speech intelligence" 묶음, 99개+ 언어.
- **Google Cloud Chirp / Chirp 2** — 일괄 전사 정확도 우수, 125개+ 언어.
- **OpenAI gpt-4o-transcribe / -mini-transcribe** (2025-03) — Whisper보다 낮은 오류율 표방.
- **Microsoft MAI-Transcribe-1** (2026-04) — MAI 계열 첫 자체 음성 모델, FLEURS 25개 언어 평균 WER 3.8% 주장.

### 5. 무엇을 고를까
- **다국어·정확도·오프라인** → Whisper large-v3 (속도 필요하면 turbo / faster-whisper).
- **실시간 대화(콜봇·자막)** → Deepgram·AssemblyAI 같은 스트리밍 API, 또는 Parakeet/Transducer 계열.
- **대량 일괄 전사를 싸게** → 오픈소스 + 자체 GPU (운영 부담은 감수).
- **회의록처럼 "누가 말했는지"까지** → STT + [[화자 분리]] 조합 (WhisperX 등).

## 코드 / 예시
```bash
# OpenAI Whisper (오픈소스) — 파일 하나를 한국어로 전사
whisper meeting.wav --model large-v3 --language ko --output_format srt
```
```python
# faster-whisper — 같은 모델을 더 빠르게, 단어 타임스탬프까지
from faster_whisper import WhisperModel
model = WhisperModel("large-v3", device="cuda", compute_type="float16")
segments, info = model.transcribe("meeting.wav", word_timestamps=True)
for s in segments:
    print(f"[{s.start:.1f}s -> {s.end:.1f}s] {s.text}")
```

## 기억할 문장 / 핵심 포인트
> "STT의 정확도는 **WER 하나로 줄세울 수 없다** — 어떤 데이터·언어·잡음에서 쟀는지가 숫자보다 중요하다."
> "**Encoder-Decoder(Whisper)는 정확·다국어, Transducer는 실시간** — 용도가 구조를 정한다."
> "STT는 '무슨 말'이고, '누가 말했나'는 [[화자 분리]]다. 둘은 다른 문제이고 보통 **합쳐서** 회의록이 된다."

## 등장하는 개념
- [[화자 분리]] — STT 결과에 화자 라벨을 붙이는 짝꿍 기술
- [[Transformer]] — 거의 모든 현대 STT 모델의 뼈대 (Conformer 인코더 포함)
- [[임베딩]] — 음성 특징·화자 표현의 기반
- [[LLM]] — 후처리·문맥 보정·Canary-Qwen 같은 결합형
- [[AI 모델 서빙 프레임워크]] — 학습된 STT 모델을 API로 띄울 때

## 내 생각 / 적용할 점
-

---
> ✅ **웹 교차검증 완료** — Whisper large-v3(1.55B·99개+ 언어)·turbo(디코더 32→4·~6배)·Canary-Qwen(Open ASR 상위)·Deepgram Nova-3·AssemblyAI Universal-2·gpt-4o-transcribe(2025-03)·MAI-Transcribe-1(2026-04), WER 정의와 파이프라인(특징추출→음향모델→디코딩)을 Northflank·Deepgram·HF 리더보드·OpenAI 등 복수 출처로 확인.
