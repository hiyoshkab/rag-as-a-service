from pydantic import BaseModel, Field

class QueryRequest(BaseModel):
    question: str = Field(min_length=1)
    top_k: int = Field(default=3, ge=1, le=10)

class Source(BaseModel):
    filename: str
    chunk_index: int
    score: float
    text: str

class QueryResponse(BaseModel):
    answer: str
    citations: list[Source]
    sources: list[Source]

class IngestResponse(BaseModel):
    filename: str
    chunks: int