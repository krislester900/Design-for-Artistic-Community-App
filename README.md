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

## Fonctionnalités

### Priorité 2 - Fonctionnalités sociales
- **Likes** : système de likes avec compteur animé sur les posts
- **Commentaires** : ajout et affichage de commentaires sur les publications
- **Favoris** : sauvegarde d'œuvres dans une liste personnalisée
- **Follow/Unfollow** : abonnement à des artistes
- **Notifications temps réel** : alertes instantanées pour likes, commentaires, follows

### Priorité 3 - Améliorations UX
- **Mode lecture** : lecteur de contenu immersif
- **Upload d'images** : publication d'œuvres avec compression automatique
- **Cache local Hive** : fonctionnement hors-ligne avec cache des posts/catégories
- **Optimisation images** : compression et cache pour performances optimales
- **IA Assistant** : assistant artistique intégré (Groq/Ollama/fallback local)

## Architecture Flutter

### Services
- `lib/services/like_service.dart` : gestion des likes
- `lib/services/comment_service.dart` : gestion des commentaires
- `lib/services/favorites_service.dart` : gestion des favoris
- `lib/services/follow_service.dart` : gestion des abonnements
- `lib/services/realtime_notifications_service.dart` : notifications temps réel
- `lib/services/cache_service.dart` : cache Hive offline
- `lib/services/image_compression_service.dart` : optimisation images
- `lib/services/ai_assistant_service.dart` : IA assistant

### Pages
- `lib/pages/post_detail_page.dart` : détail d'un post avec likes/commentaires
- `lib/pages/favorites_page.dart` : page des favoris
- `lib/pages/notifications_page_enhanced.dart` : notifications temps réel
- `lib/pages/ai_assistant_page.dart` : assistant IA
- `lib/pages/reading_mode_page.dart` : mode lecture immersif

### Tests
- `test/services_test.dart` : tests unitaires des services
- `test/features_integration_test.dart` : tests d'intégration
- `test/widget_test.dart` : tests des widgets
- `test/image_compression_test.dart` : tests de compression

Lancer les tests :
```sh
cd arteia_flutter
flutter test
```

## Fichiers utiles
- `database/schema.sql` : schéma + policies Supabase
- `database/schema-likes-comments.sql` : tables likes/commentaires
- `database/schema-ai-assistant.sql` : tables IA assistant
- `database/seed-all.sql` : données initiales
- `database/README.md` : guide de configuration Supabase
- `arteia_flutter/lib/services/api_service.dart` : récupération des données
- `arteia_flutter/lib/services/supabase_service.dart` : client Supabase
- `arteia_flutter/lib/main.dart` : initialisation Hive + notifications temps réel

## Vérification rapide
Le bandeau en haut de l'application indique la source de données utilisée :
- `Mock local`
- `Supabase`

## Architecture avancée

### Services avancés
- `lib/services/pagination_service.dart` : pagination + lazy loading pour la scalabilité
- `lib/services/auth_advanced_service.dart` : OAuth (Google/Apple/GitHub) + 2FA
- `lib/services/push_notifications_service.dart` : Firebase Cloud Messaging
- `lib/services/analytics_service.dart` : tracking d'événements et analytics

## État du projet
- ✅ Tests unitaires et d'intégration (73 tests passent)
- ✅ Cache Hive offline fonctionnel
- ✅ Notifications temps réel activées
- ✅ Pagination + Lazy loading implémentés
- ✅ OAuth + 2FA implémentés
- ✅ Push notifications (FCM) implémentées
- ✅ Analytics service implémenté
- ✅ Toutes les fonctionnalités Priorité 2 et 3 implémentées
