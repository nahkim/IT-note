---
type: 기술노트
domain: 보안
tags: [IT, 노트, 트러블슈팅, 보안, Vite, 프론트엔드, 소스노출, 배포]
출처: (실무 보안점검 — 사내 서비스 운영 도메인)
종류: 사례정리
읽은날: 2026-10-06
별점: 
aliases: [Vite dev 서버 운영 노출, 미인증 소스 유출, 운영에 뜬 개발서버, vite dev 노출, @vite/client 노출, @fs 경로 유출, 소스맵 복원, 프론트 소스 노출]
---

# 📝 Vite dev 서버를 운영에 띄워 미인증으로 소스가 다 샜다

## 한 줄 요약
> 운영 프론트엔드(`app.example.com`)가 **Vite 개발 서버(`npm run dev`)를 그대로 외부에 노출**한 채 배포돼서, 로그인·토큰 없이(**미인증**) **URL만 치면** 원본 소스·인증로직·설정·서버 내부 경로가 전부 열렸다. 공격 도구도 인증 우회도 필요 없는 "문이 열려 있는" 수준. 원인은 Dockerfile의 `CMD ["npm","run","dev"]` 한 줄. 해결은 **`vite build` 정적 번들 → nginx 서빙**으로 전환하는 것. → [[웹사이트 보안]]

핵심 교훈: **dev 서버는 핫리로드를 위해 원본을 그대로 서빙하는 "개발자 로컬용" 도구다. 거기엔 인증 경계가 설계상 존재하지 않는다.** 그걸 외부에 띄우는 순간, 원본 소스 전체가 공개 파일서버가 된다.

## 핵심 내용

### 1. 증상 — 미인증 상태로 전부 열람됨
로그인도 쿠키도 없이 아래가 전부 HTTP 200으로 열렸다.

| 항목 | 경로 | 내용 |
|------|------|------|
| 원본 소스 전체 | `/src/App.svelte` → import 트리 | 컴파일 전 Svelte 원본, 전 컴포넌트/lib |
| 인증 로직 + 주석 | `/src/lib/auth-utils.js` | 도메인 검증 규칙 + 백엔드 파일명(`app/auth_domain.py`) 언급 주석 |
| 소스맵(원본 복원) | 파일 말미 `sourceMappingURL=data:...base64` | 주석까지 100% 복원 |
| 서버/빌드 설정 | `/vite.config.js` | 내부 백엔드 주소(`localhost:8000`), allowedHosts |
| 서버 내부 절대경로 | `/@fs/...` | `/<회사>/<프로젝트>` 파일시스템 경로 |
| dev 핑거프린트 | `/` HTML | `/@vite/client`, `/src/main.js`, `register-dev-sw` |

- **F12 → Sources 탭**에 `src/` 트리가 통째로 뜨고, 파일 클릭 → 원본 열람 + 중단점까지 가능.
- 자동 봇이 `/@vite/client` 핑거프린트로 이런 노출 서버를 스캔하기도 한다.

### 2. 원인 — 운영 이미지가 dev 서버로 기동
```dockerfile
# compose/frontend.Dockerfile (문제)
CMD ["npm", "run", "dev", "--", "--host"]   # ← Vite dev 서버
```
이 이미지가 CI(`.github/workflows/frontend.yaml`, 태그 `v*` push)로 빌드·NCP 배포됨.
dev 서버는 핫리로드 위해 원본을 변환만 해서 내보내므로 인증 경계가 없다.

### 3. 해결 — 정적 빌드로 전환
멀티스테이지 Dockerfile: ① `vite build` → ② nginx가 `dist/`만 정적 서빙.
```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY frontend ./
RUN npm install && npm run build
FROM nginx:alpine
COPY compose/frontend.nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
```
- `vite build`가 **esbuild로 자동 minify**(주석 제거·이름 뭉갬) + **소스맵 미생성**(`build.sourcemap` 기본 false).
- 번들엔 `src/` 트리·`@vite/client`·`@fs` 자체가 없음 → 위 6개 항목 일괄 해소.
- 로컬 핫리로드는 `frontend.dev.Dockerfile`로 분리해 유지(`docker-compose`가 그걸 사용).

### 4. minify는 보안장치가 아니다 — 뭐가 남나
빌드 후 번들(`assets/index-[hash].js`)에서:
- 가려짐: **주석 전부 삭제**, 함수/변수명 뭉개짐(`isAllowedEmail`→`e,t,r`), 파일 구조 소멸.
- **그래도 남음**: 문자열은 못 지운다 → **API 엔드포인트 전체**(`/user/login`, `/user/auth/public-key` …), **로직 흐름**(이름만 바뀐 채 `n.slice(i+1)===r` 같은 비교 보임), 한글 UI 문자열.
- 결론: minify는 "비밀 유지"가 아니라 **정찰 비용을 초→시간으로 올리고 원본 주석·구조·서버경로를 차단**하는 것. 진짜 방어선은 서버사이드뿐. (클라이언트 코드는 비밀이 될 수 없다.)

## 체크리스트 / 재발방지
- [ ] 운영에 **dev 서버(`vite dev`, `next dev`, `webpack-dev-server` 등)를 절대 노출하지 않는다.** 배포는 항상 빌드 산출물.
- [ ] 운영 빌드는 **소스맵 비활성**(`build.sourcemap: false`) 또는 비공개.
- [ ] `/@vite/client`, `/src/`, `/@fs/` 가 외부에서 200이면 즉시 dev 서버 노출 의심.
- [ ] 비밀값·API키는 프론트에 두지 않는다. 권한·차단은 **서버에서** 강제.
- [ ] 배포 후 검증은 **상태코드가 아니라 본문**으로: `curl $H/ | grep -c '@vite/client'` → 0.

## 관련 노트
- [[웹사이트 보안]]
- [[Docker nginx 포트 없이 접속]]
- [[임베디드 웹뷰 구글 로그인 차단]] — "내 컴퓨터에서는 되는데"가 정상의 증거가 아니라는 같은 교훈
