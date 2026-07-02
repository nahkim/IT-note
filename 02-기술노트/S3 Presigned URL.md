---
type: 기술노트
tags: [IT, 노트, 보안, 스토리지, 네트워크]
출처: (실무 정리 — AWS SigV4 공식 문서 · rustfs/MinIO)
종류: 정리
읽은날: 2026-07-02
별점: 
aliases: [S3 Presigned URL, presigned URL, SigV4, 프리사인드 URL]
---

# 📝 S3 Presigned URL — SigV4 호스트 서명으로 GPU 직접 다운로드

## 한 줄 요약
S3 presigned URL은 **SigV4로 서명**되고, 그 서명에 **`host`가 포함**된다. 그래서 발급할 때 endpoint를 **GPU가 닿을 수 있는 호스트(내 맥의 LAN IP)**로 주면, GPU가 그 URL로 **rustfs에서 파일을 직접** 받을 수 있다. (앱이 중계할 필요 없음)

## 핵심 내용

### 1. 문제 상황 — 왜 이게 필요한가
- 내 맥에 **rustfs**(S3 호환 오브젝트 스토리지, MinIO 대체 Rust 구현)가 돌고, 별도의 **GPU 머신**이 거기 있는 큰 파일(모델·오디오 등)을 받아야 함.
- 앱이 rustfs에서 받아 다시 GPU로 넘기면 **대역폭·메모리 2배 낭비**(중계). → GPU에 **presigned URL**만 건네고 **직접 pull**하게 하면 앱은 바이트를 안 만진다. (→ [[레이턴시]] 감소)

### 2. Presigned URL이란
- **자격증명 없이 시간제한 접근**을 주는 서명된 URL. 쿼리스트링에 서명 정보가 들어감:
  `X-Amz-Algorithm=AWS4-HMAC-SHA256`, `X-Amz-Credential`, `X-Amz-Date`, `X-Amz-Expires`, `X-Amz-SignedHeaders`, `X-Amz-Signature`.
- 받는 쪽은 자격증명이 필요 없고, **발급자(서명자)의 권한**으로 그 객체에 접근한다(만료 전까지). (→ [[인증과 인가]])

### 3. 핵심 — SigV4는 `host`를 서명한다
- SigV4의 **CanonicalHeaders에는 `host`가 필수**로 들어가고, **`SignedHeaders`에 `host`가 포함**된다(본문·추가 헤더가 없으면 사실상 host만 서명).
- 서명은 **HMAC-SHA256**으로 계산됨(→ [[암호화와 해싱]]). 즉 **서명 = f(method, path, query, host, …)**.
- ⇒ **서명한 뒤 URL의 호스트를 바꾸면** 계산된 서명과 안 맞아 **`SignatureDoesNotMatch`** 오류. "생성 때 쓴 host"와 "요청할 때의 host"가 **정확히 일치**해야 한다.

### 4. 그래서 endpoint를 'GPU가 닿는 호스트'로 발급
- `localhost`/`127.0.0.1`로 발급하면 host가 그렇게 서명됨 → **GPU가 접속하면 자기 자신의 localhost**를 가리켜 실패(호스트를 손으로 바꾸면 서명 깨짐).
- **발급 시 endpoint를 맥의 LAN IP**(예: `http://192.168.0.42:9000`)로 주면 `host: 192.168.0.42:9000`으로 서명됨 → GPU가 **그 URL 그대로** rustfs에 직접 접속·다운로드. **URL을 손대지 않으므로 서명도 유효.**

### 5. 사전 조건 (네트워킹)
- rustfs를 **모든 인터페이스에 바인드**: `RUSTFS_ADDRESS=0.0.0.0:9000` (127.0.0.1만 열면 LAN에서 못 붙음).
- **방화벽**에서 해당 포트 허용, GPU와 맥이 **같은 LAN/도달 가능**한 네트워크.
- **path-style** 주소 사용(`http://IP:port/bucket/key`) — 생 IP에는 virtual-host 스타일(`bucket.IP`)을 못 씀.

### 6. 만료·시계·보안
- **만료(`X-Amz-Expires`)** 안에 받아야 함. 서명자·서버 간 **시계 오차**가 크면 실패.
- presigned URL은 **bearer 능력** — URL을 가진 누구나 만료까지 접근 가능 → **만료를 짧게**, URL을 로그·공유에 흘리지 말 것.
- LAN 위 http는 **평문** — 신뢰된 사설망에서만. 네트워크를 벗어나면 TLS(HTTPS) 고려. (→ [[HTTP와 HTTPS]])

## 코드 / 예시
```python
import boto3
from botocore.config import Config

s3 = boto3.client(
    "s3",
    endpoint_url="http://192.168.0.42:9000",     # ★ GPU가 닿는 맥 LAN IP (localhost 금지)
    aws_access_key_id="...", aws_secret_access_key="...",
    region_name="us-east-1",
    config=Config(signature_version="s3v4",       # SigV4
                  s3={"addressing_style": "path"}),# rustfs/MinIO는 path-style
)

url = s3.generate_presigned_url(
    "get_object",
    Params={"Bucket": "models", "Key": "model.safetensors"},
    ExpiresIn=3600,                                # 1시간 만료
)
# 이 url을 GPU에 전달 → GPU에서:  curl -O "$url"   (rustfs에서 직접 다운로드)
```
```
[맥: 앱 + rustfs(0.0.0.0:9000)]
      │  ① endpoint=맥 LAN IP 로 presigned URL 발급 (host가 IP로 서명됨)
      ▼
   presigned URL ──(전달)──▶ [GPU 머신]
                                 │  ② 그 URL 그대로 GET (host 일치 → 서명 유효)
                                 ▼
                        rustfs에서 파일 직접 다운로드 (앱 중계 X)
```

## 기억할 문장 / 핵심 포인트
> "**SigV4는 host를 서명한다.** 그래서 URL의 호스트는 나중에 못 바꾼다 → **발급 시점에 '받을 사람이 닿는 호스트'로 서명**하라."
> localhost로 서명하면 남이 못 받는다. **LAN IP(또는 GPU가 아는 DNS 이름)**로 서명하라.
> 더 깔끔하게는 raw IP 대신 **안정적 호스트명/리버스 프록시**([[리버스 프록시]])로 endpoint를 고정하는 방법도 있다(MinIO `MINIO_SERVER_URL` 류).

## 등장하는 개념
- [[암호화와 해싱]] — SigV4 서명(HMAC-SHA256)의 바탕
- [[인증과 인가]] — presigned URL = 서명자 권한의 시간제한 위임
- [[HTTP 헤더]] · [[HTTP와 HTTPS]] — `host` 헤더 서명, 평문 vs TLS
- [[DNS]] · [[리버스 프록시]] — raw IP 대신 안정적 호스트로 endpoint 고정
- [[레이턴시]] — 중계 없이 직접 다운로드로 홉 제거
- [[로컬 LLM과 셀프호스팅]] · [[AI 모델 서빙 프레임워크]] — GPU에 모델 파일을 전달하는 실제 맥락

## 내 생각 / 적용할 점
-

---
> ✅ **웹 교차검증 완료** — SigV4가 `host`를 CanonicalHeaders/SignedHeaders에 필수 포함(호스트 변경 시 SignatureDoesNotMatch), presigned URL 쿼리 파라미터(X-Amz-Algorithm/Credential/Date/Expires/SignedHeaders/Signature), rustfs S3 호환·`RUSTFS_ADDRESS=0.0.0.0` 바인드, boto3 `signature_version=s3v4`+path-style, localhost로 발급 시 외부 클라이언트가 못 받는 문제를 AWS S3 SigV4 공식 문서·rustfs/MinIO 자료로 확인.
