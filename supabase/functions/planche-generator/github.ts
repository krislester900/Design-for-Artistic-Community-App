// Déclenchement du workflow d'entraînement via GitHub Actions (repository dispatch).

export async function triggerTrainingWebhook(styleSlug: string): Promise<void> {
  const ghToken = Deno.env.get("GITHUB_TOKEN");
  if (!ghToken) return;
  try {
    await fetch(`https://api.github.com/repos/krislester900/Design-for-Artistic-Community-App/dispatches`, {
      method: "POST",
      headers: { "Accept": "application/vnd.github+json", Authorization: `Bearer ${ghToken}` },
      body: JSON.stringify({
        event_type: "trigger-training",
        client_payload: { style_slug: styleSlug },
      }),
    });
  } catch { /* webhook silencieux */ }
}
