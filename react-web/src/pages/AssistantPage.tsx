import { FormEvent, useState } from "react";
import { Navigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

function apiBase(): string {
  const v = import.meta.env.VITE_API_BASE_URL;
  return v && v.length > 0 ? v.replace(/\/$/, "") : "";
}

export function AssistantPage() {
  const auth = useAuth();
  const [prompt, setPrompt] = useState("");
  const [messages, setMessages] = useState<{ role: string; text: string }[]>([]);
  const [loading, setLoading] = useState(false);

  if (auth.status === "loading") {
    return (
      <div className="centered">
        <p>Carregando…</p>
      </div>
    );
  }
  if (auth.status === "guest") {
    return <Navigate to="/login" replace />;
  }
  if (auth.status !== "authed") {
    return null;
  }
  const { session } = auth;

  async function send(e: FormEvent) {
    e.preventDefault();
    const text = prompt.trim();
    if (!text) return;

    const base = apiBase();
    const path = `${base}/api/ai`;
    const token = session.access_token;

    setMessages((m) => [...m, { role: "user", text }]);
    setPrompt("");
    setLoading(true);

    try {
      const controller = new AbortController();
      const timeoutMs = 90000; // 90s no máximo
      const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

      const res = await fetch(path, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ prompt: text }),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      const raw = await res.text();
      let answer = "Erro ao processar resposta.";
      try {
        const j = JSON.parse(raw) as { answer?: string; error?: string };
        if (res.ok && j.answer) answer = j.answer;
        else if (j.error) answer = j.error;
      } catch {
        if (!res.ok) answer = "Falha na API.";
      }
      setMessages((m) => [...m, { role: "assistant", text: answer }]);
    } catch {
      setMessages((m) => [
        ...m,
        {
          role: "assistant",
          text:
            "Sem conexão com a API. Rode o Node em :3000 ou defina VITE_API_BASE_URL.",
        },
      ]);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="page-padding assistant">
      <h1>Assistente IA</h1>
      <p className="muted small">
        URL: <code>{apiBase() || "(proxy /api → :3000 em dev)"}</code>
      </p>
      <div className="chat">
        {messages.map((m, i) => (
          <div key={i} className={`bubble ${m.role === "user" ? "user" : "bot"}`}>
            {m.text}
          </div>
        ))}
      </div>
      <form onSubmit={send} className="chat-input">
        <input
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          placeholder="Pergunte algo…"
          disabled={loading}
        />
        <button type="submit" className="btn primary" disabled={loading}>
          {loading ? "…" : "Enviar"}
        </button>
      </form>
    </div>
  );
}
