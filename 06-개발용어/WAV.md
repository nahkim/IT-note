---
type: 용어
tags: [IT, 개발용어, 오디오]
created: 2026-07-02
aliases: [WAV, WAVE, 웨이브, wav 파일]
---

# WAV (Waveform Audio File Format)

**한 줄 뜻**: [[PCM]] 같은 **비압축 오디오를 담는 컨테이너 파일 형식**(Microsoft·IBM, RIFF 기반). 원시 오디오를 손실 없이 저장하는 표준.

**부연**:
- 구조: **RIFF 마스터 청크** 안에 **`fmt ` 청크**(샘플레이트·비트뎁스·채널 등 포맷 정보) + **`data` 청크**(원시 PCM 샘플, 채널 인터리브).
- 헤더는 보통 ~44바이트. **크기 필드(RIFF/data 길이)는 총 길이를 아는 시점(녹음 종료)**에 확정해 채운다 → 스트리밍 기록 시 마지막에 헤더 갱신.
- 비압축이라 용량이 큼(→ 압축은 FLAC/MP3/Opus 등 다른 포맷).

**관련**: [[PCM]] · [[오디오 녹음 파이프라인]]

---
> ✅ 교차검증 — WAV(RIFF 기반 비압축 오디오 컨테이너: fmt 헤더 + data 청크에 원시 PCM)를 Wikipedia(WAV)·WAVE 포맷 스펙으로 확인.
