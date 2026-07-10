// Dashboard d'état pour le pipeline manga
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

const CSS = `
* { margin:0; padding:0; box-sizing:border-box; }
body { font-family:system-ui,sans-serif; background:#0d1117; color:#c9d1d9; padding:2rem; }
h1 { color:#58a6ff; margin-bottom:0.5rem; }
h2 { color:#f0f6fc; margin:1.5rem 0 0.75rem; border-bottom:1px solid #30363d; padding-bottom:0.25rem; }
.card { background:#161b22; border:1px solid #30363d; border-radius:8px; padding:1rem; margin-bottom:1rem; }
.grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(280px,1fr)); gap:1rem; }
.stat { display:flex; justify-content:space-between; padding:0.25rem 0; }
.stat-label { color:#8b949e; }
.stat-value { color:#f0f6fc; font-weight:bold; }
.badge { display:inline-block; padding:0.125rem 0.5rem; border-radius:999px; font-size:0.75rem; }
.badge-ok { background:#1b4a1b; color:#46d160; }
.badge-warn { background:#4a3b1b; color:#d19a46; }
.badge-error { background:#4a1b1b; color:#d14646; }
pre { background:#0d1117; padding:0.75rem; border-radius:4px; overflow-x:auto; font-size:0.85rem; }
`;

async function serveDashboard(): Promise<Response> {
  const [styleRes, plancheRes, logRes, refRes] = await Promise.all([
    supabase.from("manga_styles").select("slug, status, reference_count, training_status, generation_count, updated_at").order("slug"),
    supabase.from("planches").select("id, status, style_slug, created_at").order("created_at", { ascending: false }).limit(20),
    supabase.from("ai_logs").select("*").order("created_at", { ascending: false }).limit(50),
    supabase.from("manga_styles").select("slug, status, reference_count").not("reference_count", "eq", 0),
  ]);

  const styles = styleRes.data ?? [];
  const planches = plancheRes.data ?? [];
  const logs = logRes.data ?? [];
  const refs = refRes.data ?? [];

  const totalSources = refs.reduce((s: number, r: any) => s + (r.reference_count || 0), 0);
  const activeStyles = styles.filter((s: any) => s.status === "active");
  const erroredPlanches = planches.filter((p: any) => p.status === "error");
  const readyToTrain = styles.filter((s: any) => (s.reference_count || 0) >= 50 || (s.generation_count || 0) >= 100);

  const html = `<!DOCTYPE html>
<html lang="fr">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Dashboard Manga Pipeline</title><style>${CSS}</style></head>
<body>
<h1>Dashboard Manga Pipeline</h1>
<p style="color:#8b949e">Dernière mise-à-jour: ${new Date().toISOString()}</p>

<div class="grid">
  <div class="card">
    <h2>Résumé</h2>
    <div class="stat"><span class="stat-label">Styles actifs</span><span class="stat-value">${activeStyles.length}</span></div>
    <div class="stat"><span class="stat-label">Total références</span><span class="stat-value">${totalSources}</span></div>
    <div class="stat"><span class="stat-label">Planches récentes</span><span class="stat-value">${planches.length}</span></div>
    <div class="stat"><span class="stat-label">Erreurs (récent)</span><span class="stat-value">${erroredPlanches.length}</span></div>
    <div class="stat"><span class="stat-label">Prêts pour training</span><span class="stat-value"><span class="badge ${readyToTrain.length > 0 ? "badge-warn" : "badge-ok"}">${readyToTrain.length}</span></span></div>
  </div>

  <div class="card">
    <h2>Derniers Logs</h2>
    ${logs.slice(0, 8).map((l: any) => `
      <div class="stat">
        <span class="stat-label"><span class="badge badge-${l.level === "error" ? "error" : l.level === "warn" ? "warn" : "ok"}">${l.level}</span> ${l.function_name || l.source}</span>
        <span class="stat-value" style="font-size:0.8rem">${new Date(l.created_at).toLocaleTimeString()}</span>
      </div>
    `).join("")}
  </div>
</div>

<h2>Styles & Statut Training</h2>
<div class="grid">
  ${styles.map((s: any) => `
    <div class="card">
      <div style="display:flex;justify-content:space-between"><strong>${s.slug}</strong>
        <span class="badge ${s.status === "active" ? "badge-ok" : "badge-warn"}">${s.status}</span>
      </div>
      <div class="stat"><span class="stat-label">Réfs</span><span class="stat-value">${s.reference_count ?? 0}</span></div>
      <div class="stat"><span class="stat-label">Générations</span><span class="stat-value">${s.generation_count ?? 0}</span></div>
      <div class="stat"><span class="stat-label">Training</span><span class="stat-value">${s.training_status ?? "idle"}</span></div>
    </div>
  `).join("")}
</div>

<h2>Dernières Planches</h2>
<table style="width:100%;border-collapse:collapse">
  <tr style="text-align:left;color:#8b949e">
    <th style="padding:0.5rem;border-bottom:1px solid #30363d">ID</th>
    <th style="padding:0.5rem;border-bottom:1px solid #30363d">Style</th>
    <th style="padding:0.5rem;border-bottom:1px solid #30363d">Status</th>
    <th style="padding:0.5rem;border-bottom:1px solid #30363d">Créé</th>
  </tr>
  ${planches.map((p: any) => `
    <tr>
      <td style="padding:0.5rem;border-bottom:1px solid #21262d;font-size:0.85rem">${p.id.slice(0,8)}</td>
      <td style="padding:0.5rem;border-bottom:1px solid #21262d">${p.style_slug || "-"}</td>
      <td style="padding:0.5rem;border-bottom:1px solid #21262d"><span class="badge ${p.status === "completed" ? "badge-ok" : p.status === "error" ? "badge-error" : "badge-warn"}">${p.status}</span></td>
      <td style="padding:0.5rem;border-bottom:1px solid #21262d">${new Date(p.created_at).toLocaleString()}</td>
    </tr>
  `).join("")}
</table>

<h2>Logs Récents</h2>
<div class="card">
  <pre>${JSON.stringify(logs.slice(0, 20), null, 2)}</pre>
</div>
</body></html>`;

  return new Response(html, {
    headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-cache" },
  });
}

Deno.serve((req) => serveDashboard());
