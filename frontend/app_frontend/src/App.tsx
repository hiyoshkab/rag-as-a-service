import { useState, type SubmitEvent } from "react";

type Source = {
  filename: string;
  chunk_index: number;
  score: number;
  text: string;
};

function App() {
  const [file, setFile] = useState<File | null>(null);
  const [uploadMessage, setUploadMessage] = useState("");

  const [question, setQuestion] = useState("");
  const [answer, setAnswer] = useState("");
  const [sources, setSources] = useState<Source[]>([]);

  async function handleUpload(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!file) {
      alert("Please select a file to upload.");
      return;
    }

    const formData = new FormData();
    formData.append("file", file);

    const response = await fetch("/ingest", {
      method: "POST",
      body: formData,
    });

    if (!response.ok) {
      alert(`Upload failed: ${response.status}`);
      console.error(await response.text());
      return;
    }

    const data = await response.json();
    setUploadMessage(`Uploaded ${data.filename} (${data.chunks} chunks).`);
    console.log(data);
  }

  async function handleQuestion(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!question) {
      alert("Please enter a question.");
      return;
    }

    const trimmedQuestion = question.trim();
    if (!trimmedQuestion) {
      alert("Please enter a non-empty question.");
      return;
    }

    const response = await fetch("/query", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ question: trimmedQuestion, top_k: 3 }),
    });

    if (!response.ok) {
      alert(`Query failed: ${response.status}`);
      console.error(await response.text());
      return;
    }

    const data = await response.json();
    setAnswer(data.answer);
    setSources(data.sources);
    console.log(data);
  }

  function renderAnswer() {
    const parts = answer.split(/(\[\d+\])/g);

    return parts.map((part, index) => {
      const citation = part.match(/^\[(\d+)\]$/);
      if (!citation) {
        return <span key={index}>{part}</span>;
      }

      const sourceNumber = Number(citation[1]);
      if (sourceNumber < 1 || sourceNumber > sources.length) {
        return <span key={index}>{part}</span>;
      }

      return (
        <button
          className="citation-link"
          key={index}
          type="button"
          onClick={() =>
            document
              .getElementById(`source-${sourceNumber}`)
              ?.scrollIntoView({ behavior: "smooth", block: "nearest" })
          }
          aria-label={`View source ${sourceNumber}`}
        >
          {part}
        </button>
      );
    });
  }
  
  return (
    <main className="page">
      <header className="header">
        <p className="eyebrow">RETRIEVAL-AUGMENTED Q&amp;A</p>
        <h1>Ask your documents</h1>
        <p className="intro">
          Add a UTF-8 text document, then ask a question grounded in its content.
        </p>
      </header>

      <section className="card" aria-labelledby="upload-heading">
        <div className="section-heading">
          <span className="step">01</span>
          <div>
            <h2 id="upload-heading">Add a document</h2>
            <p>Upload a plain-text file to the knowledge base.</p>
          </div>
        </div>
        <form onSubmit={handleUpload}>
          <div className="form-row">
            <label className="file-picker">
              <span>{file?.name ?? "Choose a .txt or .md file"}</span>
              <input
                type="file"
                accept=".txt,.md,text/plain,text/markdown"
                onChange={(event) => setFile(event.currentTarget.files?.[0] ?? null) }
              />
            </label>
            <button type="submit">Upload</button>
          </div>
        </form>
        {uploadMessage && <p className="status">{uploadMessage}</p>}
      </section>

      <section className="card" aria-labelledby="question-heading">
        <div className="section-heading">
          <span className="step">02</span>
          <div>
            <h2 id="question-heading">Ask a question</h2>
            <p>Answers include the passages used to form them.</p>
          </div>
        </div>
        <form onSubmit={handleQuestion}>
          <div className="form-row">
            <label className="visually-hidden" htmlFor="question">
              Your question
            </label>
            <input
              id="question"
              className="question-input"
              placeholder="What would you like to know?"
              value={question}
              onChange={(event) => setQuestion(event.currentTarget.value)}
            />
            <button type="submit">Ask</button>
          </div>
        </form>
      </section>

      <section className="card result" aria-labelledby="answer-heading">
        <h2 id="answer-heading">Answer</h2>
        <p className="answer-text">
          {answer ? renderAnswer() : "Ask a question to get started"}
        </p>
        {sources.length > 0 && (
          <>
            <h3 id="sources-heading">Sources</h3>
            <ol className="sources" aria-labelledby="sources-heading">
              {sources.map((source, index) => (
                <li id={`source-${index + 1}`} key={`${source.filename}-${source.chunk_index}`}>
                  <p className="source-meta">
                    {source.filename}, chunk {source.chunk_index}
                  </p>
                  <blockquote>{source.text}</blockquote>
                </li>
              ))}
            </ol>
          </>
        )}
      </section>
      <footer>RaaS · Document Q&amp;A</footer>
    </main>
  );
}

export default App;
