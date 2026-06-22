# 🧪 Comment tester l'application Artéïa

## Méthode 1 : Sur un téléphone Android (RECOMMANDÉ)

### Étape 1 : Connecter ton téléphone
1. Branche ton téléphone Android au PC avec un câble USB
2. Sur ton téléphone, active le **mode développeur** :
   - Paramètres → À propos du téléphone
   - Tape 7 fois sur "Numéro de build"
3. Active le **débogage USB** :
   - Paramètres → Options de développement
   - Active "Débogage USB"

### Étape 2 : Vérifier la connexion
```bash
cd arteia_flutter
flutter devices
```

Tu devrais voir ton téléphone dans la liste.

### Étape 3 : Lancer l'application
```bash
flutter run
```

L'application va s'installer et se lancer automatiquement sur ton téléphone.

---

## Méthode 2 : Sur un émulateur Android

### Étape 1 : Créer un émulateur
1. Ouvre Android Studio
2. Tools → Device Manager
3. Create Device
4. Choisis un téléphone (ex: Pixel 5)
5. Télécharge une version Android (ex: Android 14)
6. Finish

### Étape 2 : Lancer l'émulateur
```bash
flutter emulators --launch pixel_5
```

### Étape 3 : Lancer l'application
```bash
flutter run
```

---

## Méthode 3 : Build APK + Installer manuellement

### Étape 1 : Build l'APK
```bash
cd arteia_flutter
flutter build apk --release
```

### Étape 2 : Transférer sur le téléphone
L'APK est dans : `build/app/outputs/flutter-apk/app-release.apk`

Copie ce fichier sur ton téléphone et installe-le.

---

## ⚠️ IMPORTANT : Avant de tester

### 1. Exécute le SQL dans Supabase
Ouvre https://supabase.com/dashboard/project/wzewlweghntnqyfvhgan/editor
- SQL Editor → New query
- Ouvre `database/schema-content.sql`
- Copie TOUT → Colle → Run (▶️)

### 2. Crée le bucket Storage
https://supabase.com/dashboard/project/wzewlweghntnqyfvhgan/storage/buckets
- Create bucket
- Nom : `voice_messages`
- Public bucket : ✅

### 3. Vérifie le fichier .env
Le fichier `.env` doit contenir TES clés Supabase.

---

## 🎯 Test rapide

```bash
# 1. Va dans le dossier
cd arteia_flutter

# 2. Installe les dépendances
flutter pub get

# 3. Lance l'app
flutter run
```

---

## 🐛 Si ça ne marche pas

**"No devices detected"**
→ Vérifie que le téléphone est connecté et le débogage USB activé

**"Build failed"**
→ Lance `flutter clean` puis `flutter pub get` puis `flutter run`

**"Supabase not initialized"**
→ Vérifie que le fichier `.env` existe et contient les bonnes clés

**"Tables not found"**
→ Tu n'as pas exécuté le SQL dans Supabase

---

## ✅ Une fois lancé

Tu pourras :
- Voir la page d'accueil avec les catégories
- Explorer les posts (si tu en as créé dans Supabase)
- Rechercher des posts
- Voir le profil (si tu es connecté)
- Tester le chat (si les tables de messaging sont créées)

**Bon test ! 🚀**