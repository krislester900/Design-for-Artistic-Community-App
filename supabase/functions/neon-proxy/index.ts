import { neon } from "npm:@neondatabase/serverless@1.0.0";

const DATABASE_URL = Deno.env.get("NEON_DATABASE_URL");
// Ce proxy exécute du SQL arbitraire : il DOIT être protégé par le service role.
// En prod, préférez des Edge Functions avec requêtes paramétrées ciblées plutôt qu'un proxy ouvert.
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

Deno.serve(async (req) => {
  // Erreur générique si la clé de garde n'est pas configurée côté serveur.
  if (!SERVICE_ROLE_KEY) {
    return new Response(JSON.stringify({ rows: [], error: "Proxy non configuré" }), {
      status: 503,
      headers: { "Content-Type": "application/json" },
    });
  }

  const auth = req.headers.get("authorization")?.replace("Bearer ", "");
  if (auth !== SERVICE_ROLE_KEY) {
    return new Response(JSON.stringify({ rows: [], error: "Non autorisé" }), {
      status: 403,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (!DATABASE_URL) {
    return new Response(JSON.stringify({ rows: [], error: "NEON_DATABASE_URL non défini" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const { sql, params } = await req.json();
    if (!sql || typeof sql !== "string") {
      return new Response(JSON.stringify({ rows: [], error: "SQL requis" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }
    if (params !== undefined && !Array.isArray(params)) {
      return new Response(JSON.stringify({ rows: [], error: "params doit être un tableau" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const sqlExec = neon(DATABASE_URL);
    const rows = await sqlExec(sql, ...(params || []));
    return new Response(JSON.stringify({ rows }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ rows: [], error: e instanceof Error ? e.message : String(e) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
