# Configuration Supabase pour Artéïa

## Étape 1 : Créer un compte Supabase
1. Va sur **https://supabase.com**
2. Clique **"Start your project"** (gratuit)
3. Connecte-toi avec GitHub

## Étape 2 : Créer le projet
1. Clique **"New project"**
2. Organisation : choisis ton compte GitHub
3. Name : `arteia-app`
4. Database Password : copie-le dans un fichier texte (tu en auras besoin)
5. Region : choisis le plus proche de toi (ex: `West Europe`)
6. Clique **"Create new project"** (attends ~2 minutes)

## Étape 3 : Récupérer les clés API
1. Va dans **Project Settings** (⚙️)
2. Clique **"API"** dans le menu de gauche
3. Tu verras :
   - **Project URL** (ex: `https://abcdefghijk.supabase.co`)
   - **anon public key** (ex: `eyJhbGciOiJIUzI1NiIs...`)

## Étape 4 : Configurer le fichier .env
Dans le dossier du projet, crée/modifie le fichier `.env` :

```
VITE_SUPABASE_URL=https://abcdefghijk.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
```

## Étape 5 : Exécuter les schémas SQL
1. Dans Supabase, va dans **SQL Editor** (menu gauche)
2. Clique **"New query"**
3. Copie tout le contenu de `database/schema.sql` et colle-le
4. Clique **"Run"** (▶️)
5. Répète avec `database/schema-v2.sql`

## Étape 6 : Activer Google Auth (optionnel)
Dans Supabase :
1. Authentication → **Providers**
2. Clique **Google**
3. Active-le (bascule vert)
4. Client ID : va sur https://console.cloud.google.com → APIs & Services → Credentials
5. Crée un "OAuth 2.0 Client ID" → Web application
6. Dans "Authorized redirect URIs" ajoute :
   ```
   https://abcdefghijk.supabase.co/auth/v1/callback
   ```
7. Copie le Client ID et Client Secret dans Supabase
8. Sauvegarde

## Vérification
1. Lance le site : `npm run dev`
2. Va sur http://localhost:5173/connexion.html
3. Tu devrais voir le formulaire de connexion fonctionner
4. Si ça marche, tu verras "Supabase actif" dans l'interface