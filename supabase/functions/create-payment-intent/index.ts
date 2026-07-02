// Edge Function : Créer un Stripe PaymentIntent
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY') ?? ''

serve(async (req) => {
  try {
    const { amount, currency } = await req.json()

    const stripeResponse = await fetch('https://api.stripe.com/v1/payment_intents', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${STRIPE_SECRET_KEY}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        amount: amount.toString(),
        currency: currency ?? 'eur',
        automatic_payment_methods: '{"enabled": true}',
      }),
    })

    if (!stripeResponse.ok) {
      throw new Error(`Stripe error: ${await stripeResponse.text()}`)
    }

    const paymentIntent = await stripeResponse.json()

    return new Response(JSON.stringify({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})