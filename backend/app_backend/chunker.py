def chunk_text(text: str, chunk_size: int, overlap: int = 0):
    if chunk_size <= 0:
        raise ValueError("Chunk size must be a positive integer")
    if overlap < 0:
        raise ValueError("Overlap must be a non-negative integer")
    if overlap >= chunk_size:
        raise ValueError("Overlap must be less than chunk size")

    chunks = []
    words = text.split()
    for i in range(0, len(words), chunk_size - overlap):
        chunks.append(" ".join(words[i:i + chunk_size]))

        if i + chunk_size >= len(words):
            break

    return chunks