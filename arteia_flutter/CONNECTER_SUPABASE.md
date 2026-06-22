# 🔗 Connecter Artéïa à TON Supabase

Tu as déjà un projet Supabase ? Parfait ! Suis ces étapes :

## Étape 1 : Récupérer TES clés (30 secondes)

1. Va sur https://supabase.com/dashboard
2. Ouvre TON projet
3. Clique sur **Settings** (⚙️) en bas à gauche
4. Clique sur **API**
5. Tu vois 2 informations importantes :

```
Project URL: https://ABCDEFGHIJKLMNOP.supabase.co
anon/public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.ton_cle_unique...
```

**Copie ces 2 valeurs.**

---

## Étape 2 : Configurer le fichier .env (10 secondes)

1. Dans le dossier `arteia_flutter/`, cherche le fichier `.env.example`
2. Copie-le et renomme la copie en `.env`
3. Ouvre `.env` et remplace :

```env
# Remplace par TES valeurs
SUPABASE_URL=https://TON_PROJET.supabase.co
SUPABASE_ANON_KEY=TA_CLE_ANON
```

**Exemple :**
```env
SUPABASE_URL=https://abc123xyz.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.abc123...
```

---

## Étape 3 : Ajouter les tables à TA base (1 minute)

1. Dans Supabase, clique sur **SQL Editor** (📝)
2. Clique sur **New query**
3. Ouvre le fichier `database/schema-messaging.sql` dans ce projet
4. **Sélectionne TOUT** (Ctrl+A) et **copie** (Ctrl+C)
5. **Colle** dans l'éditeur SQL de Supabase (Ctrl+V)
6. Clique sur **Run** (▶️) en haut à droite
7. Attends le message : "Success. No rows returned"

✅ **Les tables sont créées dans TA base !**

---

## Étape 4 : Créer le bucket pour les messages vocaux (30 secondes)

1. Dans Supabase, clique sur **Storage** (📦)
2. Clique sur **Create a new bucket**
3. Remplis :
   - **Name**: `voice_messages`
   - ✅ Coche **Public bucket**
4. Clique sur **Create bucket**

✅ **Bucket créé !**

---

## Étape 5 : Tester l'application (30 secondes)

```bash
cd arteia_flutter
flutter pub get
flutter run
```

OU pour build l'APK :
```bash
flutter build apk --release
```

---

## ✅ Vérification

- [ ] Fichier `.env` créé avec TES clés
- [ ] Script SQL exécuté dans Supabase
- [ ] Bucket `voice_messages` créé
- [ ] Application se lance sans erreur
- [ ] Chat fonctionne (teste en envoyant un message)

---

## 🆘 Si ça ne marche pas

**Erreur "Supabase not initialized"**
→ Vérifie que `.env` existe et contient les bonnes valeurs

**Messages ne s'affichent pas**
→ Vérifie que le SQL a bien été exécuté (pas d'erreurs dans SQL Editor)

**Upload vocal échoue**
→ Vérifie que le bucket `voice_messages` existe et est public

---

## 🎉 C'est tout !

Maintenant ton application Artéïa est connectée à TA base de données Supabase.

Les messages seront sauvegardés, le temps réel fonctionnera, et les utilisateurs pourront discuter !