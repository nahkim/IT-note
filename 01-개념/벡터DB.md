---
type: 개념
tags: [IT, AI, 데이터베이스]
created: 2026-06-09
---

# 벡터DB (Vector Database)

## 한 줄 정의
[[임베딩]] 벡터를 저장하고, "가장 비슷한 벡터"를 빠르게 찾아주는(ANN 검색) 데이터베이스.

## 자세히
- 일반 DB가 "정확히 일치"를 찾는다면, 벡터DB는 **"의미가 가까운 것"**을 찾는다.
- 핵심 기술은 **ANN(Approximate Nearest Neighbor)** 검색 — HNSW, IVF 같은 인덱스 사용.
- 대표 제품: Pinecone, Weaviate, Milvus, Qdrant, pgvector(PostgreSQL 확장).

## 왜 중요한가
- [[RAG]] 파이프라인에서 "관련 문서 검색"을 담당하는 저장소.

## 관련 개념
- [[임베딩]] — 벡터DB에 저장되는 데이터
- [[RAG]] — 벡터DB로 문서를 검색해 LLM에 전달
- [[LLM]] — 검색 결과를 활용하는 모델

## 내 생각 / 질문
-
