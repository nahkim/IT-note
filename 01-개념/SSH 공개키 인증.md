---
type: 개념
tags: [IT, 보안, 인프라, SSH]
created: 2026-06-26
aliases: [SSH 키 인증, 패스워드 없는 SSH, SSH 공개키, passwordless ssh]
---

# SSH 공개키 인증 (패스워드 없는 접속)

## 한 줄 정의
SSH 접속 때 **비밀번호를 입력하는 대신**, 클라이언트가 가진 **개인키(private key)**로 서버가 낸 챌린지에 서명해 신원을 증명하는 방식. 서버에는 짝이 되는 **공개키(public key)**만 등록해 둔다. 비밀번호 자체가 네트워크로 오가지 않아 더 안전하고, 자동화에 쓰기 좋다.

## 자세히

### 어떻게 패스워드 없이 되나 (원리)
- 비대칭 암호([[암호화와 해싱]]) 기반. **개인키는 내 컴퓨터에만**, **공개키는 서버의 `~/.ssh/authorized_keys`**에 둔다.
- 접속 시: 서버가 랜덤 챌린지를 보내고 → 클라이언트가 **개인키로 서명** → 서버가 등록된 **공개키로 검증**. 일치하면 로그인 허용. 개인키는 서버로 전송되지 않는다.
- 즉 "비밀번호를 안 친다"의 핵심은 **공개키 인증(public key authentication)**으로 비밀번호 인증을 대체하는 것.

### 기본 설정 3단계
**① 키 쌍 생성** (클라이언트에서, 한 번만)
```bash
ssh-keygen -t ed25519 -C "내 메모"   # 권장: ed25519 (구형 호환은 -t rsa -b 4096)
# → 개인키 ~/.ssh/id_ed25519, 공개키 ~/.ssh/id_ed25519.pub 생성
# 패스프레이즈를 걸어두면 개인키 탈취 시에도 한 겹 더 안전(→ ssh-agent와 함께 쓰면 매번 안 쳐도 됨)
```

**② 공개키를 서버에 등록**
- 방법 A — `ssh-copy-id` (가장 간편, 권장):
```bash
ssh-copy-id user@host
# 또는 키 지정: ssh-copy-id -i ~/.ssh/id_ed25519.pub user@host
```
  최초 1회만 서버 비밀번호를 묻고, 공개키를 `~/.ssh/authorized_keys`에 추가한다. **원격 `.ssh` 디렉터리·파일 권한까지 알아서 맞춰 준다.**

- 방법 B — 수동 등록 (`ssh-copy-id`가 없을 때, 예: 기본 macOS·Windows):
```bash
# 파이프로 한 번에 추가
cat ~/.ssh/id_ed25519.pub | ssh user@host \
  'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys'

# 또는 scp로 옮긴 뒤 서버에서 직접 append
scp ~/.ssh/id_ed25519.pub user@host:~/
ssh user@host 'cat ~/id_ed25519.pub >> ~/.ssh/authorized_keys'
```

> ⚠️ **권한이 안 맞으면 키 인증이 조용히 실패**한다(`Permission denied (publickey)`). `~/.ssh`는 **700**, `authorized_keys`는 **600**이어야 하고, SSH는 너무 느슨한 권한이면 파일을 아예 무시한다.

**③ 접속** — `ssh user@host` → 비밀번호 없이 로그인.

### 그 외 패스워드 없이 접속하는 방법들
- **ssh-agent (개인키 패스프레이즈 캐싱)** — 개인키에 패스프레이즈를 걸어도, 에이전트에 한 번 올려두면(`ssh-add ~/.ssh/id_ed25519`) 세션 동안 다시 안 묻는다. macOS는 키체인 연동(`ssh-add --apple-use-keychain`, `~/.ssh/config`에 `UseKeychain yes`)으로 재부팅 후에도 유지.
- **`~/.ssh/config`** — 접속 자체를 패스워드 없게 만들진 않지만, `Host`/`IdentityFile`로 호스트별 키·옵션을 묶어 `ssh 별칭` 한 줄로 접속하게 해 준다(키 인증과 조합).
- **SSH 인증서(certificate)** — CA가 사용자/호스트 키에 **서명**해 발급. 서버마다 `authorized_keys`를 갱신할 필요 없이, **단기 인증서**로 대규모·자동화 환경을 안전하게 운영. (`ssh-keygen`으로 서명)
- **FIDO2 하드웨어 보안키** — OpenSSH 8.2+에서 `ssh-keygen -t ed25519-sk`(또는 `ecdsa-sk`). 개인키 자체가 **YubiKey 등 하드웨어를 벗어나지 않고**, 접속 시 비밀번호 대신 **터치/PIN**으로 승인.
- **GSSAPI / Kerberos SSO** — 기업·AD 환경에서 `kinit`으로 받은 티켓으로 **싱글사인온**. 비밀번호 재입력 없이 여러 서버에 접속.
- **호스트 기반 인증(host-based)** — `/etc/ssh/shosts.equiv`·`~/.shosts`로 신뢰된 호스트 간 접속을 허용(레거시, 내부망 한정·드묾).
- **에이전트 포워딩(`ssh -A` / `ForwardAgent`)** — 점프 호스트를 거쳐 다음 서버로 갈 때, 개인키를 복사하지 않고 로컬 키로 인증. (보안상 신뢰된 경유지에서만)
- **(비권장) `sshpass`** — 비밀번호를 스크립트로 자동 입력. "패스워드를 안 치는" 게 아니라 **대신 쳐 주는** 것이라 평문 노출 위험이 커, 키 인증으로 대체하는 게 정석.

## 왜 중요한가
- **보안** — 비밀번호 무차별 대입(brute-force) 표적이 사라지고, 비밀번호가 네트워크로 오가지 않는다. (서버에서 `PasswordAuthentication no`로 비밀번호 로그인 자체를 끄는 게 권장 설정)
- **자동화** — [[Ansible]]·[[CI-CD]]·배포 스크립트처럼 사람이 매번 비밀번호를 못 치는 상황에서 필수.
- **편의** — 자주 쓰는 서버에 한 번 설정해두면 매번 입력이 사라진다.

## 관련 개념
- [[암호화와 해싱]] — 공개키/개인키 비대칭 암호가 작동 원리
- [[인증과 인가]] — 공개키 인증은 SSH의 '인증' 수단 중 하나
- [[Ansible]] — 에이전트리스 자동화가 바로 이 키 기반 SSH에 의존
- [[환경 변수]] · [[CI-CD]] — 파이프라인/스크립트에서 키·에이전트로 무인 접속
- [[토큰]] — '비밀번호 없이 신원 증명'이라는 점에서 발상 비교

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — 공개키 인증 원리, `ssh-keygen -t ed25519`, `ssh-copy-id`(최초 1회만 비번·원격 권한 자동 설정), 수동 등록 시 `~/.ssh` 700·`authorized_keys` 600, ssh-agent 캐싱, SSH 인증서, FIDO2 `ed25519-sk`/`ecdsa-sk`(OpenSSH 8.2+), GSSAPI/Kerberos(`kinit`)를 Linuxize·Yubico·OpenSSH 문서 등 복수 출처로 확인.
