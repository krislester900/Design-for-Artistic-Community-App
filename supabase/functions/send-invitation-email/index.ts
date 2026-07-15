// Edge Function : Envoyer un email d'invitation
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function esc(value: unknown): string {
  return String(value ?? "").replace(/[&<>"']/g, (c) => {
    switch (c) {
      case "&": return "&amp;";
      case "<": return "&lt;";
      case ">": return "&gt;";
      case '"': return "&quot;";
      default: return "&#39;";
    }
  });
}

serve(async (req) => {
  try {
    // 1. Authentifier l'expéditeur.
    const authHeader = req.headers.get("authorization")?.replace("Bearer ", "");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Non authentifié" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data: { user }, error: authError } = await supabase.auth.getUser(authHeader);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Utilisateur non trouvé" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { email, code, sender_name, message } = await req.json();

    // 2. Validation des entrées (anti open-relay, injection d'en-tête, XSS).
    if (!email || !EMAIL_RE.test(String(email))) {
      return new Response(JSON.stringify({ error: "Email destinataire invalide" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }
    if (!code || typeof code !== "string" || code.length > 64) {
      return new Response(JSON.stringify({ error: "Code d'invitation invalide" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }
    const safeSender = sender_name ? esc(sender_name).slice(0, 60) : "Un membre";
    const safeMessage = message ? esc(message).slice(0, 500) : "";
    const safeCode = esc(code);
    const safeEmail = esc(String(email));

    // 3. Envoyer l'email via Resend.
    const emailResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "Artéïa <invitations@arteia.app>",
        to: String(email),
        subject: `${safeSender} t'invite à rejoindre Artéïa !`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <div style="background: linear-gradient(135deg, #7C5CFC, #5C3CFC); padding: 40px; text-align: center; border-radius: 16px 16px 0 0;">
              <h1 style="color: white; margin: 0;">🎨 Artéïa</h1>
              <p style="color: white; opacity: 0.9;">La communauté artistique</p>
            </div>
            <div style="padding: 32px; background: #f8f9fa; border-radius: 0 0 16px 16px;">
              <h2 style="color: #333;">${safeSender} t'invite à rejoindre Artéïa !</h2>
              <p style="color: #666; line-height: 1.6;">${safeMessage}</p>
              <div style="text-align: center; margin: 32px 0;">
                <a href="https://arteia.app/invite?code=${safeCode}"
                   style="background: #7C5CFC; color: white; padding: 16px 32px;
                          text-decoration: none; border-radius: 12px; font-weight: bold;
                          display: inline-block;">
                  Rejoindre Artéïa
                </a>
              </div>
              <p style="color: #999; font-size: 12px; text-align: center;">
                Code d'invitation : <strong>${safeCode}</strong><br>
                Ce lien expire dans 7 jours.
              </p>
            </div>
          </div>
        `,
      }),
    });

    if (!emailResponse.ok) {
      return new Response(JSON.stringify({ error: "Échec de l'envoi de l'email" }), {
        status: 502,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: "Erreur interne" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
