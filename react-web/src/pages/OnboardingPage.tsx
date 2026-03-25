import { Navigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

/** Paridade com Flutter: onboarding completo no mobile; aqui só aviso + atalho ao dashboard. */
export function OnboardingPage() {
  const auth = useAuth();

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
  if (!auth.onboardingPending) {
    return <Navigate to="/" replace />;
  }

  return (
    <div className="page-padding">
      <h1>Configuração pendente</h1>
      <p className="muted">
        Conclua o onboarding no app <strong>Flutter</strong> (wizard completo) ou marque{" "}
        <code>onboarding_completed = true</code> na tabela <code>users</code> no Supabase.
      </p>
      <p className="muted">
        O dashboard web só abre após o onboarding concluído.
      </p>
      <p>
        <button type="button" className="btn ghost" onClick={() => void auth.logout()}>
          Sair da conta
        </button>
      </p>
    </div>
  );
}
