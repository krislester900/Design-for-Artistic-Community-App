// Edge Function : Créer un Stripe PaymentIntent
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

// Devise autorisée (Stripe attend des montants en centimes entiers).
const ALLOWED_CURRENCIES = ["eur", "usd", "gbp"];
const MAX_AMOUNT = 1_000_000_00; // 1 000 000,00 dans la devise (plafond anti-fraude)

serve(async (req) => {
  try {
    // 1. Authentifier l'utilisateur (le montant ne doit jamais être créé par un anonyme).
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

    // 2. Validation stricte des entrées (le montant doit venir validé, pas d'un simple client).
    const { amount, currency } = await req.json();
    const safeCurrency = (currency ?? "eur").toLowerCase();

    if (typeof amount !== "number" || !Number.isInteger(amount) || amount <= 0) {
      return new Response(JSON.stringify({ error: "Montant invalide" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }
    if (amount > MAX_AMOUNT) {
      return new Response(JSON.stringify({ error: "Montant trop élevé" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }
    if (!ALLOWED_CURRENCIES.includes(safeCurrency)) {
      return new Response(JSON.stringify({ error: "Devise non supportée" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const stripeResponse = await fetch("https://api.stripe.com/v1/payment_intents", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${STRIPE_SECRET_KEY}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        amount: amount.toString(),
        currency: safeCurrency,
        automatic_payment_methods: '{"enabled": true}',
      }),
    });

    if (!stripeResponse.ok) {
      // Ne pas exposer le message d'erreur Stripe brut au client.
      return new Response(JSON.stringify({ error: "Échec de la création du paiement" }), {
        status: 502,
        headers: { "Content-Type": "application/json" },
      });
    }

    const paymentIntent = await stripeResponse.json();

    return new Response(JSON.stringify({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: "Erreur interne" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
