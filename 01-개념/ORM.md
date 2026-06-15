---
type: 개념
tags: [IT, 데이터베이스, 백엔드, 기초]
created: 2026-06-11
aliases: [ORM, 객체 관계 매핑]
---

# ORM (Object-Relational Mapping, 객체 관계 매핑)

## 한 줄 정의
[[관계형 데이터베이스와 SQL|DB]]의 **테이블·행을 프로그래밍 언어의 객체·클래스로 자동 매핑**해, SQL 대신 코드로 데이터를 다루게 해주는 도구.

## 자세히
- 객체지향 코드와 표(table) 기반 DB는 사고방식이 달라(임피던스 불일치), 매번 SQL을 손으로 쓰면 번거롭다. ORM이 그 사이를 자동 변환한다.
- 클래스 ↔ 테이블, 객체(인스턴스) ↔ 행(row), 속성 ↔ 컬럼으로 매핑.
- `user = User.objects.get(id=1)` 같은 코드가 내부적으로 `SELECT * FROM users WHERE id=1`로 변환된다 → **CRUD를 SQL 없이** 수행.
- 대표 ORM: **Hibernate**(Java), **Entity Framework**(.NET), **Django ORM·SQLAlchemy**(Python), **Prisma·TypeORM**(JS/TS).
- 장점: 생산성↑, DB 종류 교체가 쉬움, SQL 인젝션 위험↓.
- **흔한 함정 — N+1 쿼리 문제**: 목록을 한 번 조회(1) 후 각 항목의 연관 데이터를 개별 조회(N) → 쿼리가 N+1번 폭증. 지연 로딩(lazy loading) 기본값 탓에 자주 발생하며, eager/join 로딩으로 해결한다.

## 왜 중요한가
- 현대 백엔드 프레임워크 대부분이 ORM을 기본 탑재 — 주니어가 가장 먼저 익히는 DB 접근 방식.
- 편하지만 내부 SQL을 모르면 N+1·느린 쿼리를 못 잡는다 → **ORM을 쓰되 SQL도 알아야** 한다.

## 관련 개념
- [[관계형 데이터베이스와 SQL]] — ORM이 감싸는 대상
- [[데이터베이스 인덱스]] — N+1·느린 쿼리 해결과 직결
- [[FastAPI]] — SQLAlchemy 등 ORM과 함께 자주 쓰는 프레임워크

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — ORM 정의(객체↔테이블 매핑), 대표 프레임워크(Hibernate·SQLAlchemy·Prisma), N+1 쿼리 문제를 AWS·TechTarget·Prisma·Baeldung 등 복수 출처로 2회 확인.
