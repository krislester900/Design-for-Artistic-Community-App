const NEON_EDGE_FUNCTION =
  import.meta.env.VITE_SUPABASE_URL && import.meta.env.VITE_NEON_ENABLED
    ? `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/neon-proxy`
    : null;

export const hasNeonEnv = Boolean(NEON_EDGE_FUNCTION);

export type NeonResult<T = Record<string, unknown>> = {
  rows: T[];
  error?: string;
};

async function query<T = Record<string, unknown>>(
  sql: string,
  params?: unknown[],
): Promise<NeonResult<T>> {
  if (!hasNeonEnv) {
    return { rows: [], error: "Neon non configuré" };
  }

  try {
    const res = await fetch(NEON_EDGE_FUNCTION!, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sql, params }),
    });
    if (!res.ok) {
      const err = await res.text();
      return { rows: [], error: err };
    }
    return await res.json();
  } catch (e) {
    return { rows: [], error: e instanceof Error ? e.message : "Erreur réseau" };
  }
}

// ─── Tables d'archives (données froides) ───

export async function archiveChatMessages(beforeDays = 90) {
  return query(
    `INSERT INTO archive_chat_messages
     SELECT * FROM chat_messages
     WHERE created_at < NOW() - INTERVAL '${beforeDays} days'
     ON CONFLICT (id) DO NOTHING`,
  );
}

export async function getArchivedMessages(channelId: string, limit = 50) {
  return query<{
    id: string;
    channel_id: string;
    author_id: string;
    content: string;
    created_at: string;
  }>(
    "SELECT * FROM archive_chat_messages WHERE channel_id = $1 ORDER BY created_at DESC LIMIT $2",
    [channelId, limit],
  );
}

export async function archiveOldStats() {
  return query(
    `INSERT INTO archive_community_stats
     SELECT * FROM community_stats
     WHERE created_at < NOW() - INTERVAL '1 year'`,
  );
}

export async function getArchivedStats() {
  return query<{
    number_label: string;
    label: string;
    archived_at: string;
  }>("SELECT * FROM archive_community_stats ORDER BY archived_at DESC");
}
