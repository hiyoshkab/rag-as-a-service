import pytest
from fastapi.testclient import TestClient
from qdrant_client import QdrantClient

from app_backend import config, embedder, main, store


@pytest.fixture
def test_client(monkeypatch):
    monkeypatch.setattr(config, "COLLECTION", "test_documents")
    monkeypatch.setattr(config, "EMBED_DIM", 3)
    client = QdrantClient(location=":memory:")
    store.ensure_collection(client, config.COLLECTION, config.EMBED_DIM)

    main.app.dependency_overrides[main.get_model] = lambda: object()
    main.app.dependency_overrides[main.get_client] = lambda: client
    main.app.dependency_overrides[main.get_generate] = lambda: (
        lambda question, sources: "The payment is due in 30 days. [1]"
    )

    try:
        yield TestClient(main.app), client
    finally:
        main.app.dependency_overrides.clear()
        client.close()


def test_health_endpoint(test_client):
    client, _ = test_client

    response = client.get("/healthz")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_readiness_endpoint(test_client):
    client, _ = test_client

    response = client.get("/readyz")

    assert response.status_code == 200
    assert response.json() == {"status": "ready"}


def test_ingest_and_query_document(test_client, monkeypatch):
    client, _ = test_client
    monkeypatch.setattr(config, "CHUNK_SIZE", 10)
    monkeypatch.setattr(config, "OVERLAP", 0)
    monkeypatch.setattr(
        embedder,
        "embed_documents",
        lambda model, chunks, **kwargs: [[1.0, 0.0, 0.0] for _ in chunks],
    )
    monkeypatch.setattr(
        embedder, "embed_query", lambda model, question, **kwargs: [1.0, 0.0, 0.0]
    )

    ingest_response = client.post(
        "/ingest",
        files={"file": ("contract.txt", b"payment is due in 30 days")},
    )
    query_response = client.post("/query", json={"question": "When is payment due?"})

    assert ingest_response.status_code == 200
    assert ingest_response.json() == {"filename": "contract.txt", "chunks": 1}
    assert query_response.status_code == 200
    assert query_response.json() == {
        "answer": "The payment is due in 30 days. [1]",
        "citations": [
            {
                "filename": "contract.txt",
                "chunk_index": 0,
                "score": 1.0,
                "text": "payment is due in 30 days",
            }
        ],
        "sources": [
            {
                "filename": "contract.txt",
                "chunk_index": 0,
                "score": 1.0,
                "text": "payment is due in 30 days",
            }
        ],
    }


def test_ingest_rejects_invalid_utf8(test_client):
    client, _ = test_client

    response = client.post("/ingest", files={"file": ("invalid.txt", b"\xff")})

    assert response.status_code == 422
    assert response.json()["detail"] == "File is not valid UTF-8 text"


def test_ingest_rejects_empty_document(test_client):
    client, _ = test_client

    response = client.post("/ingest", files={"file": ("empty.txt", b" \n\t ")})

    assert response.status_code == 422
    assert response.json()["detail"] == "File contains no text"


def test_query_rejects_top_k_outside_allowed_range(test_client):
    client, _ = test_client

    response = client.post("/query", json={"question": "Question?", "top_k": 0})

    assert response.status_code == 422
