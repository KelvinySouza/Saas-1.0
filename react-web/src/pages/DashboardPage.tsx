import { Link } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

export function DashboardPage() {
  const auth = useAuth();
  if (auth.status !== "authed") return null;

  return (
    <div className="page-padding">
      <h1>Dashboard</h1>
      <p className="muted">
        Logado como <strong>{auth.user.email}</strong> · empresa{" "}
        <code>{auth.companyId}</code>
      </p>

      <div className="card-grid">
        <div className="card">
          <h3>Contatos</h3>
          <p className="stat">234</p>
          <p className="muted small">Exemplo — integre tabelas Supabase aqui</p>
        </div>
        <div className="card">
          <h3>Vendas</h3>
          <p className="stat">12</p>
        </div>
        <div className="card">
          <h3>Assistente IA</h3>
          <p className="muted small">Mesma rota <code>/api/ai</code> que o Flutter</p>
          <Link to="/assistant" className="btn-link">
            Abrir assistente →
          </Link>
        </div>
      </div>
    </div>
  );
}
