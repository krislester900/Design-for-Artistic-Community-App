import { neon } from "@neondatabase/serverless";

const DATABASE_URL = Deno.env.get("NEON_DATABASE_URL");

Deno.serve(async (req) => {
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
