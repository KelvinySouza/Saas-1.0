import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { fetchSessionProfile, loginWithSlug } from "./loginFlow";
import { supabase } from "../lib/supabaseClient";
import type { Session, User } from "@supabase/supabase-js";

type AuthState =
  | { status: "loading" }
  | { status: "guest" }
  | {
      status: "authed";
      session: Session;
      user: User;
      companyId: string;
      onboardingPending: boolean;
    };

type AuthContextValue = AuthState & {
  login: (
    slug: string,
    email: string,
    password: string
  ) => Promise<{ error?: string }>;
  logout: () => Promise<void>;
  refreshProfile: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AuthState>({ status: "loading" });

  const refreshProfile = useCallback(async () => {
    if (!supabase) {
      setState({ status: "guest" });
      return;
    }
    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.user) {
      setState({ status: "guest" });
      return;
    }
    const profile = await fetchSessionProfile(session.user.id);
    if (!profile) {
      setState({ status: "guest" });
      await supabase.auth.signOut();
      return;
    }
    setState({
      status: "authed",
      session,
      user: session.user,
      companyId: profile.companyId,
      onboardingPending: profile.onboardingPending,
    });
  }, []);

  useEffect(() => {
    void refreshProfile();
    if (!supabase) return;

    const { data: sub } = supabase.auth.onAuthStateChange((_event, session) => {
      if (!session?.user) {
        setState({ status: "guest" });
        return;
      }
      void (async () => {
        const profile = await fetchSessionProfile(session.user.id);
        if (!profile) {
          setState({ status: "guest" });
          return;
        }
        setState({
          status: "authed",
          session,
          user: session.user,
          companyId: profile.companyId,
          onboardingPending: profile.onboardingPending,
        });
      })();
    });
    return () => sub.subscription.unsubscribe();
  }, [refreshProfile]);

  const login = useCallback(
    async (slug: string, email: string, password: string) => {
      const res = await loginWithSlug(slug, email, password);
      if (!res.ok) {
        return { error: res.error };
      }
      await refreshProfile();
      return {};
    },
    [refreshProfile]
  );

  const logout = useCallback(async () => {
    if (supabase) {
      await supabase.auth.signOut();
    }
    setState({ status: "guest" });
  }, []);

  const value = useMemo<AuthContextValue>(() => {
    if (state.status === "loading") {
      return {
        ...state,
        login,
        logout,
        refreshProfile,
      };
    }
    if (state.status === "guest") {
      return {
        ...state,
        login,
        logout,
        refreshProfile,
      };
    }
    return {
      ...state,
      login,
      logout,
      refreshProfile,
    };
  }, [state, login, logout, refreshProfile]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error("useAuth must be used within AuthProvider");
  }
  return ctx;
}
