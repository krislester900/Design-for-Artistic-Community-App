# Guide d'installation de la base de données Artéïa

## Ordre d'exécution des scripts SQL

⚠️ **Important**: Exécutez les scripts dans l'ordre suivant dans l'éditeur SQL de Supabase.

### Étape 1: Schema de base (OBLIGATOIRE)
```sql
-- Exécuter: database/schema.sql
-- Contient: tables de base, RLS policies, triggers
```

### Étape 2: Schema de contenu (OBLIGATOIRE)
```sql
-- Exécuter: database/schema-content.sql
-- Contient: tables posts, likes, comments, notifications, follows
-- C'est CE script qui crée la table "posts" qui manque!
```

### Étape 3: Fonctionnalités avancées (RECOMMANDÉ)
```sql
-- Exécuter: database/schema-v3-features.sql
-- Contient: upload d'images, compression, favoris, realtime
```

### Étape 4: Messagerie (SI BESOIN)
```sql
-- Exécuter: database/schema-messaging.sql
-- Contient: système de chat Discord-like
```

## Vérification rapide

Après exécution, vérifiez que ces tables existent:
- ✅ profiles
- ✅ categories  
- ✅ posts (créée par schema-content.sql)
- ✅ likes
- ✅ comments
- ✅ notifications
- ✅ follows
- ✅ artwork_favorites
- ✅ artwork_bookmarks

## Erreur "relation does not exist"

Si vous voyez `ERROR: 42P01: relation "public.posts" does not exist`:
1. Vérifiez que vous avez exécuté `schema-content.sql`
2. La table `posts` est créée dans ce fichier (ligne 31-44)
3. Exécutez-le avant `schema-v3-features.sql`

## Script SQL combiné (ALTERNATIVE)

Si vous préférez un seul fichier, utilisez `database/schema-complete.sql` qui contient tout dans le bon ordre.