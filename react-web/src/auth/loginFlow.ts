import { supabase, supabaseInitError } from "../lib/supabaseClient";

export type LoginResult =
  | {
      ok: true;
      userId: string;
      companyId: string;
      onboardingPending: boolean;
    }
  | { ok: false; error: string };

/** Mesma lógica que `AuthService.login` no Flutter. */
export async function loginWithSlug(
  slug: string,
  email: string,
  password: string
): Promise<LoginResult> {
  try {
    if (!supabase) {
      return { ok: false, error: supabaseInitError ?? "Supabase não configurado" };
    }
    const { data: companyRes, error: cErr } = await supabase
      .from("companies")
      .select("id")
      .eq("slug", slug.trim())
      .maybeSingle();

    if (cErr) {
      return { ok: false, error: cErr.message };
    }
    if (!companyRes) {
      return { ok: false, error: "Empresa não encontrada" };
    }

    const companyId = companyRes.id as string;

    const { data: authRes, error: aErr } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password,
    });

    if (aErr || !authRes.user) {
      return { ok: false, error: "Credenciais inválidas" };
    }

    const userId = authRes.user.id;

    const { data: userRes, error: uErr } = await supabase
      .from("users")
      .select("onboarding_completed")
      .eq("id", userId)
      .eq("company_id", companyId)
      .maybeSingle();

    if (uErr) {
      return { ok: false, error: uErr.message };
    }

    const onboardingPending =
      userRes == null || userRes.onboarding_completed !== true;

    return {
      ok: true,
      userId,
      companyId,
      onboardingPending,
    };
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return { ok: false, error: msg };
  }
}

export async function fetchSessionProfile(userId: string): Promise<{
  companyId: string;
  onboardingPending: boolean;
} | null> {
  if (!supabase) return null;
  const { data, error } = await supabase
    .from("users")
    .select("company_id, onboarding_completed")
    .eq("id", userId)
    .maybeSingle();

  if (error || !data?.company_id) return null;
  const onboardingPending = data.onboarding_completed !== true;
  return {
    companyId: data.company_id as string,
    onboardingPending,
  };
}
