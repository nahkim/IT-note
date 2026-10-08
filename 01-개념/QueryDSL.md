---
type: 개념
domain: 백엔드
tags: [IT, 데이터베이스, 백엔드, Java, JPA, Spring]
created: 2026-10-07
aliases: [QueryDSL, Querydsl, 쿼리DSL, 타입 안전 쿼리, Q클래스, JPAQueryFactory]
---

# QueryDSL (Querydsl)

## 한 줄 정의
Java에서 **SQL·JPQL 쿼리를 문자열 대신 자바 코드(메서드 체인)로 작성**하게 해주는 타입 안전(type-safe) 쿼리 빌더. 엔티티로부터 **Q클래스**를 자동 생성해, 오타·타입 오류를 **컴파일 시점**에 잡는다.

## 자세히

### 왜 쓰나 — 문자열 쿼리의 문제
- JPA의 JPQL(`"select m from Member m where m.name = :name"`)은 **문자열**이라 오타가 런타임(실행 중)에야 터진다.
- 검색 조건이 있을 수도 없을 수도 있는 **동적 쿼리**를 문자열 이어 붙이기로 만들면 지저분하고 실수가 잦다.
- JPA 표준 Criteria API는 타입 안전하지만 코드가 너무 장황해 읽기 어렵다.
- → QueryDSL은 **SQL처럼 읽히면서 컴파일러가 검사해 주는** 중간 지점.

### 동작 방식
1. `@Entity` 클래스(`Member`)를 빌드하면 애노테이션 프로세서(APT)가 **`QMember`** 클래스를 생성한다.
2. `QMember.member.name` 같은 필드로 조건을 조립한다 — 필드명이 틀리면 컴파일 에러.
3. 실행 시 JPQL(→ [[ORM|Hibernate]]가 SQL로 변환)로 바뀌어 DB에 날아간다.

```java
QMember m = QMember.member;

List<Member> result = queryFactory
    .selectFrom(m)
    .where(
        nameEq(cond.getName()),      // null 이면 조건 자체가 빠짐
        ageGoe(cond.getAgeMin())
    )
    .orderBy(m.createdAt.desc())
    .offset(0).limit(20)
    .fetch();

private BooleanExpression nameEq(String name) {
    return name != null ? m.name.eq(name) : null;
}
```
- `where()`에 `null`을 넘기면 그 조건은 **무시**된다 → 동적 쿼리를 `if` 지옥 없이 깔끔하게 작성. 조건 메서드는 재사용·조합도 쉽다.

### 어디에 쓰이나
- **Spring Data JPA와 짝꿍**: 단순 CRUD는 Spring Data JPA 리포지토리, **복잡한 검색·동적 쿼리는 QueryDSL**로 짜는 커스텀 리포지토리 구조가 국내 Spring 실무의 사실상 표준 조합.
- JPA 외에 SQL(`querydsl-sql`), MongoDB 등 백엔드 모듈도 있다.

### 2026년 기준 현황 — 원본은 멈췄고 포크가 이어받음
| | 원본 | OpenFeign 포크 |
|---|---|---|
| groupId | `com.querydsl` | `io.github.openfeign.querydsl` |
| 상태 | 5.1.0(2024-01) 이후 사실상 유지보수 중단 | 활발 — 7.x 릴리스 중 (7.4.0, 2026-06) |
| 비고 | Spring Boot 3에선 `:jakarta` classifier 필요 | 원본과 거의 같은 API로 그대로 갈아타기 쉬움 |

- **새 프로젝트라면 OpenFeign 포크**를 쓰는 게 무난하다. 의존성 좌표(groupId·버전)만 바꾸면 코드는 대부분 그대로 동작.

### 자주 밟는 함정
- **Q클래스 빌드 설정**: Gradle에서 annotationProcessor 설정이 빠지거나 생성 경로가 꼬이면 `QMember`를 못 찾는다. Q클래스는 생성물이므로 **git에 커밋하지 않는다**.
- **`fetchResults()`·`fetchCount()` deprecated (5.0~)**: 페이징 총 개수는 count 쿼리를 **따로** 작성한다 (`select(m.count())`).
- **fetch join + 페이징**: 컬렉션 fetch join에 `limit`를 걸면 Hibernate가 **메모리에서 페이징**(전체 로드)한다 → 성능 폭탄. [[ORM]]의 N+1 문제와 한 세트로 이해할 것.
- **정렬 기준을 사용자 입력으로 받을 때 (CVE-2024-49203)**: `PathBuilder.get(사용자입력)`으로 `orderBy`를 만들면 **HQL 인젝션** 가능. 원본 5.1.0 등이 해당되며, OpenFeign 포크는 **5.6.1 / 6.10.1**에서 수정. 버전과 무관하게 **정렬 컬럼은 화이트리스트(허용 목록)로만** 받는 게 정석. (커뮤니티 일부는 "개발자가 신뢰할 수 없는 입력을 그대로 넣은 것"이라며 취약점 판정에 이의를 제기했다.)

## 왜 중요한가
- "ORM이면 SQL 인젝션 걱정 없다"는 오해를 깨는 사례 — **쿼리 빌더도 입력값이 쿼리 구조(컬럼명·정렬)에 들어가면 위험**하다.
- Spring + JPA 백엔드 코드를 읽다 보면 `QXxx`, `JPAQueryFactory`, `BooleanExpression`이 반드시 나온다. 정체를 알아야 코드가 읽힌다.

## 관련 개념
- [[ORM]] — QueryDSL이 얹혀 동작하는 기반(JPA/Hibernate), N+1 문제
- [[관계형 데이터베이스와 SQL]] — 최종적으로 만들어지는 것은 결국 SQL
- [[데이터베이스 인덱스]] — 동적 검색 조건·정렬이 인덱스를 타는지 확인 필요

## 내 생각 / 질문
-

---
> ✅ **웹 교차검증 완료** — OpenFeign 포크 최신 릴리스(7.4.0, 2026-06)는 Maven Central·mvnrepository로, CVE-2024-49203(orderBy HQL 인젝션, 영향: 5.1.0·OpenFeign 6.8 / 수정: 5.6.1·6.10.1 / 이의 제기 있음)은 CSIRT.SK·Wiz·Debian 보안 트래커로 확인.
