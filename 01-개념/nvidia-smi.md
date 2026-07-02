---
type: 개념
tags: [IT, AI, GPU, CLI, 모니터링]
created: 2026-06-30
aliases: [nvidia-smi, NVSMI, NVIDIA System Management Interface]
---

# nvidia-smi

## 한 줄 정의
NVIDIA GPU의 상태(드라이버·온도·전력·메모리·사용률·실행 중인 프로세스)를 한눈에 보여주는 **GPU 모니터링·관리 CLI**(NVIDIA System Management Interface). 터미널에 `nvidia-smi`만 쳐도 현재 GPU 현황 표가 출력된다.

## 출력 예시
```
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.65.06              Driver Version: 580.65.06      CUDA Version: 13.0       |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA A100-SXM4-40GB      On      | 00000000:07:00.0 Off   |                    0 |
| N/A   38C    P0             250W / 400W |  18432MiB / 40960MiB   |     87%      Default |
|                                         |                        |             Disabled |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                               |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory  |
|        ID   ID                                                               Usage       |
|=========================================================================================|
|    0   N/A  N/A     31245      C   python (vllm)                               18420MiB  |
+-----------------------------------------------------------------------------------------+
```

## 항목별 의미

### ① 맨 윗줄 — 버전 정보
- **NVIDIA-SMI** — smi 도구 자체의 버전.
- **Driver Version** — 설치된 NVIDIA 드라이버 버전.
- **CUDA Version** — **이 드라이버가 지원하는 최대 CUDA 버전**. ⚠️ 실제 설치된 툴킷(`nvcc --version`)과 다를 수 있다 — 여기 13.0이어도 프로젝트는 12.x 툴킷을 쓸 수 있음. (→ [[CUDA]])

### ② GPU 표 — 윗 행
- **GPU** — GPU 인덱스(`0`, `1`, …). 코드에서 `CUDA_VISIBLE_DEVICES`나 디바이스 지정할 때 이 번호.
- **Name** — 모델명(예: `A100-SXM4-40GB`).
- **Persistence-M** — 퍼시스턴스 모드. `On`이면 클라이언트가 없어도 드라이버가 메모리에 상주 → **첫 CUDA 호출 지연↓**(서버에선 보통 On 권장).
- **Bus-Id** — PCIe 버스 주소(`00000000:07:00.0`). 여러 장 구분·하드웨어 매핑용.
- **Disp.A** — Display Active. 이 GPU에 **모니터 출력이 연결**돼 있는지(`On`/`Off`).
- **Volatile Uncorr. ECC** — 재부팅 후 누적된 **정정 불가(uncorrectable) ECC 메모리 오류 수**. 늘어나면 하드웨어 이상 신호(미지원/비활성이면 `N/A`).

### ③ GPU 표 — 아랫 행
- **Fan** — 팬 속도(%). 데이터센터용 팬리스 GPU는 `N/A`.
- **Temp** — GPU 코어 온도(°C).
- **Perf** — 성능 상태(P-State). **`P0`=최대 성능 … `P12`=최저(유휴)**. 부하가 없으면 높은 번호로 절전한다.
- **Pwr:Usage/Cap** — 현재 소비 전력 / 전력 상한(W). 예: `250W / 400W`.
- **Memory-Usage** — 사용 중 / 전체 GPU 메모리(MiB). ⚠️ 프레임워크 캐시(PyTorch 캐싱 할당자 등)까지 잡혀 **실제로 '쓰는' 양보다 커 보일 수 있다**. (→ [[가비지 컬렉션과 메모리]])
- **GPU-Util** — 최근 샘플 구간(1초~1/6초)에서 **커널이 1개 이상 실행된 시간의 비율(%)**. ⚠️ '연산 자원을 몇 % 활용했나'가 **아님** — 작은 커널 하나만 계속 돌아도 100%로 보일 수 있어 실제 효율과 다르다.
- **Compute M.** — Compute Mode. `Default`(여러 프로세스 공유) / `Exclusive_Process`(한 프로세스 독점) / `Prohibited`(컴퓨트 금지).
- **MIG M.** — Multi-Instance GPU 모드. `Enabled`면 물리 GPU 한 장을 **격리된 여러 인스턴스로 분할**(A100/H100 등). 기본은 `Disabled`.

### ④ Processes 표 — GPU를 쓰는 프로세스 목록
- **GPU** — 어느 GPU에서 도는지(인덱스).
- **GI ID / CI ID** — MIG의 GPU Instance / Compute Instance ID. MIG를 안 쓰면 `N/A`.
- **PID** — OS 프로세스 ID(죽일 땐 `kill <PID>`).
- **Type** — **`C`**=Compute(CUDA 연산) · **`G`**=Graphics · **`C+G`**=둘 다 · `M`=MPS · `O`=기타. (→ [[프로세스와 스레드]])
- **Process name** — 실행 파일/프로세스 이름.
- **GPU Memory Usage** — 그 프로세스가 점유한 GPU 메모리.

## 꼭 알아둘 함정
- **CUDA Version**(헤더) ≠ 설치된 툴킷 버전. 드라이버가 지원하는 상한일 뿐.
- **GPU-Util 100% ≠ GPU를 꽉 썼다.** 커널이 '돌고 있던 시간' 비율이라, 메모리 대역폭·연산 효율은 별개. 진짜 효율은 Nsight 등 프로파일러로 봐야 함.
- **Memory-Usage**는 프레임워크 예약/캐시를 포함 — "메모리 거의 다 찼네"가 곧 OOM 임박은 아님.

## 자주 쓰는 명령
- `nvidia-smi -l 1` — 1초마다 갱신해 계속 출력 / `watch -n 1 nvidia-smi` — 화면 고정 갱신
- `nvidia-smi -L` — GPU 목록(이름·UUID) 한 줄씩
- `nvidia-smi --query-gpu=utilization.gpu,memory.used,temperature.gpu --format=csv -l 1` — 원하는 값만 **CSV**로(로깅·모니터링용)
- `nvidia-smi dmon` — 초당 한 줄 시계열 모니터링 / `nvidia-smi -i 0` — 특정 GPU만
- `nvidia-smi -pl 300` — 전력 상한 설정 등 관리 명령(권한 필요)

## 관련 개념
- [[CUDA]] — nvidia-smi가 들여다보는 GPU를 실제로 굴리는 플랫폼
- [[vLLM]] — GPU 서빙 시 메모리·Util을 nvidia-smi로 점검
- [[프로세스와 스레드]] — Processes 표의 PID·Type
- [[가비지 컬렉션과 메모리]] — GPU 메모리 점유/캐시 해석과 대비
- [[수평 확장]] — 다중 GPU 현황을 인덱스별로 확인
- [[컨테이너와 Docker]] — 컨테이너(`--gpus`) 안에서 GPU 가시성 확인에도 사용

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — 헤더의 CUDA Version은 '드라이버가 지원하는 최대 CUDA 버전'(설치 툴킷과 별개), GPU-Util은 '샘플 구간(1~1/6초) 동안 커널이 실행된 시간 비율'(자원 활용률 아님), Perf는 P0(최대)~P12(유휴), Persistence-M·Compute M.·MIG M.·Volatile Uncorr. ECC, Processes의 Type(C/G/C+G/M/O)을 NVIDIA 공식 nvidia-smi 매뉴얼·Baeldung·Modal GPU Glossary 등 복수 출처로 확인.
