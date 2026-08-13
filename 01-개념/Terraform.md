---
type: 개념
domain: 인프라
tags: [IT, DevOps, 인프라, 자동화, IaC]
created: 2026-08-13
aliases: [Terraform, 테라폼, IaC, Infrastructure as Code, 코드형 인프라, HCL, OpenTofu, 오픈토푸]
---

# Terraform (테라폼)

## 한 줄 정의
클라우드 인프라(서버·네트워크·DB·권한 등)를 **코드로 선언**해두면, 실제 상태와 비교해 **필요한 변경만 API로 만들어 주는** IaC(Infrastructure as Code) 프로비저닝 도구.

## 자세히

### 무엇을 하나 — 선언하면 맞춰준다
```hcl
terraform {
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}
provider "aws" { region = "ap-northeast-2" }

resource "aws_instance" "web" {
  ami           = "ami-0abcd1234"
  instance_type = "t3.micro"
  tags = { Name = "web-server" }
}
```
- 콘솔에서 클릭하는 대신 **HCL(HashiCorp Configuration Language)** 로 "있어야 할 모습"을 적는다.
- Terraform은 **원하는 상태(코드) ↔ 기록된 상태(state) ↔ 실제 상태(클라우드)** 셋을 비교해 **차이(diff)만** 실행한다 → 여러 번 돌려도 같은 결과([[멱등성]]).

### 핵심 구성 요소
- **Provider** — AWS·GCP·Azure·[[쿠버네티스]]·GitHub 등 **대상 API를 다루는 플러그인**. Terraform 자체는 클라우드를 모르고, 전부 provider가 안다.
- **Resource** — 실제로 만들 대상 하나(EC2 인스턴스, S3 버킷…).
- **Data source** — 이미 있는 것을 **읽어오기만** 하는 조회.
- **Variable / Output** — 입력값과 결과값. 환경별 차이를 여기로 뺀다([[환경 변수]]).
- **Module** — 리소스 묶음을 **재사용 단위**로 패키징. "VPC 모듈", "EKS 모듈"처럼 조립한다.
- **State** — 아래 참고. **가장 중요하고 가장 많이 사고 나는 부분.**

### 기본 워크플로
```
terraform init      # provider·모듈 내려받기, 백엔드 설정
terraform plan      # 실행 계획: 무엇이 생성/변경/삭제될지 미리 보기 (+2 ~0 -1 …)
terraform apply     # 계획대로 실제 적용
terraform destroy   # 만든 것 전부 제거
```
- **`plan`이 Terraform의 정체성**이다. 바꾸기 전에 **무엇이 지워지는지** 사람이 눈으로 확인할 수 있다 — 특히 `-/+ destroy and then create replacement`(재생성) 표시는 무중단 여부와 직결되니 반드시 읽고 넘어간다.

### State — 왜 필요하고 왜 위험한가
- Terraform은 "내가 만든 리소스"를 **`terraform.tfstate`** 에 기록한다. 코드의 `aws_instance.web`과 실제 클라우드의 `i-0abc…`를 **연결하는 장부**.
- **로컬 파일로 두면 협업이 불가능하다.** 팀이 쓰면 **원격 백엔드**(S3·GCS·Azure Blob·HCP Terraform)에 두고 **잠금(locking)** 을 건다. 잠금이 없으면 두 사람의 `apply`가 동시에 돌아 **state가 깨지고**, 장부에서 사라진 리소스가 다음 plan에서 재생성 대상이 된다.
  - AWS는 오래도록 **S3 + DynamoDB 테이블** 조합으로 잠금을 걸었지만, **Terraform 1.10부터 S3 자체 잠금(`use_lockfile = true`)** 이 생겼고 **1.11에서 `dynamodb_table`은 deprecated** 됐다. 새로 구성한다면 lockfile 방식.
- ⚠️ **state에는 비밀번호·키가 평문으로 들어갈 수 있다.** 저장소 암호화(KMS/CMEK)·접근 통제는 선택이 아니다. 절대 Git에 커밋하지 말 것([[형상관리]]).
- **드리프트(drift)** — 누군가 콘솔에서 손으로 고치면 코드·state와 실제가 어긋난다. 정기 `plan`으로 탐지하고, 손댈 거면 코드에 반영하는 게 원칙.
- **blast radius(폭발 반경)** — state 하나에 전사 인프라를 다 담으면 실수 하나가 전부를 건드린다. **환경별·서비스별로 state를 쪼개는** 것이 기본 설계.

### 2026년 현재 알아둘 것
- **테스트 프레임워크(`terraform test`)**, **`import` 블록**(기존 리소스를 코드로 선언적으로 편입), **`removed` 블록**(실제 자원은 두고 state에서만 제거), **ephemeral 값**(실행 중에만 쓰고 **state에 안 남기는** 민감값), **provider 정의 함수** 등이 더해지며 "장부 관리" 부담이 줄었다.
- **라이선스 분기** — 2023년 HashiCorp가 Terraform을 **BUSL 1.1(소스 공개형, 경쟁 서비스 제공 제한)** 으로 바꾸자, 커뮤니티가 **OpenTofu**(MPL 2.0)로 포크했다. OpenTofu는 리눅스 재단 산하로 가 **2025년 4월 CNCF에 편입**됐고, state 암호화·`for_each` provider 등 자체 기능을 붙이며 갈라지는 중.
- **HashiCorp는 2025년 2월 IBM에 인수**(약 64억 달러) 완료.
- 실무 선택: 사내에서 쓰는 데는 둘 다 무료·프로덕션 레디. **HCP Terraform·Sentinel 등 상용 생태계에 묶여 있으면 Terraform**, 라이선스 리스크를 피하고 싶은 신규 프로젝트는 **OpenTofu**를 고르는 흐름. CLI 사용법은 아직 대부분 호환된다.

### [[Ansible]]과 뭐가 다른가 (자주 나오는 비교)
| | **Terraform** | **Ansible** |
|---|---|---|
| 주 역할 | **프로비저닝** — 인프라를 만들고 없앰 | **구성 관리** — 만들어진 서버 안을 설정 |
| 상태 관리 | **state 파일로 추적** | 상태 파일 없음(매번 현재 상태 확인) |
| 방식 | 선언적, 실행 계획(plan) 제공 | 선언적 태스크의 순차 실행(push, agentless) |
| 전형적 조합 | Terraform으로 VM·네트워크 생성 → | → Ansible로 그 안에 설치·설정 |

## 왜 중요한가
- 인프라가 **코드로 버전 관리·리뷰·재현**된다 — 콘솔 클릭은 기록도 리뷰도 롤백도 없다([[Git]] · [[CI-CD]]).
- **재현성**: 개발/스테이징/운영을 같은 코드로 찍어내고, 사고 시 같은 구성을 다시 세울 수 있다.
- 멀티 클라우드·SaaS까지 **하나의 문법**으로 다룬다(provider만 갈아끼우면 됨) — 실제로 GitHub 권한, Datadog 모니터, Cloudflare DNS도 Terraform으로 관리한다.

## 관련 개념
- [[Ansible]] — 프로비저닝(Terraform) vs 구성 관리(Ansible)
- [[멱등성]] — 여러 번 실행해도 같은 결과라는 IaC의 전제
- [[형상관리]] · [[Git]] — 인프라 코드도 버전 관리 대상(단, state는 제외)
- [[CI-CD]] — plan은 PR에서 자동, apply는 승인 후 — 파이프라인 설계의 핵심
- [[쿠버네티스]] · [[컨테이너와 Docker]] — 클러스터 자체는 Terraform으로, 그 안은 매니페스트로
- [[환경 변수]] — 시크릿을 코드·state 밖에 두기
- [[온프레미스]] · [[무중단 배포]] — 어디에 어떻게 굴릴지의 상위 맥락
- [[동시성 문제]] — state 잠금이 막으려는 것이 결국 동시 쓰기

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — HCL 선언 + provider/resource/module/state 구조와 init→plan→apply→destroy 워크플로, 원격 백엔드·state 잠금의 필요성(동시 apply 시 state 손상), **Terraform 1.10의 S3 네이티브 잠금 `use_lockfile`과 1.11에서 `dynamodb_table` deprecated**, state 평문 시크릿·암호화 백엔드 권고·환경별 state 분리(blast radius)·정기 plan 드리프트 탐지, 2026년 기능(`terraform test`·`import`/`removed` 블록·ephemeral 값·provider 정의 함수), **2023년 BUSL 1.1 전환 → OpenTofu(MPL 2.0) 포크 → 리눅스 재단·2025년 4월 CNCF 편입**, **IBM의 HashiCorp 인수 2025년 2월 완료(약 64억 달러)** 를 HashiCorp 공식 문서(backend/s3)·GitHub 이슈·Wikipedia·TechCrunch·2026년 IaC 가이드 복수 출처로 확인.
