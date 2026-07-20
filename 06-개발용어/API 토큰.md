---
type: 용어
tags: [IT, 개발용어, 웹, 보안, 인증]
created: 2026-07-16
aliases: [API 토큰, API Token, API 키, 스코프 기반 토큰, scope-based token, OAuth 스코프, fine-grained 토큰, fine-grained token, 세분화 토큰, PAT]
---

# API 토큰 (API Token · 스코프 · fine-grained)

**한 줄 뜻**: API 요청을 인증하기 위한 **비밀 자격증명(문자열)**. 매번 아이디·비밀번호를 보내는 대신 토큰 하나로 신원을 증명하며, **권한을 좁히고(스코프·fine-grained) 폐기·만료**하기 쉬운 게 장점. (LLM의 [[토큰]]과는 **전혀 다른 개념**)

**부연**:
- **API 토큰(기본)** — 앱·사용자를 식별·인증하는 발급된 키. 보통 [[Basic Auth와 Bearer 인증|Bearer]] 헤더로 전송. 유출 시 **개별 폐기**할 수 있어 비밀번호보다 안전.
- **스코프 기반 토큰(scope-based)** — 토큰에 **스코프**(예: `read:user`, `repo`)를 붙여 **할 수 있는 일을 범주 단위로 제한**. [[OAuth]] 스코프가 대표. **최소 권한 원칙**의 실현이지만, 한 스코프가 *모든* 해당 리소스에 적용돼 다소 굵다.
- **fine-grained 토큰(세분화)** — 권한을 **리소스·동작 단위로 잘게** 제한. 예: GitHub fine-grained PAT는 **특정 리포지토리**만 + **50여 개 권한 각각을 no-access/read/write**로 지정, **만료일 필수**. 유출 시 피해 범위(blast radius)를 크게 줄인다. (기존 classic PAT는 접근 가능한 모든 리포에 적용되고 무기한 가능 → 굵고 위험)
- **흐름**: 전부 접근(classic) → **스코프**로 범주 제한 → **fine-grained**로 리소스·동작 단위 제한. 갈수록 **최소 권한**에 가까워진다. → [[인증과 인가|인가]]·[[RBAC]]의 실전.

**관련**: [[Basic Auth와 Bearer 인증]] · [[OAuth]] · [[인증과 인가]] · [[RBAC]] · [[쿠키 세션 JWT]]

---
> ✅ 교차검증 — API 토큰(발급 자격증명·개별 폐기)·스코프(OAuth 최소권한), fine-grained 토큰(GitHub: 리포 단위+50여 권한 read/write·만료 필수, classic PAT는 전체 접근·무기한)을 GitHub Docs·GitHub Blog·MDN 등으로 확인.
