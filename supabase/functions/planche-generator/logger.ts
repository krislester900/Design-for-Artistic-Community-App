// Logger structuré + retry, partagés par toutes les fonctions de la planche.

export function makeLogger(source: string, supabase?: any) {
  const start = Date.now();
  return {
    info: (msg: string, meta?: any) => logToSupabase(supabase, "info", source, msg, meta, Date.now() - start),
    warn: (msg: string, meta?: any) => logToSupabase(supabase, "warn", source, msg, meta, Date.now() - start),
    error: (msg: string, meta?: any) => logToSupabase(supabase, "error", source, msg, meta, Date.now() - start),
    time: () => Date.now() - start,
  };
}

export async function logToSupabase(supabase: any, level: string, source: string, message: string, metadata?: any, durationMs?: number) {
  if (!supabase) return;
  try {
    await supabase.rpc("insert_ai_log", {
      p_level: level, p_source: source, p_function_name: source,
      p_message: message, p_metadata: metadata ? JSON.stringify(metadata) : "{}",
      p_duration_ms: durationMs ?? null, p_style_slug: metadata?.style_slug ?? null,
      p_planche_id: metadata?.planche_id ?? null,
    });
  } catch { /* log silencieux */ }
}

// Retry avec backoff exponentiel
export async function withRetry<T>(fn: () => Promise<T>, label: string, maxRetries = 3): Promise<T | null> {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (err) {
      if (attempt === maxRetries) return null;
      const delay = Math.min(1000 * Math.pow(2, attempt), 15000);
      console.warn(`[${label}] tentative ${attempt + 1}/${maxRetries + 1} échouée, retry dans ${delay}ms`);
      await new Promise((r) => setTimeout(r, delay));
    }
  }
  return null;
}
