import { Link, Outlet } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

export function AppShell() {
  const auth = useAuth();

  if (auth.status !== "authed") {
    return <Outlet />;
  }

  return (
    <div className="app-shell">
      <header className="top-nav">
        <Link to="/" className="brand-inline">
          VendaFlow
        </Link>
        <nav>
          <Link to="/">Dashboard</Link>
          <Link to="/assistant">Assistente IA</Link>
        </nav>
        <div className="nav-actions">
          <span className="muted small">{auth.user.email}</span>
          <button type="button" className="btn ghost" onClick={() => void auth.logout()}>
            Sair
          </button>
        </div>
      </header>
      <main className="main-outlet">
        <Outlet />
      </main>
    </div>
  );
}
