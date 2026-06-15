---
type: 기술노트
tags: [IT, 노트, 파일포맷, PDF]
출처: PDF 구조 해설(Mapsoft·Nutrient·losLab) + qpdf 공식 문서(QDF Mode·Object/Xref Streams·JSON) + J. Berkenbilt "The Structure of a PDF File"
종류: 정리
읽은날: 2026-06-15
별점:
---

# 📝 PDF 구조와 QDF (PDF File Structure & qpdf QDF form)

## 한 줄 요약
PDF는 **헤더·본문·상호참조표(xref)·트레일러** 네 부분으로 된, **객체(object)들의 묶음 + 위치(offset) 색인** 파일이고, **QDF**는 그 PDF를 *텍스트 에디터로 손편집할 수 있게* qpdf가 정규화해 만든 형태다.

## 핵심 내용

### 1. PDF의 4대 구성요소
1. **헤더(Header)** — 첫 줄 `%PDF-1.7`(버전). 보통 둘째 줄에 **고위 바이트(예: `%âãÏÓ`)로 된 바이너리 주석**을 둬, 전송 도구가 이 파일을 *텍스트가 아닌 바이너리*로 다루게 신호한다.
2. **본문(Body)** — 실제 내용을 담은 **객체들**. 대부분 **간접 객체(indirect object)** 형태:
   - `12 0 obj … endobj` → **객체번호 12 · 세대번호 0**.
   - 다른 객체를 가리킬 땐 **참조** `12 0 R` (R = reference).
3. **상호참조표(Cross-Reference Table, xref)** — 각 간접 객체가 **파일 시작점에서 몇 바이트째**에 있는지(byte offset)를 적은 색인 → 전체를 안 읽고 **임의 접근(random access)** 가능.
4. **트레일러(Trailer)** — `/Root`(문서 카탈로그)·`/Size` 등을 담은 사전. 끝에 **`startxref`(xref의 바이트 위치) → `%%EOF`**로 마무리.

### 2. 객체(Object) — PDF의 8가지 기본 타입
**Boolean · Numeric(정수/실수) · String(`( )` 또는 `< >` 16진) · Name(`/Type`) · Array(`[ ]`) · Dictionary(`<< >>`) · Stream · Null**.
- **Dictionary**: `<< /Key value … >>` 키-값 묶음. PDF 구조의 뼈대.
- **Name**: `/Type` 처럼 `/`로 시작하는 식별자(키·열거값에 쓰임).
- **Stream**: `<<…>> stream … endstream` — 대량/바이너리 데이터(아래 3절).

### 3. 스트림(Stream)과 필터(Filter)
- 이미지·폰트·페이지 콘텐츠처럼 **큰 데이터는 스트림**에 담고, 사전의 `/Length`로 길이를, **`/Filter`로 인코딩 방식**을 명시한다.
- 대표 필터:
  - **`/FlateDecode`** — zlib/deflate 압축. **콘텐츠·일반 데이터의 표준 압축**.
  - **`/DCTDecode`**(JPEG) · **`/JPXDecode`**(JPEG2000, 1.5+) · **`/JBIG2Decode`** · **`/CCITTFaxDecode`** — 이미지용(주로 손실).
  - **`/ASCIIHexDecode`·`/ASCII85Decode`·`/LZWDecode`·`/RunLengthDecode`** 등.
- **필터 캐스케이딩**: `/Filter [/ASCII85Decode /FlateDecode]` 처럼 **여러 필터를 순서대로** 적용할 수 있다.
- 콘텐츠 스트림 안은 **[[PDF 콘텐츠 연산자]]**(후위 표기): `BT … ET`(텍스트 블록), `/F1 24 Tf`(폰트·크기), `72 700 Td`(위치), `(Hello) Tj`(문자 출력), `re`·`f`(사각형·채움) 등. → 상세는 [[PDF 콘텐츠 연산자]].

### 4. 문서의 논리 구조(객체들이 이루는 트리)
- 트레일러의 `/Root` → **카탈로그(Catalog)** → **페이지 트리(`/Pages`)** → 각 **페이지(`/Page`)** → **콘텐츠 스트림 + 리소스(폰트·이미지)**.
- 즉 물리적 배치(본문 객체 나열)와 논리적 구조(참조로 연결된 트리)가 분리돼 있다.

### 5. 어떻게 읽히나 + 증분 업데이트(Incremental Update)
- 리더는 **파일 끝의 `startxref`를 먼저 읽고 → xref로 점프 → `/Root`부터 트리를 따라간다**(뒤에서 앞으로).
- 파일을 수정하면 원본을 안 건드리고 **변경 객체 + 새 xref + 새 트레일러를 끝에 덧붙인다**(증분 업데이트). 그래서 한 PDF에 xref/트레일러가 여러 번 나올 수 있다(이전 xref는 트레일러의 `/Prev`로 연결).

### 6. 객체 스트림 · 상호참조 스트림 (PDF 1.5+)
- 전통 xref는 **20바이트 ASCII 엔트리**(`0000000009 00000 n`)라 사람이 읽기 쉽지만 부피가 크다.
- **객체 스트림(Object Stream, `/Type /ObjStm`)**: 여러 개의 (비스트림) 객체를 **하나의 압축 스트림 안에 묶어** 저장 → 파일 축소.
- **상호참조 스트림(Cross-Reference Stream, `/Type /XRef`)**: xref 자체를 **압축 바이너리 스트림**으로 저장(객체 스트림 안 객체의 위치도 표현).
- 효과: 더 작아지지만 **텍스트로 열어봐도 사람이 못 읽는다** → 디버깅·편집이 어려워짐. ← 이게 **QDF가 필요한 핵심 이유**(QDF는 이걸 풀어 펼친다).

### 7. 암호화(Encryption) — `/Encrypt`
- 암호화된 PDF는 트레일러에 **`/Encrypt` 사전**을 두고, 문자열·스트림 데이터를 암호화한다(표준 보안 핸들러: RC4 → 후속 버전은 AES).
- **주의**: "열기 암호"가 없고 "권한 암호"만 있는 경우 등은 **사용자 비밀번호 없이도 복호화**되곤 한다 → 권한 제한은 보안이 아니라 *약속*에 가깝다. (`qpdf --decrypt`로 제거 가능)

### 8. 선형화 PDF (Fast Web View)
- 첫 페이지를 **전체 다운로드 전에 표시**하도록 객체를 재배치하고 힌트 테이블·앞쪽 xref를 추가한 변형. 서버의 HTTP Range 지원이 전제. **QDF와 동시 사용 불가**.
- 상세는 → **[[선형화 PDF]]**.

### 9. QDF — "텍스트로 편집 가능한 PDF" (qpdf)
- **QDF form**: qpdf가 만드는, **완전히 유효한 PDF**이면서 세 번째 줄에 `%QDF-1.0` 표식을 가진 특수 형태. (qpdf = Jay Berkenbilt가 만든 PDF 변환 도구)
- **왜?** 일반 PDF는 ① 내용이 **압축**(FlateDecode/객체·xref 스트림)돼 있고 ② **offset·length 정보**가 곳곳에 박혀 있어, 한 글자만 바꿔도 위치가 어긋나 텍스트 편집이 사실상 불가능하다.
- QDF가 풀어주는 것(기본값):
  - **스트림 압축 해제**(uncompressed) + **콘텐츠 스트림 정규화**(`--normalize-content`, 기본 on).
  - **객체를 번호 순서대로 배치** — 객체 스트림 안에 있던 것도 펼쳐서 순서대로.
  - **줄바꿈을 UNIX(LF)로 정규화**, 사람이 읽기 쉬운 포맷.
  - **암호화 제거**(QDF 모드에선 기본적으로 풀림).
  - 각 객체 앞에 **원본 객체 ID 등 `%%` 주석**을 달아 위치를 표시(`--no-original-object-ids`로 끌 수 있음 — 파일 비교·테스트용).
- **편집 워크플로**: `qpdf --qdf` 로 만든 파일을 에디터로 수정 → **`fix-qdf`**(qpdf 동봉)가 **xref offset·스트림 length를 다시 계산해 복구**(인자 없이 stdin→stdout).
- **객체 스트림 제어**: `--object-streams=preserve|disable|generate`. QDF로 풀어 볼 땐 보통 `disable`.
- **구조만 들여다보기**: `qpdf --json file.pdf` 는 PDF의 객체 구조를 **JSON으로 덤프**(재작성·재압축·QDF 변환을 하지 않고 *읽기 전용 분석*). `--check`/`--show-xref`도 진단용.
- **제약**: QDF는 **선형화(linearized) PDF를 지원하지 않는다** — 선형화를 켜면 QDF가 자동 비활성화된다.

## 코드 / 예시
```text
%PDF-1.7                      ← 헤더(버전)
%âãÏÓ                          ← 바이너리 주석(고위 바이트)

1 0 obj                       ← 간접 객체: 카탈로그
<< /Type /Catalog /Pages 2 0 R >>
endobj

2 0 obj                       ← 페이지 트리
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj

3 0 obj                       ← 페이지(3 0 R 로 참조됨)
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>
endobj

4 0 obj                       ← 콘텐츠 스트림(보통 FlateDecode 압축)
<< /Length 44 >>
stream
BT /F1 24 Tf 72 700 Td (Hello PDF) Tj ET
endstream
endobj

xref                          ← 상호참조표
0 5
0000000000 65535 f            ← 0번 객체는 항상 free, 세대 65535
0000000009 00000 n            ← 각 엔트리=20바이트: 10자리 offset + 5자리 gen + n(사용)/f(free)
0000000074 00000 n
0000000139 00000 n
0000000241 00000 n
trailer                       ← 트레일러 사전
<< /Size 5 /Root 1 0 R >>
startxref
338                           ← xref 가 시작하는 바이트 위치
%%EOF
```

```text
# QDF form 예시 (qpdf --qdf 결과의 일부) — %QDF 표식과 객체 주석이 붙는다
%PDF-1.7
%¿÷¢þ
%QDF-1.0

%% Original object ID: 4 0
4 0 obj
<< /Length 5 0 R >>          ← 길이를 간접참조로 빼두면 fix-qdf가 자동 보정
stream
BT /F1 24 Tf 72 700 Td (Hello PDF) Tj ET
endstream
endobj
```

```bash
# 일반 PDF → QDF(텍스트 편집용): 스트림·객체스트림을 펼침
qpdf --qdf --object-streams=disable input.pdf output.qdf.pdf
# (에디터로 output.qdf.pdf 를 직접 수정)

# 편집한 QDF를 정상 PDF로 복구 (offset/length 자동 재계산)
fix-qdf < output.qdf.pdf > fixed.pdf

# 구조 분석/진단 (재작성하지 않음)
qpdf --json input.pdf          # 객체 구조를 JSON으로 덤프
qpdf --check input.pdf         # 무결성 점검
qpdf --show-xref input.pdf     # xref 엔트리 보기

# 압축 해제 / 암호 제거 / 선형화
qpdf --decrypt --decode-level=all input.pdf decoded.pdf
qpdf --linearize input.pdf weboptimized.pdf   # ← QDF와 동시 사용 불가
```

## 기억할 문장 / 핵심 포인트
> "PDF를 읽는 순서는 **뒤에서 앞으로** — `%%EOF` 직전의 `startxref`로 xref를 찾고, 트레일러의 `/Root`부터 트리를 탄다."
> "수정은 덮어쓰기가 아니라 **끝에 덧붙이기(증분 업데이트)** — 그래서 '삭제한' 내용이 파일에 남아있을 수 있다(포렌식·정보유출 포인트)."
> "현대 PDF가 텍스트로 안 읽히는 건 **FlateDecode + 객체/상호참조 스트림** 때문 — **QDF가 이걸 풀어 펼친 게** 핵심. 편집 후엔 **`fix-qdf`로 offset을 고친다**."
> "**선형화 ↔ QDF는 양립 불가**: 하나는 스트리밍용 배치, 하나는 사람이 읽기 위한 배치."

## 등장하는 개념
- [[선형화 PDF]] — 웹 점진 표시(Fast Web View)용 재배치, QDF와 상충
- [[JSON과 직렬화]] — PDF도 객체를 직렬화해 저장하는 형태(중첩 사전·배열이 닮음). qpdf의 `--json` 덤프와도 연결
- [[암호화와 해싱]] — `/Encrypt`의 RC4/AES 기반 PDF 암호화
- [[가비지 컬렉션과 메모리|메모리/오프셋]] — 'byte offset 기반 임의 접근'을 이해하는 토대

## 내 생각 / 적용할 점
- 증분 업데이트 특성상 **"지운 텍스트가 실제로 안 지워질 수 있다"** → 민감 문서는 `qpdf --linearize`/평탄화로 재작성하거나 sanitize 필요.
- 깨진 PDF 디버깅·악성 PDF 분석 시 **`qpdf --qdf`로 펼쳐 보거나 `--json`으로 구조만 떠서** 보면 객체 관계가 한눈에 들어온다.
-

---
> ✅ **웹 2회 교차검증** — PDF 4대 구성·8개 객체 타입·간접객체(`N G obj`/`N G R`)·`startxref`/`%%EOF`·증분 업데이트·필터(FlateDecode/DCTDecode 등 캐스케이딩)·객체/상호참조 스트림(1.5+)은 Mapsoft·Nutrient·losLab·Berkenbilt로, **QDF(`%QDF-1.0`·압축 해제·콘텐츠 정규화·암호화 제거·`--object-streams`·`--no-original-object-ids`·`fix-qdf`·선형화 비지원)와 `qpdf --json`**은 **qpdf 공식 문서(QDF Mode·Object/Xref Streams·JSON)**로 확인.
