import { FormEvent, useState } from "react";
import { Navigate, useLocation } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

export function LoginPage() {
  const auth = useAuth();
  const location = useLocation();
  const from = (location.state as { from?: string } | null)?.from ?? "/";

  const [slug, setSlug] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  if (auth.status === "authed") {
    return <Navigate to={auth.onboardingPending ? "/onboarding" : "/"} replace />;
  }

  if (auth.status === "loading") {
    return (
      <div className="centered">
        <p>Carregando…</p>
      </div>
    );
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    const { error: err } = await auth.login(slug, email, password);
    setLoading(false);
    if (err) {
      setError(err);
    }
  }

  return (
    <div className="login-page">
      <div className="login-card">
        <div className="brand">
          <span className="brand-icon">📊</span>
          <h1>VendaFlow</h1>
          <p className="muted">Web (React) — mesmo backend Supabase que o app Flutter</p>
        </div>

        <form onSubmit={onSubmit} className="form">
          {from !== "/" && (
            <p className="hint">Faça login para acessar {from}</p>
          )}
          <label>
            ID da empresa
            <input
              value={slug}
              onChange={(e) => setSlug(e.target.value)}
              placeholder="ex: techbrasil"
              autoComplete="organization"
              required
            />
          </label>
          <label>
            Email
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoComplete="username"
              required
            />
          </label>
          <label>
            Senha
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="current-password"
              required
              minLength={6}
            />
          </label>
          {error && <div className="error-banner">{error}</div>}
          <button type="submit" className="btn primary" disabled={loading}>
            {loading ? "Entrando…" : "Entrar"}
          </button>
        </form>
      </div>
    </div>
  );
}
