import { createClient, type SupabaseClient } from "@supabase/supabase-js";

const url = import.meta.env.VITE_SUPABASE_URL;
const anon = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const supabaseInitError = !url || !anon
  ? "Defina VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY em react-web/.env"
  : null;

export const supabase: SupabaseClient | null = !supabaseInitError
  ? createClient(url, anon)
  : null;
