# Design for Artistic Community App

Application front React/Vite pour une communauté artistique.

## Lancer le site en local

### Première installation
```sh
npm install
```

### Démarrer le site
```sh
npm run dev
```

Ensuite ouvre dans ton navigateur l'URL affichée par Vite, en général :
- `http://localhost:5173`

## Build de production
```sh
npm run build
```

## Mode actuel
Le site fonctionne dans deux modes :

1. **Mock local**
   - aucune configuration supplémentaire
   - l'application démarre volontairement avec des données vides
   - pratique pour tester l'état pré-lancement du site

2. **Supabase**
   - les données viennent de la base PostgreSQL Supabase
   - si la base est vide, l'interface reste vide avec des compteurs à zéro
   - si la connexion échoue, l'application revient automatiquement en mode mock

## Configurer Supabase

1. Crée un projet sur Supabase
2. Exécute `database/schema.sql` dans l'éditeur SQL
3. Copie `.env.example` vers `.env`
4. Remplis :

```env
VITE_SUPABASE_URL=https://your-project-ref.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

5. Relance :
```sh
npm run dev
```

## Administration
Une interface d'administration est disponible ici :
- `http://localhost:5173/admin.html`

Elle permet de :
- se connecter avec Supabase
- vérifier le rôle admin
- initialiser les catégories
- ajouter artistes, œuvres, discussions, tendances, événements et statistiques

Important : un compte connecté doit aussi être promu en rôle `admin` dans Supabase.

## Fichiers utiles
- `database/schema.sql` : schéma + policies Supabase
- `database/README.md` : guide de configuration Supabase
- `src/app/services/community.ts` : récupération des données
- `src/app/hooks/useCommunityData.ts` : chargement côté interface
- `src/app/lib/supabase.ts` : client Supabase
- `src/app/admin/AdminApp.tsx` : interface admin

## Vérification rapide
Le bandeau en haut de l'application indique la source de données utilisée :
- `Mock local`
- `Supabase`
