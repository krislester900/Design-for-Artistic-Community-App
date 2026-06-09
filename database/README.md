# Base de données Supabase

## 1. Créer le projet
1. Crée un projet sur https://supabase.com
2. Ouvre l'éditeur SQL
3. Colle le contenu de `database/schema.sql`
4. Exécute le script

Le script crée une base vide de pré-lancement :
- aucune œuvre
- aucun artiste
- aucune discussion
- compteurs à zéro

## 2. Récupérer les clés
Dans `Project Settings > API` récupère :
- `Project URL`
- `anon public key`

## 3. Configurer le front
Crée un fichier `.env` à la racine du projet avec :

```env
VITE_SUPABASE_URL=https://your-project-ref.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

Tu peux partir de `.env.example`.

## 4. Tester
Lance ensuite :

```sh
npm run dev
```

Pages utiles :
- site public : `http://localhost:5173/`
- admin : `http://localhost:5173/admin.html`

Si les variables Supabase ne sont pas présentes ou si la base n'est pas disponible,
l'application utilisera automatiquement son état local vide de pré-lancement.

## Tables créées
- `profiles`
- `categories`
- `artists`
- `artworks`
- `forum_discussions`
- `trend_tags`
- `community_events`
- `community_stats`

## Sécurité
Le script active le RLS et ajoute :
- des policies de lecture publique pour le site public
- des policies d’écriture réservées aux utilisateurs ayant le rôle `admin`
- une table `profiles` liée à `auth.users`
- une fonction SQL `public.is_admin()` utilisée par les policies

La page `admin.html` nécessite donc :
1. une connexion Supabase
2. un profil promu en `admin`

## Promouvoir le premier admin
Après création du premier compte, exécute dans Supabase :

```sql
update public.profiles
set role = 'admin'
where email = 'ton-email@example.com';
```
