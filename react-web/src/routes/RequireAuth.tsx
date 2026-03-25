import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

/** Exige sessão Supabase e onboarding concluído (igual fluxo pós-login do Flutter). */
export function RequireAuth() {
  const auth = useAuth();
  const loc = useLocation();

  if (auth.status === "loading") {
    return (
      <div className="centered">
        <p>Carregando…</p>
      </div>
    );
  }

  if (auth.status === "guest") {
    return <Navigate to="/login" replace state={{ from: loc.pathname }} />;
  }

  if (auth.onboardingPending) {
    return <Navigate to="/onboarding" replace />;
  }

  return <Outlet />;
}
