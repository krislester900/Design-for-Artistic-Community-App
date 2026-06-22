# 🚀 Guide de Setup - Artéïa

## Étape 1 : Créer un projet Supabase

1. Va sur [supabase.com](https://supabase.com)
2. Crée un compte gratuit
3. Clique sur "New Project"
4. Nomme-le `arteia-app`
5. Choisis un mot de passe pour la base de données
6. Attends 2 minutes que le projet se crée

## Étape 2 : Récupérer les clés API

1. Dans ton projet Supabase, va dans **Settings** (⚙️)
2. Clique sur **API**
3. Copie ces 2 valeurs :
   - **Project URL** : `https://xxxxx.supabase.co`
   - **anon/public key** : `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

## Étape 3 : Configurer la base de données

1. Dans Supabase, clique sur **SQL Editor** (📝)
2. Clique sur **New query**
3. Ouvre le fichier `database/schema-messaging.sql` dans ce projet
4. Copie TOUT le contenu
5. Colle dans l'éditeur SQL
6. Clique sur **Run** (▶️)
7. Attends le message "Success. No rows returned"

## Étape 4 : Créer le bucket Storage

1. Dans Supabase, va dans **Storage** (📦)
2. Clique sur **Create a new bucket**
3. Nomme-le : `voice_messages`
4. Coche **Public bucket**
5. Clique sur **Create bucket**

## Étape 5 : Configurer l'application

1. Dans le dossier `arteia_flutter/`, copie `.env.example` vers `.env` :
   ```bash
   cp .env.example .env
   ```

2. Ouvre `.env` et remplace les valeurs :
   ```env
   SUPABASE_URL=https://ton-projet.supabase.co
   SUPABASE_ANON_KEY=ta_cle_anon_copier_coler_ici
   ```

## Étape 6 : Installer l'APK

```bash
cd arteia_flutter
flutter pub get
flutter build apk --release
```

L'APK sera dans : `build/app/outputs/flutter-apk/app-release.apk`

## Étape 7 : Tester

1. Transfère l'APK sur ton téléphone Android
2. Installe-la
3. Ouvre l'app
4. Le chat public devrait fonctionner !
5. Les messages seront sauvegardés dans Supabase

## ✅ Vérification

- [ ] Projet Supabase créé
- [ ] Clés API récupérées
- [ ] Fichier `.env` configuré
- [ ] Script SQL exécuté
- [ ] Bucket `voice_messages` créé
- [ ] APK buildée et installée
- [ ] Messages s'affichent en temps réel

## 🆘 Problèmes courants

**Erreur "Supabase not initialized"**
→ Vérifie que `.env` existe et contient les bonnes valeurs

**Messages ne s'affichent pas**
→ Vérifie que le script SQL a bien été exécuté (pas d'erreurs)

**Upload vocal échoue**
→ Vérifie que le bucket `voice_messages` existe et est public

**App crash au démarrage**
→ Lance `flutter clean` puis rebuild