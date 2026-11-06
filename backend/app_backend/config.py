from os import getenv

AZURE_OPENAI_ENDPOINT = getenv("AZURE_OPENAI_ENDPOINT", "")
AZURE_OPENAI_DEPLOYMENT = getenv("AZURE_OPENAI_DEPLOYMENT", "gpt-5.4-mini")
LLM_TIMEOUT = float(getenv("LLM_TIMEOUT", "300"))

QDRANT_URL = getenv("QDRANT_URL", "http://localhost:6333")
COLLECTION = getenv("COLLECTION", "documents")

EMBED_MODEL = getenv("EMBED_MODEL", "BAAI/bge-small-en-v1.5")
EMBED_DIM = int(getenv("EMBED_DIM", "384"))
EMBED_BATCH_SIZE = int(getenv("EMBED_BATCH_SIZE", "64"))
MAX_UPLOAD_BYTES = int(getenv("MAX_UPLOAD_BYTES", str(5 * 1024 * 1024)))

CHUNK_SIZE = int(getenv("CHUNK_SIZE", "256"))
OVERLAP = int(getenv("OVERLAP", "32"))