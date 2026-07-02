// Edge Function : Envoyer un email d'invitation
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY') ?? ''
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_KEY') ?? ''

serve(async (req) => {
  try {
    const { email, code, sender_name, message } = await req.json()

    // Envoyer l'email via Resend
    const emailResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'Artéïa <invitations@arteia.app>',
        to: email,
        subject: `${sender_name} t'invite à rejoindre Artéïa !`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <div style="background: linear-gradient(135deg, #7C5CFC, #5C3CFC); padding: 40px; text-align: center; border-radius: 16px 16px 0 0;">
              <h1 style="color: white; margin: 0;">🎨 Artéïa</h1>
              <p style="color: white; opacity: 0.9;">La communauté artistique</p>
            </div>
            <div style="padding: 32px; background: #f8f9fa; border-radius: 0 0 16px 16px;">
              <h2 style="color: #333;">${sender_name} t'invite à rejoindre Artéïa !</h2>
              <p style="color: #666; line-height: 1.6;">${message}</p>
              <div style="text-align: center; margin: 32px 0;">
                <a href="https://arteia.app/invite?code=${code}" 
                   style="background: #7C5CFC; color: white; padding: 16px 32px; 
                          text-decoration: none; border-radius: 12px; font-weight: bold;
                          display: inline-block;">
                  Rejoindre Artéïa
                </a>
              </div>
              <p style="color: #999; font-size: 12px; text-align: center;">
                Code d'invitation : <strong>${code}</strong><br>
                Ce lien expire dans 7 jours.
              </p>
            </div>
          </div>
        `,
      }),
    })

    if (!emailResponse.ok) {
      throw new Error(`Resend error: ${await emailResponse.text()}`)
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})